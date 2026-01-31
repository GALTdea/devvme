# == Schema Information
#
# Table name: profile_views
# Database name: primary
#
#  id         :bigint           not null, primary key
#  referrer   :string(500)
#  user_agent :string(500)
#  visited_at :datetime         not null
#  visitor_ip :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_profile_views_on_user_id                                (user_id)
#  index_profile_views_on_user_id_and_visited_at                 (user_id,visited_at)
#  index_profile_views_on_visited_at                             (visited_at)
#  index_profile_views_on_visitor_ip_and_user_id_and_visited_at  (visitor_ip,user_id,visited_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class ProfileViewTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
