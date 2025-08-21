class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_owner, only: [ :show, :edit, :update, :destroy ]

  def index
    @projects = current_user.projects.by_display_order.includes(images_attachments: :blob)
  end

  def show
  end

  def new
    @project = current_user.projects.build
  end

  def create
    @project = current_user.projects.build(project_params)

    if @project.save
      redirect_to @project, notice: "Project was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: "Project was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy!
    redirect_to projects_path, notice: "Project was successfully deleted."
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def ensure_owner
    unless @project.user == current_user
      redirect_to projects_path, alert: "You can only access your own projects."
    end
  end

  def project_params
    params.require(:project).permit(:title, :description, :live_url, :source_code_url,
                                   :featured, :status, :display_order, :technologies_display,
                                   :thumbnail, images: [])
  end
end
