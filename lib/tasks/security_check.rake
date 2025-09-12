namespace :security do
  desc "Run comprehensive security checks"
  task check: :environment do
    puts "🔒 DevvMe Security Check"
    puts "=" * 50

    check_environment_variables
    check_rails_credentials
    check_database_security
    check_email_configuration
    check_ssl_configuration
    check_security_headers
    check_file_permissions

    puts "\n✅ Security check completed!"
  end

  desc "Check environment variables"
  task env_check: :environment do
    check_environment_variables
  end

  desc "Check Rails credentials"
  task credentials_check: :environment do
    check_rails_credentials
  end

  private

  def check_environment_variables
    puts "\n📋 Environment Variables Check"
    puts "-" * 30

    required_vars = %w[
      RAILS_MASTER_KEY
      DATABASE_URL
      CACHE_DATABASE_URL
      QUEUE_DATABASE_URL
      CABLE_DATABASE_URL
    ]

    if Rails.env.production?
      required_vars += %w[
        SMTP_USERNAME
        SMTP_PASSWORD
        RAILS_HOST
      ]
    end

    missing_vars = []
    required_vars.each do |var|
      if ENV[var].blank?
        missing_vars << var
        puts "❌ Missing: #{var}"
      else
        # Mask sensitive values
        masked_value = var.include?("PASSWORD") || var.include?("KEY") || var.include?("URL") ?
          "#{ENV[var][0..3]}...#{ENV[var][-4..-1]}" : ENV[var]
        puts "✅ #{var}: #{masked_value}"
      end
    end

    if missing_vars.any?
      puts "\n⚠️  Missing required environment variables: #{missing_vars.join(', ')}"
    else
      puts "\n✅ All required environment variables are set"
    end
  end

  def check_rails_credentials
    puts "\n🔐 Rails Credentials Check"
    puts "-" * 30

    begin
      credentials = Rails.application.credentials

      # Check if credentials are accessible
      if credentials.respond_to?(:dig)
        puts "✅ Rails credentials are accessible"

        # Check for common credential keys
        credential_keys = %w[google facebook smtp aws azure_storage]
        credential_keys.each do |key|
          if credentials.dig(key.to_sym)
            puts "✅ #{key} credentials found"
          else
            puts "ℹ️  #{key} credentials not found (optional)"
          end
        end
      else
        puts "❌ Rails credentials not accessible"
      end
    rescue => e
      puts "❌ Error accessing Rails credentials: #{e.message}"
    end
  end

  def check_database_security
    puts "\n🗄️  Database Security Check"
    puts "-" * 30

    begin
      # Check database connection
      ActiveRecord::Base.connection.execute("SELECT 1")
      puts "✅ Database connection successful"

      # Check if using SSL in production
      if Rails.env.production?
        db_config = ActiveRecord::Base.connection_db_config
        if db_config.url&.include?("sslmode=require")
          puts "✅ Database SSL enabled"
        else
          puts "⚠️  Database SSL not explicitly required"
        end
      end

      # Check for sensitive data in logs
      if Rails.logger.respond_to?(:level) && Rails.logger.level <= 1
        puts "⚠️  Debug logging enabled - may expose sensitive data"
      else
        puts "✅ Log level appropriate for production"
      end

    rescue => e
      puts "❌ Database connection failed: #{e.message}"
    end
  end

  def check_email_configuration
    puts "\n📧 Email Configuration Check"
    puts "-" * 30

    mailer_config = Rails.application.config.action_mailer

    if mailer_config.delivery_method == :smtp
      puts "✅ SMTP delivery method configured"

      smtp_settings = mailer_config.smtp_settings
      if smtp_settings[:user_name].present?
        puts "✅ SMTP username configured"
      else
        puts "❌ SMTP username not configured"
      end

      if smtp_settings[:password].present?
        puts "✅ SMTP password configured"
      else
        puts "❌ SMTP password not configured"
      end

      if smtp_settings[:enable_starttls_auto]
        puts "✅ STARTTLS enabled for secure email"
      else
        puts "⚠️  STARTTLS not enabled"
      end
    else
      puts "⚠️  SMTP not configured - using #{mailer_config.delivery_method}"
    end
  end

  def check_ssl_configuration
    puts "\n🔒 SSL Configuration Check"
    puts "-" * 30

    if Rails.env.production?
      if Rails.application.config.force_ssl
        puts "✅ Force SSL enabled"
      else
        puts "❌ Force SSL not enabled"
      end

      if Rails.application.config.ssl_options
        puts "✅ SSL options configured"
      else
        puts "⚠️  SSL options not configured"
      end
    else
      puts "ℹ️  SSL check skipped (not in production)"
    end
  end

  def check_security_headers
    puts "\n🛡️  Security Headers Check"
    puts "-" * 30

    # Check if security initializer exists
    security_file = Rails.root.join("config/initializers/security.rb")
    if security_file.exist?
      puts "✅ Security initializer found"
    else
      puts "❌ Security initializer not found"
    end

    # Check CSP configuration
    if Rails.application.config.content_security_policy
      puts "✅ Content Security Policy configured"
    else
      puts "⚠️  Content Security Policy not configured"
    end
  end

  def check_file_permissions
    puts "\n📁 File Permissions Check"
    puts "-" * 30

    sensitive_files = [
      "config/master.key",
      "config/credentials.yml.enc",
      ".kamal/secrets"
    ]

    sensitive_files.each do |file|
      file_path = Rails.root.join(file)
      if file_path.exist?
        stat = File.stat(file_path)
        permissions = sprintf("%o", stat.mode)[-3..-1]

        if permissions == "600" || permissions == "640"
          puts "✅ #{file}: #{permissions} (secure)"
        else
          puts "⚠️  #{file}: #{permissions} (consider restricting)"
        end
      else
        puts "ℹ️  #{file}: not found (expected for some files)"
      end
    end
  end
end
