require "test_helper"

class ProjectGitHubInsightSnapshotTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    project = projects(:test_project_one)
    snapshot = ProjectGitHubInsightSnapshot.new(
      project: project,
      sync_type: "light",
      source: "auto",
      captured_at: Time.current
    )

    assert snapshot.valid?
  end

  test "requires project association" do
    snapshot = ProjectGitHubInsightSnapshot.new(
      sync_type: "light",
      source: "auto",
      captured_at: Time.current
    )

    assert_not snapshot.valid?
    assert_includes snapshot.errors[:project], "must exist"
  end

  test "validates sync_type inclusion" do
    snapshot = ProjectGitHubInsightSnapshot.new(
      project: projects(:test_project_one),
      sync_type: "invalid",
      source: "auto",
      captured_at: Time.current
    )

    assert_not snapshot.valid?
    assert_includes snapshot.errors[:sync_type], "is not included in the list"
  end

  test "validates source inclusion" do
    snapshot = ProjectGitHubInsightSnapshot.new(
      project: projects(:test_project_one),
      sync_type: "deep",
      source: "bad",
      captured_at: Time.current
    )

    assert_not snapshot.valid?
    assert_includes snapshot.errors[:source], "is not included in the list"
  end

  test "requires captured_at" do
    snapshot = ProjectGitHubInsightSnapshot.new(
      project: projects(:test_project_one),
      sync_type: "deep",
      source: "manual",
      captured_at: nil
    )

    assert_not snapshot.valid?
    assert_includes snapshot.errors[:captured_at], "can't be blank"
  end
end
