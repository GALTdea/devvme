class BetaController < ApplicationController
  def confirmation
    # Show beta confirmation page for users who just signed up
  end

  def waiting
    # Show waiting page for pending activation users who try to access the app
    redirect_to root_path unless user_signed_in? && current_user.pending_activation?
  end
end
