require "test_helper"

class UserActivationMailerTest < ActionMailer::TestCase
  test "activation_notification" do
    mail = UserActivationMailer.activation_notification
    assert_equal "Activation notification", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
