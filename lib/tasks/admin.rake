namespace :admin do
  desc "Create first admin user"
  task create_admin: :environment do
    puts "Creating admin user..."

    print "Email: "
    email = STDIN.gets.chomp

    print "Username: "
    username = STDIN.gets.chomp

    print "Full name (optional): "
    full_name = STDIN.gets.chomp
    full_name = nil if full_name.blank?

    print "Password (leave blank for random): "
    password = STDIN.gets.chomp

    if password.blank?
      password = SecureRandom.hex(8)
      puts "Generated password: #{password}"
    end

    user = User.create!(
      email: email,
      username: username,
      full_name: full_name,
      password: password,
      password_confirmation: password,
      role: :super_admin
    )

    puts "\n✅ Admin user created successfully!"
    puts "Email: #{user.email}"
    puts "Username: #{user.username}"
    puts "Role: #{user.role}"
    puts "Password: #{password}"
    puts "\nYou can now sign in at #{Rails.application.config.force_ssl ? 'https' : 'http'}://localhost:3000/users/sign_in"
  end

  desc "List all admin users"
  task list_admins: :environment do
    admins = User.where(role: [:admin, :super_admin])

    if admins.any?
      puts "\n📋 Admin Users:"
      puts "=" * 60
      admins.each do |admin|
        puts "#{admin.username.ljust(20)} | #{admin.email.ljust(30)} | #{admin.role.humanize}"
      end
    else
      puts "No admin users found. Run 'rails admin:create_admin' to create one."
    end
  end

  desc "Promote user to admin"
  task promote_user: :environment do
    print "Username or email to promote: "
    identifier = STDIN.gets.chomp

    user = User.find_by(username: identifier) || User.find_by(email: identifier)

    if user.nil?
      puts "❌ User not found"
      exit 1
    end

    if user.can_access_admin?
      puts "❌ User is already an admin (#{user.role})"
      exit 1
    end

    puts "Available roles:"
    puts "1. Admin"
    puts "2. Super Admin"
    print "Choose role (1-2): "
    choice = STDIN.gets.chomp.to_i

    role = case choice
    when 1
      :admin
    when 2
      :super_admin
    else
      puts "❌ Invalid choice"
      exit 1
    end

    user.update!(role: role)
    puts "✅ User #{user.username} promoted to #{role.to_s.humanize}"
  end
end
