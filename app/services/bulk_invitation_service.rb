class BulkInvitationService
  require "csv"

  def initialize(admin_user)
    @admin_user = admin_user
  end

  def process_csv(csv_file)
    results = { total: 0, successful: 0, failed: 0, errors: [] }

    CSV.foreach(csv_file.path, headers: true, header_converters: :symbol) do |row|
      results[:total] += 1

      begin
        user_data = extract_user_data_from_row(row)

        if create_invited_user(user_data)
          results[:successful] += 1
        else
          results[:failed] += 1
          results[:errors] << "Row #{results[:total]}: Failed to create user"
        end
      rescue => e
        results[:failed] += 1
        results[:errors] << "Row #{results[:total]}: #{e.message}"
        Rails.logger.error "Bulk invitation error for row #{results[:total]}: #{e.message}"
      end
    end

    results
  end

  def process_manual_entries(entries)
    results = { total: 0, successful: 0, failed: 0, errors: [] }

    entries.each_with_index do |entry, index|
      results[:total] += 1

      begin
        user_data = parse_manual_entry(entry)

        if create_invited_user(user_data)
          results[:successful] += 1
        else
          results[:failed] += 1
          results[:errors] << "Entry #{index + 1}: Failed to create user"
        end
      rescue => e
        results[:failed] += 1
        results[:errors] << "Entry #{index + 1}: #{e.message}"
        Rails.logger.error "Bulk invitation error for entry #{index + 1}: #{e.message}"
      end
    end

    results
  end

  private

  def extract_user_data_from_row(row)
    {
      username: generate_username_from_email(row[:email]),
      email: row[:email]&.strip&.downcase,
      full_name: row[:full_name]&.strip,
      job_title: row[:job_title]&.strip,
      location: row[:location]&.strip,
      bio: row[:bio]&.strip,
      headline: row[:headline]&.strip,
      github_url: row[:github_url]&.strip,
      linkedin_url: row[:linkedin_url]&.strip,
      website_url: row[:website_url]&.strip,
      twitter_url: row[:twitter_url]&.strip,
      contact_email: row[:contact_email]&.strip,
      phone: row[:phone]&.strip,
      skills: parse_skills(row[:skills]),
      role: (row[:role]&.strip&.downcase || "user"),
      admin_notes: "Bulk created by #{@admin_user.display_name} on #{Time.current.strftime('%Y-%m-%d')}"
    }
  end

  def parse_manual_entry(entry)
    # Support formats:
    # email@example.com
    # "Full Name" <email@example.com>
    # email@example.com,Full Name,Job Title

    if entry.include?(",")
      # CSV-like format
      parts = entry.split(",").map(&:strip)
      email = parts[0]
      full_name = parts[1] if parts.length > 1
      job_title = parts[2] if parts.length > 2
    elsif entry.match(/"([^"]+)"\s*<([^>]+)>/)
      # "Name" <email> format
      matches = entry.match(/"([^"]+)"\s*<([^>]+)>/)
      full_name = matches[1]
      email = matches[2]
    else
      # Just email
      email = entry
    end

    {
      username: generate_username_from_email(email),
      email: email&.strip&.downcase,
      full_name: full_name&.strip,
      job_title: job_title&.strip,
      role: "user",
      admin_notes: "Bulk created by #{@admin_user.display_name} on #{Time.current.strftime('%Y-%m-%d')}"
    }
  end

  def generate_username_from_email(email)
    return nil unless email.present?

    base_username = email.split("@").first.gsub(/[^a-zA-Z0-9_-]/, "_").downcase
    base_username = base_username[0..29] # Limit to 30 characters

    # Ensure uniqueness
    username = base_username
    counter = 1

    while User.exists?(username: username)
      suffix = "_#{counter}"
      max_base_length = 30 - suffix.length
      username = "#{base_username[0..max_base_length-1]}#{suffix}"
      counter += 1

      # Prevent infinite loop
      break if counter > 999
    end

    username
  end

  def parse_skills(skills_string)
    return [] unless skills_string.present?

    skills_string.split(/[,;|]/).map(&:strip).reject(&:blank?).uniq.first(10)
  end

  def create_invited_user(user_data)
    return false unless user_data[:email].present?
    return false if User.exists?(email: user_data[:email])

    user = User.new(user_data.except(:admin_notes))
    user.account_status = :invited

    if user.save
      # Add admin notes if provided
      if user_data[:admin_notes].present?
        user.update_column(:admin_notes, user_data[:admin_notes])
      end

      # Send invitation
      user.invite!(admin: @admin_user, send_email: true)

      Rails.logger.info "Bulk invitation created for #{user.email} (#{user.username})"
      true
    else
      Rails.logger.error "Failed to create bulk invitation for #{user_data[:email]}: #{user.errors.full_messages.join(', ')}"
      false
    end
  end
end
