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
require "test_helper"

class AdminActivityTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
