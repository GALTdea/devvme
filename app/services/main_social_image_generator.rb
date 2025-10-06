# Example usage in Rails console:
# generator = MainSocialImageGenerator.new(title: "My Custom Title", subtitle: "My Custom Subtitle")
# generator.generate # Returns path to generated image

class MainSocialImageGenerator
  TEMPLATE_VERSION = 1

  CANVAS_WIDTH  = 1200
  CANVAS_HEIGHT = 630

  def initialize(title:, subtitle:, background_variant: "default")
    @title = (title || "Devv.me — Build a standout developer profile").to_s.strip
    @subtitle = (subtitle || "Showcase projects, get discovered, and grow your developer brand.").to_s.strip
    @background_variant = background_variant
  end

  def generate
    png_path = cached_png_path
    return png_path if File.exist?(png_path)

    svg_path = write_svg
    convert_svg_to_png(svg_path, png_path)

    File.exist?(png_path) ? png_path : svg_path
  end

  private

  def cache_dir
    dir = Rails.root.join("tmp", "social", "main")
    FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
    dir
  end

  def digest
    raw = [@title, @subtitle, @background_variant, TEMPLATE_VERSION].join("|")
    Digest::SHA1.hexdigest(raw)
  end

  def cached_svg_path
    cache_dir.join("main_#{digest}.svg")
  end

  def cached_png_path
    cache_dir.join("main_#{digest}.png")
  end

  def write_svg
    path = cached_svg_path
    File.write(path, svg_markup)
    path
  end

  def convert_svg_to_png(svg_path, png_path)
    # Prefer libvips CLI which is already used elsewhere in the app
    system("vips copy #{svg_path} #{png_path}")
  end

  def svg_markup
    safe_title_lines = wrap_text(@title, max_chars_per_line: 22, max_lines: 2)
    safe_subtitle_lines = wrap_text(@subtitle, max_chars_per_line: 38, max_lines: 3)

    title_y = 280
    subtitle_y = 345

    <<~SVG
      <svg width="#{CANVAS_WIDTH}" height="#{CANVAS_HEIGHT}" viewBox="0 0 #{CANVAS_WIDTH} #{CANVAS_HEIGHT}" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#6366F1;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#A855F7;stop-opacity:1" />
          </linearGradient>
          <filter id="softShadow" x="-20%" y="-20%" width="140%" height="140%">
            <feDropShadow dx="0" dy="8" stdDeviation="16" flood-color="#000000" flood-opacity="0.12"/>
          </filter>
        </defs>

        <!-- Background -->
        <rect width="#{CANVAS_WIDTH}" height="#{CANVAS_HEIGHT}" fill="url(#bg)"/>

        <!-- Decorative shapes -->
        <g opacity="0.25">
          <circle cx="200" cy="120" r="80" fill="#ffffff"/>
          <rect x="980" y="420" width="140" height="140" rx="16" fill="#ffffff"/>
        </g>

        <!-- Card surface -->
        <rect x="80" y="60" width="1040" height="510" rx="28" fill="rgba(255,255,255,0.9)" filter="url(#softShadow)" />

        <!-- Brand chip -->
        <rect x="120" y="110" width="140" height="40" rx="20" fill="#111827" opacity="0.88" />
        <text x="190" y="137" text-anchor="middle" fill="#FFFFFF" font-family="-apple-system, BlinkMacSystemFont, Segoe UI, Helvetica, Arial, sans-serif" font-size="18" font-weight="700">Devv.me</text>

        <!-- Title -->
        <text x="160" y="#{title_y}" fill="#111827" font-family="-apple-system, BlinkMacSystemFont, Segoe UI, Helvetica, Arial, sans-serif" font-size="84" font-weight="800">
          #{tspans(safe_title_lines, 0)}
        </text>

        <!-- Subtitle -->
        <text x="160" y="#{subtitle_y}" fill="#4B5563" font-family="-apple-system, BlinkMacSystemFont, Segoe UI, Helvetica, Arial, sans-serif" font-size="32" font-weight="600">
          #{tspans(safe_subtitle_lines, 40)}
        </text>

        <!-- Wordmark -->
        <text x="1080" y="570" text-anchor="end" fill="#374151" font-family="-apple-system, BlinkMacSystemFont, Segoe UI, Helvetica, Arial, sans-serif" font-size="20" font-weight="700">devv.me</text>
      </svg>
    SVG
  end

  def wrap_text(text, max_chars_per_line:, max_lines:)
    words = text.split(/\s+/)
    lines = []
    current = ""

    words.each do |word|
      trial = current.empty? ? word : "#{current} #{word}"
      if trial.length <= max_chars_per_line
        current = trial
      else
        lines << current
        current = word
      end
      break if lines.length >= max_lines && current.length > max_chars_per_line
    end
    lines << current unless current.empty?
    lines = lines.first(max_lines)
    if lines.length == max_lines && (words.join(" ").length > lines.join(" ").length)
      lines[-1] = lines[-1].gsub(/.$/, '') + "…"
    end
    lines
  end

  def tspans(lines, line_height)
    return "" if lines.empty?
    y = 0
    lines.map.with_index do |l, i|
      dy = i.zero? ? 0 : line_height
      %(<tspan x="160" dy="#{dy}">#{ERB::Util.html_escape(l)}</tspan>)
    end.join
  end
end
