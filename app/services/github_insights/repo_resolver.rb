# frozen_string_literal: true

module GitHubInsights
  class RepoResolver
    GITHUB_HOST_PATTERN = /\A(?:www\.)?github\.com\z/i

    class InvalidRepositoryUrlError < StandardError; end

    def self.resolve!(url)
      new.resolve!(url)
    end

    def self.resolve_project!(project)
      new.resolve_project!(project)
    end

    def resolve_project!(project)
      resolve!(project&.project_github_repo_url)
    end

    def resolve!(url)
      normalized_url = normalize(url)
      uri = URI.parse(normalized_url)

      unless uri.host.to_s.match?(GITHUB_HOST_PATTERN)
        raise InvalidRepositoryUrlError, "Repository URL must point to github.com"
      end

      owner, repo = extract_owner_repo(uri.path)
      raise InvalidRepositoryUrlError, "Repository URL must include owner and repository name" if owner.blank? || repo.blank?

      {
        owner: owner,
        repo: repo,
        canonical_url: "https://github.com/#{owner}/#{repo}"
      }
    rescue URI::InvalidURIError
      raise InvalidRepositoryUrlError, "Repository URL is invalid"
    end

    private

    def normalize(url)
      value = url.to_s.strip
      raise InvalidRepositoryUrlError, "Repository URL is required" if value.blank?

      value.match?(/\A[a-z][a-z0-9+.-]*:/i) ? value : "https://#{value}"
    end

    def extract_owner_repo(path)
      segments = path.to_s.split("/").reject(&:blank?)
      owner = safe_decode(segments[0])
      repo = safe_decode(segments[1]).to_s.sub(/\.git\z/i, "")
      [owner, repo]
    end

    def safe_decode(value)
      URI.decode_www_form_component(value.to_s)
    rescue ArgumentError
      value.to_s
    end
  end
end
