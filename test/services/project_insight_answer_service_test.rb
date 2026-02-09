require "test_helper"

class ProjectInsightAnswerServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:test_user_one)
    @project = projects(:test_project_one)
    @project.update!(project_insight_enabled: true, source_code_url: "https://github.com/rails/rails")
  end

  test "returns actionable message when repo is not accessible" do
    original_fetch = ProjectInsight::AnalysisService.method(:fetch)
    ProjectInsight::AnalysisService.singleton_class.send(:define_method, :fetch) do |project, force_refresh: false|
      raise ProjectInsight::AnalysisService::RepositoryNotFoundError, "not found"
    end

    error = assert_raises(ProjectInsight::AnswerService::AnswerError) do
      ProjectInsight::AnswerService.call(project: @project, question: "What does this project do?", user: @user)
    end

    assert_match(/Repository could not be accessed/i, error.message)
  ensure
    ProjectInsight::AnalysisService.singleton_class.send(:define_method, :fetch, original_fetch)
  end
end
