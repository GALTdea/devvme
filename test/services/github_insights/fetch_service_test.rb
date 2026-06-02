require "test_helper"

module GitHubInsights
  class FetchServiceTest < ActiveSupport::TestCase
    test "uses oauth token in headers when provided" do
      service = FetchService.new(oauth_token: "owner-token")
      headers = service.send(:headers)

      assert_equal "Bearer owner-token", headers["Authorization"]
    end

    test "falls back to app github token when oauth token is absent" do
      service = FetchService.new
      original = GitHubContextService.method(:api_token)
      GitHubContextService.define_singleton_method(:api_token) { "app-token" }

      headers = service.send(:headers)
      assert_equal "Bearer app-token", headers["Authorization"]
    ensure
      GitHubContextService.define_singleton_method(:api_token, original)
    end

    test "returns baseline payload for light sync" do
      service = stubbed_service do |path, _params|
        case path
        when %r{\Arepos/acme/demo\z}
          { "default_branch" => "main", "name" => "demo" }
        when %r{\Arepos/acme/demo/languages\z}
          { "Ruby" => 700, "JavaScript" => 300 }
        when %r{\Arepos/acme/demo/readme\z}
          base64_blob("README content")
        when %r{\Arepos/acme/demo/git/trees/main\z}
          { "tree" => [{ "type" => "blob", "path" => "app/models/user.rb" }] }
        when %r{\Arepos/acme/demo/commits\z}
          [{ "sha" => "abc123" }]
        else
          nil
        end
      end

      payload = service.call(owner: "acme", repo: "demo", sync_type: "light")

      assert_equal "light", payload["sync_type"]
      assert payload["repo"].present?
      assert payload["languages"].any?
      assert payload["readme"].present?
      assert payload["tree_paths"].any?
      assert payload["commits"].any?
      assert_nil payload["pull_requests"]
      assert_nil payload["issues"]
      assert_nil payload["contributors"]
    end

    test "returns deep payload and filters issue entries that are pull requests" do
      service = stubbed_service do |path, _params|
        case path
        when %r{\Arepos/acme/demo\z}
          { "default_branch" => "main", "name" => "demo" }
        when %r{\Arepos/acme/demo/languages\z}
          { "Ruby" => 1000 }
        when %r{\Arepos/acme/demo/readme\z}
          base64_blob("README")
        when %r{\Arepos/acme/demo/git/trees/main\z}
          { "tree" => [{ "type" => "blob", "path" => "Gemfile" }] }
        when %r{\Arepos/acme/demo/contents/Gemfile\z}
          base64_blob("source 'https://rubygems.org'")
        when %r{\Arepos/acme/demo/commits\z}
          [{ "sha" => "1" }]
        when %r{\Arepos/acme/demo/pulls\z}
          [{ "id" => 1 }]
        when %r{\Arepos/acme/demo/issues\z}
          [{ "id" => 1, "state" => "open", "pull_request" => { "url" => "x" } }, { "id" => 2, "state" => "closed" }]
        when %r{\Arepos/acme/demo/contributors\z}
          [{ "login" => "alice" }]
        when %r{\Arepos/acme/demo/releases\z}
          [{ "tag_name" => "v1.0.0" }]
        else
          nil
        end
      end

      payload = service.call(owner: "acme", repo: "demo", sync_type: "deep")

      assert_equal "deep", payload["sync_type"]
      assert_equal 1, payload["pull_requests"].size
      assert_equal 1, payload["contributors"].size
      assert_equal 1, payload["releases"].size
      assert_equal [2], payload["issues"].map { |issue| issue["id"] }
    end

    test "raises repository not found error" do
      service = stubbed_service do |_path, _params|
        raise FetchService::RepositoryNotFoundError, "Repository not found or not publicly accessible."
      end

      assert_raises(FetchService::RepositoryNotFoundError) do
        service.call(owner: "acme", repo: "missing", sync_type: "light")
      end
    end

    test "raises authentication error for unauthorized owner oauth response" do
      service = FetchService.new(oauth_token: "owner-token")
      response = Struct.new(:status, :body) do
        def success?
          false
        end
      end.new(401, { "message" => "Bad credentials" })
      connection = Struct.new(:response) do
        attr_reader :requests

        def initialize(response)
          super(response)
          @requests = []
        end

        def get(*request)
          requests << request
          response
        end
      end.new(response)

      service.define_singleton_method(:connection) { connection }

      error = assert_raises(FetchService::AuthenticationError) do
        service.send(:get, "/repos/acme/demo")
      end

      assert_match(/authentication failed/i, error.message)
      assert_match(/GITHUB_TOKEN/i, error.message)
      assert_equal 1, connection.requests.size
    end

    test "retries without authorization when configured app token is rejected" do
      service = FetchService.new
      responses = [
        Struct.new(:status, :body) { def success? = false }.new(401, { "message" => "Bad credentials" }),
        Struct.new(:status, :body) { def success? = true }.new(200, { "name" => "demo" })
      ]
      requests = []
      connection = Struct.new(:responses, :requests) do
        def get(*request)
          requests << request
          responses.shift
        end
      end.new(responses, requests)

      original = GitHubContextService.method(:api_token)
      GitHubContextService.define_singleton_method(:api_token) { "bad-app-token" }
      service.define_singleton_method(:connection) { connection }

      assert_equal({ "name" => "demo" }, service.send(:get, "/repos/acme/demo"))
      assert_equal "Bearer bad-app-token", requests.first.last["Authorization"]
      assert_nil requests.second.last["Authorization"]
    ensure
      GitHubContextService.define_singleton_method(:api_token, original) if original
    end

    test "raises for unsupported sync type" do
      assert_raises(FetchService::FetchError) do
        FetchService.call(owner: "acme", repo: "demo", sync_type: "invalid")
      end
    end

    private

    def stubbed_service(&block)
      service = FetchService.new
      service.define_singleton_method(:get) do |path, params = {}, allow_not_found: false, **query_params|
        query = (params.is_a?(Hash) ? params : {}).merge(query_params)
        block.call(path.sub(%r{\A/}, ""), query)
      rescue FetchService::RepositoryNotFoundError
        raise
      end
      service
    end

    def base64_blob(content)
      { "encoding" => "base64", "content" => Base64.strict_encode64(content) }
    end
  end
end
