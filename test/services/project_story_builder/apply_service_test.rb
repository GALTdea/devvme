require "test_helper"

class ProjectStoryBuilder::ApplyServiceTest < ActiveSupport::TestCase
  setup do
    @project = projects(:test_project_one)
    @project.update!(project_story: {
      "overview" => "Existing overview",
      "problem" => "",
      "role" => "Existing role"
    })
    @suggestions = {
      "fields" => {
        "overview" => "Suggested overview",
        "problem" => "Suggested problem",
        "role" => "Suggested role"
      }
    }
  end

  test "applies blank only selections without overwriting existing content" do
    applied = ProjectStoryBuilder::ApplyService.call(
      project: @project,
      suggestions: @suggestions,
      selections: {
        "overview" => "blank_only",
        "problem" => "blank_only",
        "role" => "blank_only"
      }
    )

    assert_equal ["problem"], applied
    @project.reload
    assert_equal "Existing overview", @project.project_story["overview"]
    assert_equal "Suggested problem", @project.project_story["problem"]
    assert_equal "Existing role", @project.project_story["role"]
  end

  test "replaces existing content only when replace is selected" do
    applied = ProjectStoryBuilder::ApplyService.call(
      project: @project,
      suggestions: @suggestions,
      selections: {
        "overview" => "replace",
        "problem" => "blank_only"
      }
    )

    assert_equal %w[overview problem], applied.sort
    @project.reload
    assert_equal "Suggested overview", @project.project_story["overview"]
    assert_equal "Suggested problem", @project.project_story["problem"]
  end

  test "raises when no eligible fields are selected" do
    assert_raises(ProjectStoryBuilder::ApplyService::ApplyError) do
      ProjectStoryBuilder::ApplyService.call(
        project: @project,
        suggestions: @suggestions,
        selections: { "overview" => "blank_only" }
      )
    end
  end
end
