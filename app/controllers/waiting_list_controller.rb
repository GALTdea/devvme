class WaitingListController < ApplicationController
  # Public controller - no authentication required

  def new
    @waiting_list_entry = WaitingListEntry.new
  end

  def create
    @waiting_list_entry = WaitingListEntry.new(waiting_list_params)
    @waiting_list_entry.source = params[:source] || 'direct'

    if @waiting_list_entry.save
      redirect_to waiting_list_success_path, notice: 'You\'ve been added to the waiting list!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def success
    # Success page after signing up
  end

  private

  def waiting_list_params
    params.require(:waiting_list_entry).permit(:email, :full_name)
  end
end
