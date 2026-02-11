# == Schema Information
#
# Table name: project_github_insight_snapshots
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  captured_at        :datetime         not null
#  duration_ms        :integer
#  errors_payload     :jsonb            not null
#  highlights_payload :jsonb            not null
#  metrics_payload    :jsonb            not null
#  repo_payload       :jsonb            not null
#  source             :string           not null
#  sync_type          :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  project_id         :bigint           not null
#
# Indexes
#
#  idx_proj_gh_insight_snapshots_project_captured        (project_id,captured_at)
#  index_project_github_insight_snapshots_on_project_id  (project_id)
#  index_project_github_insight_snapshots_on_source      (source)
#  index_project_github_insight_snapshots_on_sync_type   (sync_type)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#
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
