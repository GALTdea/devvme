require "test_helper"

class UserActivationMailerTest < ActionMailer::TestCase
  test "activation_notification" do
    skip "User activation mailer not yet implemented"
    # TODO: Implement when user activation feature is ready
    # mail = UserActivationMailer.activation_notification
    # assert_equal "Activation notification", mail.subject
    # assert_equal [ "to@example.org" ], mail.to
    # assert_equal [ "from@example.com" ], mail.from
    # assert_match "Hi", mail.body.encoded
  end
end
