class NewUserSignupNotification < Noticed::Base
  # Only deliver to database (in-app notifications)
  deliver_by :database

  # Parameters passed when creating the notification
  param :user

  # Helper methods for notification display
  def title
    "New User Signup: #{params[:user].username}"
  end

  def message
    "#{params[:user].username} (#{params[:user].email}) just signed up."
  end

  def user
    params[:user]
  end
end
