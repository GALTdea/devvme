namespace :beta do
  desc "List all pending activation users"
  task list_pending: :environment do
    pending_users = User.pending_activation.order(:created_at)

    if pending_users.any?
      puts "\n📋 Pending Activation Users (#{pending_users.count}):"
      puts "=" * 50

      pending_users.each_with_index do |user, index|
        puts "#{index + 1}. #{user.username} (#{user.email}) - Created: #{user.created_at.strftime('%Y-%m-%d %H:%M')}"
      end

      puts "\nTo activate a user, run:"
      puts "bin/rails beta:activate_user USERNAME=username"
    else
      puts "✅ No users pending activation"
    end
  end

  desc "Activate a specific user by username"
  task activate_user: :environment do
    username = ENV['USERNAME']

    unless username
      puts "❌ Error: Please provide a USERNAME"
      puts "Usage: bin/rails beta:activate_user USERNAME=john_doe"
      exit 1
    end

    user = User.find_by(username: username)

    unless user
      puts "❌ Error: User with username '#{username}' not found"
      exit 1
    end

    if user.active?
      puts "⚠️  User '#{username}' is already active"
      exit 0
    end

    user.activate_account!
    puts "✅ User '#{username}' has been activated successfully!"
    puts "📧 Activation email sent to: #{user.email}"
  end

  desc "Activate multiple users in batch"
  task :activate_batch, [:count] => :environment do |task, args|
    count = (args[:count] || 5).to_i

    pending_users = User.pending_activation.order(:created_at).limit(count)

    if pending_users.empty?
      puts "✅ No users pending activation"
      exit 0
    end

    puts "🚀 Activating #{pending_users.count} users..."

    pending_users.each do |user|
      user.activate_account!
      puts "✅ Activated: #{user.username} (#{user.email})"
    end

    puts "\n🎉 Successfully activated #{pending_users.count} users!"
  end

  desc "Show beta statistics"
  task stats: :environment do
    total_users = User.count
    pending_users = User.pending_activation.count
    active_users = User.active.count

    puts "\n📊 Beta Statistics:"
    puts "=" * 30
    puts "Total Users:     #{total_users}"
    puts "Active Users:    #{active_users}"
    puts "Pending Users:   #{pending_users}"
    puts "Activation Rate: #{active_users > 0 ? ((active_users.to_f / total_users) * 100).round(1) : 0}%"

    if pending_users > 0
      oldest_pending = User.pending_activation.order(:created_at).first
      puts "\nOldest pending user: #{oldest_pending.username} (#{oldest_pending.created_at.strftime('%Y-%m-%d')})"
    end
  end
end
