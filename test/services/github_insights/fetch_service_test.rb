require "test_helper"

module GitHubInsights
  class FetchServiceTest < ActiveSupport::TestCase
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
