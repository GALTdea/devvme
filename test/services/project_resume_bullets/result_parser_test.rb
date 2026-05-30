require "test_helper"

class ProjectResumeBullets::ResultParserTest < ActiveSupport::TestCase
  test "parses strict json payload" do
    payload = {
      "version" => 1,
      "resume_bullets" => [
        {
          "text" => "Designed and implemented a REST API for project portfolio management.",
          "focus" => "architecture",
          "source_notes" => ["Based on project story", "Based on technologies"]
        },
        {
          "text" => "",
          "focus" => "technical_depth",
          "source_notes" => []
        }
      ],
      "missing_context_questions" => ["What was your specific role on this project?"]
    }

    result = ProjectResumeBullets::ResultParser.parse(payload.to_json)

    assert_equal 1, result["resume_bullets"].size
    assert_equal "Designed and implemented a REST API for project portfolio management.", result.dig("resume_bullets", 0, "text")
    assert_equal "architecture", result.dig("resume_bullets", 0, "focus")
    assert_equal 2, result.dig("resume_bullets", 0, "source_notes").size
    assert_equal 1, result["missing_context_questions"].size
  end

  test "parses fenced json and normalizes unknown focus values" do
    text = <<~TEXT
      ```json
      {
        "resume_bullets": [
          {
            "text": "Integrated GitHub signals into project enrichment workflows.",
            "focus": "unknown_focus",
            "source_notes": ["Based on GitHub signals"]
          }
        ],
        "extra_key": "ignored"
      }
      ```
    TEXT

    result = ProjectResumeBullets::ResultParser.parse(text)

    assert_equal "general", result.dig("resume_bullets", 0, "focus")
    assert_not result.key?("extra_key")
  end

  test "raises parse error for invalid json" do
    assert_raises(ProjectResumeBullets::ResultParser::ParseError) do
      ProjectResumeBullets::ResultParser.parse("not json")
    end
  end

  test "limits number of bullets returned" do
    bullets = (1..8).map do |i|
      { "text" => "Bullet #{i}", "focus" => "general", "source_notes" => [] }
    end
    payload = { "resume_bullets" => bullets, "missing_context_questions" => [] }

    result = ProjectResumeBullets::ResultParser.parse(payload.to_json)

    assert_equal ProjectResumeBullets::ResultParser::MAX_BULLETS, result["resume_bullets"].size
  end
end
