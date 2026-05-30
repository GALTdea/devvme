require "test_helper"

class ProjectResumeBullets::GenerationServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:test_user_one)
    @project = projects(:test_project_one)
  end

  test "returns parsed resume bullets from openai response" do
    response_json = {
      "version" => 1,
      "resume_bullets" => [
        {
          "text" => "Built a proof-of-work platform using Ruby on Rails and PostgreSQL.",
          "focus" => "technical_depth",
          "source_notes" => ["Based on project story"]
        }
      ],
      "missing_context_questions" => ["What measurable outcomes did this project achieve?"]
    }.to_json

    service = ProjectResumeBullets::GenerationService.new
    with_stubbed_singleton_method(service, :call_openai, response_json) do
      result = service.call(project: @project, user: @user, emphasis: "Emphasize backend work")

      assert_equal 1, result["resume_bullets"].size
      assert_match(/proof-of-work platform/, result.dig("resume_bullets", 0, "text"))
      assert_equal "technical_depth", result.dig("resume_bullets", 0, "focus")
      assert_equal 1, result["missing_context_questions"].size
    end
  end

  test "raises when emphasis notes are too long" do
    assert_raises(ProjectResumeBullets::GenerationService::GenerationError) do
      ProjectResumeBullets::GenerationService.call(
        project: @project,
        user: @user,
        emphasis: "a" * (ProjectResumeBullets::GenerationService::MAX_EMPHASIS_CHARS + 1)
      )
    end
  end

  test "raises missing api key error when openai is not configured" do
    with_stubbed_singleton_method(ArchitectService, :openai_api_key, nil) do
      assert_raises(ArchitectService::MissingApiKeysError) do
        ProjectResumeBullets::GenerationService.call(project: @project, user: @user)
      end
    end
  end

  test "system prompt forbids invented metrics and unsupported impact claims" do
    service = ProjectResumeBullets::GenerationService.new
    prompt = service.send(:system_prompt)

    assert_match(/Do not invent metrics/i, prompt)
    assert_match(/Do not claim production users/i, prompt)
    assert_match(/Avoid first-person language/i, prompt)
    assert_match(/Do not rewrite the whole resume/i, prompt)
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
