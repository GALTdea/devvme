# frozen_string_literal: true

module ProjectResumeBullets
  class RateLimiter
    DAILY_LIMIT = 10
    COOLDOWN_SECONDS = 30
    FALLBACK_STORE = ActiveSupport::Cache::MemoryStore.new

    def self.allowed?(user:, project:)
      new.allowed?(user:, project:)
    end

    def allowed?(user:, project:)
      return [ false, "Authentication required" ] if user.blank?

      if daily_count(user) >= DAILY_LIMIT
        return [ false, "Daily resume bullet limit reached. Try again tomorrow." ]
      end

      if cooldown_active?(user, project)
        return [ false, "Please wait a few seconds before generating resume bullets for this project again." ]
      end

      [ true, nil ]
    end

    def track!(user:, project:)
      key = daily_key(user)
      count = cache_store.read(key).to_i
      ttl = (Time.current.end_of_day - Time.current).to_i
      cache_store.write(key, count + 1, expires_in: ttl)
      cache_store.write(cooldown_key(user, project), true, expires_in: COOLDOWN_SECONDS)
    end

    private

    def daily_count(user)
      cache_store.read(daily_key(user)).to_i
    end

    def cooldown_active?(user, project)
      cache_store.read(cooldown_key(user, project)).present?
    end

    def daily_key(user)
      date = Time.current.to_date.iso8601
      "project_resume_bullets:daily:#{user.id}:#{date}"
    end

    def cooldown_key(user, project)
      "project_resume_bullets:cooldown:#{user.id}:#{project.id}"
    end

    def cache_store
      Rails.cache.is_a?(ActiveSupport::Cache::NullStore) ? FALLBACK_STORE : Rails.cache
    end
  end
end
