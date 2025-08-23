class Admin::ActivitiesController < ApplicationController
  before_action :require_admin
  before_action :set_activity, only: [:show]

  include Pagy::Backend

  def index
    @pagy, @activities = pagy(
      AdminActivity.includes(:admin, :target).recent,
      limit: 25
    )

    # Apply filters
    @activities = @activities.for_action(params[:action_filter]) if params[:action_filter].present?
    @activities = @activities.for_admin(params[:admin_id]) if params[:admin_id].present?
    @activities = @activities.today if params[:period] == 'today'
    @activities = @activities.this_week if params[:period] == 'week'
    @activities = @activities.this_month if params[:period] == 'month'

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @activities = @activities.joins(:admin)
                              .where("users.username ILIKE ? OR admin_activities.action ILIKE ?",
                                     search_term, search_term)
    end

    @activity_stats = {
      total_activities: AdminActivity.count,
      activities_today: AdminActivity.today.count,
      activities_this_week: AdminActivity.this_week.count,
      activities_this_month: AdminActivity.this_month.count
    }

    @top_actions = AdminActivity.group(:action).count.sort_by { |_, count| -count }.first(5)
    @active_admins = AdminActivity.joins(:admin)
                                 .this_week
                                 .group('users.username')
                                 .count
                                 .sort_by { |_, count| -count }
                                 .first(5)
  end

  def show
    @related_activities = AdminActivity.where(target: @activity.target)
                                      .where.not(id: @activity.id)
                                      .recent
                                      .limit(10)
  end

  private

  def set_activity
    @activity = AdminActivity.find(params[:id])
  end
end
