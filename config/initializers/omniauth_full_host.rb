# frozen_string_literal: true

# In development, force a stable OAuth host so GitHub callback validation
# does not break when requests come from ::1/127.0.0.1/localhost variants.
if Rails.env.development?
  OmniAuth.config.full_host = ENV.fetch("OMNIAUTH_FULL_HOST", "http://localhost:3000")
end
