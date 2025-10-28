namespace :social_images do
  desc "Clean up old social image versions, keeping only the current version per user"
  task cleanup: :environment do
    keep_versions = ENV.fetch("KEEP_VERSIONS", "1").to_i

    puts "🧹 Cleaning up old social image versions..."
    puts "Keeping only the current version per user"
    puts ""

    deleted_count = 0
    deleted_size = 0

    User.all.each do |user|
      # Find all images for this user
      user_images = Dir.glob(Rails.root.join("tmp", "social_#{user.id}_*.png"))

      next if user_images.empty?

      # Sort by modification time (newest first)
      sorted_images = user_images.sort_by { |f| File.mtime(f) }.reverse

      # Files to keep (most recent N)
      files_to_keep = sorted_images.first(keep_versions)
      files_to_delete = sorted_images.drop(keep_versions)

      # Delete old files
      files_to_delete.each do |file|
        file_size = File.size(file)
        deleted_size += file_size
        File.delete(file) if File.exist?(file)
        deleted_count += 1
        puts "  Deleted: #{File.basename(file)} (#{(file_size / 1024.0).round(2)} KB)"
      end
    end

    puts ""
    puts "✅ Cleanup complete!"
    puts "  Deleted: #{deleted_count} files"
    puts "  Freed: #{(deleted_size / 1024.0 / 1024.0).round(2)} MB"
  end

  desc "Show storage usage statistics for social images"
  task stats: :environment do
    puts "📊 Social Images Storage Statistics"
    puts ""

    all_images = Dir.glob(Rails.root.join("tmp", "social_*.png"))
    total_images = all_images.count
    total_size_bytes = all_images.sum { |f| File.size(f) }
    total_size_mb = (total_size_bytes / 1024.0 / 1024.0).round(2)
    avg_size_kb = (total_size_bytes / total_images.to_f / 1024.0).round(2)

    puts "Total Images: #{total_images}"
    puts "Total Size: #{total_size_mb} MB"
    puts "Average Size: #{avg_size_kb} KB"
    puts ""

    # Per-user breakdown
    user_counts = Hash.new(0)
    all_images.each do |file|
      filename = File.basename(file)
      if filename =~ /social_(\d+)_/
        user_counts[$1.to_i] += 1
      end
    end

    puts "Users with social images: #{user_counts.keys.count}"
    puts ""
    puts "Top 10 users by version count:"
    user_counts.sort_by { |k, v| -v }.first(10).each do |user_id, count|
      user = User.find_by(id: user_id)
      if user
        user_size_bytes = Dir.glob(Rails.root.join("tmp", "social_#{user_id}_*.png")).sum { |f| File.size(f) }
        user_size_mb = (user_size_bytes / 1024.0 / 1024.0).round(2)
        puts "  #{user.username}: #{count} versions, #{user_size_mb} MB"
      end
    end
  end
end
