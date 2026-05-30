require "test_helper"

class ProjectStoryBuilder::GenerationServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:test_user_one)
    @project = projects(:test_project_one)
  end

  test "returns parsed suggestions from openai response" do
    response_json = {
      "version" => 1,
      "fields" => {
        "overview" => "DevvMe helps developers explain real work",
        "problem" => "Project stories are often vague"
      },
      "evidence_notes" => [{ "source" => "project_metadata", "summary" => "Used title and description" }],
      "missing_context_questions" => ["What did you personally build?"]
    }.to_json

    service = ProjectStoryBuilder::GenerationService.new
    with_stubbed_singleton_method(service, :call_openai, response_json) do
      result = service.call(project: @project, user: @user, rough_notes: "I built the story flow")

      assert_equal "DevvMe helps developers explain real work", result.dig("fields", "overview")
      assert_equal "Project stories are often vague", result.dig("fields", "problem")
      assert_equal 1, result["missing_context_questions"].size
    end
  end

  test "raises when rough notes are too long" do
    assert_raises(ProjectStoryBuilder::GenerationService::GenerationError) do
      ProjectStoryBuilder::GenerationService.call(
        project: @project,
        user: @user,
        rough_notes: "a" * (ProjectStoryBuilder::GenerationService::MAX_ROUGH_NOTES_CHARS + 1)
      )
    end
  end

  test "raises missing api key error when openai is not configured" do
    with_stubbed_singleton_method(ArchitectService, :openai_api_key, nil) do
      assert_raises(ArchitectService::MissingApiKeysError) do
        ProjectStoryBuilder::GenerationService.call(project: @project, user: @user)
      end
    end
  end

  private

  def with_stubbed_singleton_method(target, method_name, replacement)
    original = target.method(method_name)
    target.define_singleton_method(method_name) do |*args, **kwargs, &block|
      if replacement.is_a?(Proc)
        replacement.call(*args, **kwargs)
      else
        replacement
      end
    end
    yield
  ensure
    target.define_singleton_method(method_name, original)
  end
end
