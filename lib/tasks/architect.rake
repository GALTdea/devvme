# frozen_string_literal: true

namespace :architect do
  ARCHITECT_JOB_CLASS = "ArchitectReplyJob"
  ESTIMATED_COST_PER_SESSION = 0.06

  desc "Enable Career Architect (beta) for a user by username"
  task enable_beta: :environment do
    username = ENV["USERNAME"]
    unless username.present?
      puts "Usage: USERNAME=username bin/rails architect:enable_beta"
      exit 1
    end
    user = User.find_by(username: username)
    unless user
      puts "User not found: #{username}"
      exit 1
    end
    user.update!(allow_career_architect: true)
    puts "Career Architect enabled for #{user.username} (#{user.email})"
  end

  desc "Disable Career Architect (beta) for a user by username"
  task disable_beta: :environment do
    username = ENV["USERNAME"]
    unless username.present?
      puts "Usage: USERNAME=username bin/rails architect:disable_beta"
      exit 1
    end
    user = User.find_by(username: username)
    unless user
      puts "User not found: #{username}"
      exit 1
    end
    user.update!(allow_career_architect: false)
    puts "Career Architect disabled for #{user.username}"
  end

  desc "List users who have Career Architect (beta) access"
  task list_beta: :environment do
    users = User.where(allow_career_architect: true).order(:username)
    if users.empty?
      puts "No users with Career Architect access."
      return
    end
    puts "Users with Career Architect access (#{users.count}):"
    users.each { |u| puts "  #{u.username} (#{u.email})" }
  end

  desc "Report ArchitectReplyJob queue status (pending, failed, finished)"
  task queue_status: :environment do
    require "solid_queue"

    pending = SolidQueue::Job.where(class_name: ARCHITECT_JOB_CLASS).where(finished_at: nil).count
    failed = SolidQueue::FailedExecution.joins(:job).where(solid_queue_jobs: { class_name: ARCHITECT_JOB_CLASS }).count
    finished_24h = SolidQueue::Job.where(class_name: ARCHITECT_JOB_CLASS).where("finished_at > ?", 24.hours.ago).count

    puts "\nCareer Architect queue (ArchitectReplyJob):"
    puts "  Pending:     #{pending}"
    puts "  Failed:      #{failed}"
    puts "  Finished (24h): #{finished_24h}"
  rescue NameError, LoadError => e
    puts "Could not load Solid Queue: #{e.message}"
    puts "Queue status requires the solid_queue gem and queue database."
  end

  desc "Report Career Architect session stats and estimated cost"
  task stats: :environment do
    total = ArchitectSession.count
    completed = ArchitectSession.completed.count
    created_24h = ArchitectSession.where("created_at > ?", 24.hours.ago).count
    completed_24h = ArchitectSession.completed.where("updated_at > ?", 24.hours.ago).count

    puts "\nCareer Architect stats:"
    puts "  Sessions (all time):  #{total}"
    puts "  Completed:            #{completed}"
    puts "  Created (24h):        #{created_24h}"
    puts "  Completed (24h):      #{completed_24h}"
    puts "  Est. cost (all time): $#{format('%.2f', completed * ESTIMATED_COST_PER_SESSION)} (~$#{ESTIMATED_COST_PER_SESSION}/session)"
  end
end
