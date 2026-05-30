# frozen_string_literal: true

module Dashboard
  class ProofOfWorkNextAction
    include Rails.application.routes.url_helpers

    attr_reader :user

    def initialize(user)
      @user = user
    end

    def state
      return :no_projects if projects.empty?
      return :publish_project_story if draft_meaningful_project
      return :improve_published_story if published_projects.any? && published_story_projects.empty?
      return :add_story_context if meaningful_projects.empty?
      return :share_project_story if published_story_projects.one?

      :share_proof_of_work_profile
    end

    def title
      case state
      when :no_projects
        "Turn your work into proof"
      when :add_story_context
        "Make one project easier to explain"
      when :publish_project_story
        "Publish your project story"
      when :improve_published_story
        "Improve your published story"
      when :share_project_story
        "Share your project story"
      when :share_proof_of_work_profile
        "Share your proof-of-work profile"
      end
    end

    def body
      case state
      when :no_projects
        "Start with one real project you've built. DevvMe will help you turn it into clear proof-of-work."
      when :add_story_context
        "Help visitors understand what you built, why it matters, and what it demonstrates."
      when :publish_project_story
        "Your story has enough context to become public proof-of-work."
      when :improve_published_story
        "Your project is public, but it needs more context to become strong proof-of-work."
      when :share_project_story
        "Your work is ready to share with recruiters, peers, clients, or collaborators."
      when :share_proof_of_work_profile
        "Your profile now has multiple proof points. Share the full profile to show the range of your work."
      end
    end

    def cta_label
      case state
      when :no_projects
        "Create your first project story"
      when :add_story_context
        "Add story context"
      when :publish_project_story
        "Publish your project story"
      when :improve_published_story
        "Improve your published story"
      when :share_project_story
        "Share your project story"
      when :share_proof_of_work_profile
        "Share your proof-of-work profile"
      end
    end

    def cta_path
      case state
      when :no_projects
        new_project_path
      when :add_story_context
        edit_project_path(project_without_meaningful_story, anchor: "story-builder")
      when :publish_project_story
        edit_project_path(draft_meaningful_project, anchor: "story-builder")
      when :improve_published_story
        edit_project_path(published_project_without_meaningful_story, anchor: "story-builder")
      when :share_project_story
        public_project_path(published_story_project)
      when :share_proof_of_work_profile
        public_profile_path(user.friendly_id)
      end
    end

    def secondary_cta_label
      return "Generate resume bullets" if state == :share_project_story
      return "Generate resume bullets" if state == :share_proof_of_work_profile

      nil
    end

    def secondary_cta_path
      if state == :share_project_story
        return edit_project_path(published_story_project, anchor: "resume-bullets")
      end

      return edit_project_path(strongest_story_project, anchor: "resume-bullets") if state == :share_proof_of_work_profile

      nil
    end

    private

    def projects
      @projects ||= user.projects.order(updated_at: :desc, id: :desc).to_a
    end

    def meaningful_projects
      @meaningful_projects ||= projects.select(&:story_meaningful?)
    end

    def published_projects
      @published_projects ||= projects.select(&:published?)
    end

    def published_story_projects
      @published_story_projects ||= published_projects.select(&:story_meaningful?)
    end

    def draft_meaningful_project
      @draft_meaningful_project ||= meaningful_projects.find { |project| !project.published? }
    end

    def project_without_meaningful_story
      @project_without_meaningful_story ||= projects.find { |project| !project.story_meaningful? }
    end

    def published_project_without_meaningful_story
      @published_project_without_meaningful_story ||= published_projects.find { |project| !project.story_meaningful? }
    end

    def published_story_project
      @published_story_project ||= published_story_projects.first
    end

    def strongest_story_project
      @strongest_story_project ||= published_story_projects.first
    end
  end
end
