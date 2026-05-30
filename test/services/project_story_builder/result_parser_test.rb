require "test_helper"

class ProjectStoryBuilder::ResultParserTest < ActiveSupport::TestCase
  test "parses strict json payload" do
    payload = {
      "version" => 1,
      "fields" => {
        "overview" => "A portfolio app",
        "problem" => "Developers struggle to explain projects"
      },
      "evidence_notes" => [{ "source" => "project_metadata", "summary" => "Used title and description" }],
      "missing_context_questions" => ["What was hardest for you personally?"]
    }

    result = ProjectStoryBuilder::ResultParser.parse(payload.to_json)

    assert_equal "A portfolio app", result.dig("fields", "overview")
    assert_equal "Developers struggle to explain projects", result.dig("fields", "problem")
    assert_equal "", result.dig("fields", "role")
    assert_equal 1, result["evidence_notes"].size
    assert_equal 1, result["missing_context_questions"].size
  end

  test "parses fenced json and ignores unknown fields" do
    text = <<~TEXT
      ```json
      {
        "fields": {
          "overview": "Summary",
          "resume_bullet": "Should be ignored"
        }
      }
      ```
    TEXT

    result = ProjectStoryBuilder::ResultParser.parse(text)

    assert_equal "Summary", result.dig("fields", "overview")
    assert_not result["fields"].key?("resume_bullet")
  end

  test "raises parse error for invalid json" do
    assert_raises(ProjectStoryBuilder::ResultParser::ParseError) do
      ProjectStoryBuilder::ResultParser.parse("not json")
    end
  end
end
