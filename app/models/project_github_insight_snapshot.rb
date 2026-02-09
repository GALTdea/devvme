# frozen_string_literal: true

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
class ProjectGitHubInsightSnapshot < ApplicationRecord
  SYNC_TYPES = %w[light deep].freeze
  SOURCES = %w[auto manual].freeze

  belongs_to :project

  validates :sync_type, presence: true, inclusion: { in: SYNC_TYPES }
  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :captured_at, presence: true
end
