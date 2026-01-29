# == Schema Information
#
# Table name: admin_activities
#
#  id          :bigint           not null, primary key
#  action      :string           not null
#  details     :json
#  ip_address  :string
#  target_type :string
#  user_agent  :string(500)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  admin_id    :bigint           not null
#  target_id   :bigint
#
# Indexes
#
#  index_admin_activities_on_action                     (action)
#  index_admin_activities_on_admin_id                   (admin_id)
#  index_admin_activities_on_admin_id_and_created_at    (admin_id,created_at)
#  index_admin_activities_on_created_at                 (created_at)
#  index_admin_activities_on_target_type_and_target_id  (target_type,target_id)
#
# Foreign Keys
#
#  fk_rails_...  (admin_id => users.id)
#
class AdminActivity < ApplicationRecord
  belongs_to :admin, class_name: "User"
  belongs_to :target, polymorphic: true, optional: true

  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_action, ->(action) { where(action: action) }
  scope :for_admin, ->(admin) { where(admin: admin) }
  scope :today, -> { where(created_at: Date.current.all_day) }
  scope :this_week, -> { where(created_at: 1.week.ago..Time.current) }
  scope :this_month, -> { where(created_at: 1.month.ago..Time.current) }

  def target_description
    return "N/A" unless target

    case target_type
    when "User"
      "User: #{details['target_username'] || target&.username}"
    when "BlogPost"
      "Blog Post: #{details['target_title'] || target&.title}"
    when "Project"
      "Project: #{details['target_title'] || target&.title}"
    else
      "#{target_type}: #{target_id}"
    end
  end

  def action_description
    case action
    when "suspend_user"
      "Suspended user"
    when "unsuspend_user"
      "Unsuspended user"
    when "delete_user"
      "Deleted user"
    when "promote_user"
      "Promoted user to admin"
    when "demote_user"
      "Demoted user from admin"
    when "moderate_blog_post"
      "Moderated blog post"
    when "moderate_project"
      "Moderated project"
    when "view_admin_dashboard"
      "Viewed admin dashboard"
    when "bulk_operation"
      "Performed bulk operation"
    else
      action.humanize
    end
  end
end
