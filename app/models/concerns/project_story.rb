# frozen_string_literal: true

module ProjectStory
  extend ActiveSupport::Concern

  STORY_VERSION = 1
  STORY_FIELD_MAX_LENGTH = 2000

  STORY_FIELDS = %w[
    overview
    problem
    intended_users
    why_built
    role
    technical_decisions
    hardest_challenge
    lessons_learned
    demonstrates
    promotion_notes
  ].freeze

  PUBLIC_STORY_FIELDS = (STORY_FIELDS - %w[promotion_notes]).freeze

  PUBLIC_STORY_SECTIONS = {
    "overview" => { label: "Overview", prompt: nil },
    "problem" => { label: "Problem Solved", prompt: "What problem does this project address?" },
    "intended_users" => { label: "Intended Users", prompt: "Who is this project for?" },
    "why_built" => { label: "Why It Was Built", prompt: "What motivated you to build this?" },
    "role" => { label: "Developer Role", prompt: "What was your contribution?" },
    "technical_decisions" => { label: "Key Technical Decisions", prompt: "What architecture or implementation choices matter?" },
    "hardest_challenge" => { label: "Hardest Challenge", prompt: "What was the toughest part?" },
    "lessons_learned" => { label: "Lessons Learned", prompt: "What did you take away from this work?" },
    "demonstrates" => { label: "What This Demonstrates", prompt: "What skills or proof does this project show?" }
  }.freeze

  FORM_STORY_SECTIONS = {
    "overview" => {
      label: "Project Overview",
      prompt: "What is this project? A short summary for visitors.",
      rows: 3
    },
    "problem" => {
      label: "Problem Solved",
      prompt: "What problem does it address?",
      rows: 3
    },
    "intended_users" => {
      label: "Intended Users",
      prompt: "Who is it for?",
      rows: 2
    },
    "why_built" => {
      label: "Why You Built It",
      prompt: "What motivated this work?",
      rows: 3
    },
    "role" => {
      label: "Your Role",
      prompt: "What did you personally build or own?",
      rows: 2
    },
    "technical_decisions" => {
      label: "Key Technical Decisions",
      prompt: "What architecture or implementation choices matter?",
      rows: 3
    },
    "hardest_challenge" => {
      label: "Hardest Challenge",
      prompt: "What was the toughest part?",
      rows: 3
    },
    "lessons_learned" => {
      label: "Lessons Learned",
      prompt: "What did you take away from this project?",
      rows: 3
    },
    "demonstrates" => {
      label: "What This Demonstrates",
      prompt: "What skills or proof-of-work does this show?",
      rows: 3
    },
    "promotion_notes" => {
      label: "Promotion Notes",
      prompt: "Private notes for future sharing assets. Not shown publicly.",
      rows: 2,
      private: true
    }
  }.freeze

  included do
    validate :validate_project_story_fields
  end

  class_methods do
    def default_project_story
      {
        "version" => STORY_VERSION,
        **STORY_FIELDS.index_with { "" }
      }
    end
  end

  def project_story
    self.class.default_project_story.merge(read_attribute(:project_story).presence || {})
  end

  def project_story=(value)
    write_attribute(:project_story, normalize_project_story(value))
  end

  def public_story_overview
    project_story["overview"].presence || description
  end

  def story_overview_from_story?
    project_story["overview"].present?
  end

  def public_story_sections
    sections = []

    PUBLIC_STORY_FIELDS.each do |field|
      content = project_story[field].to_s.strip
      next if content.blank?

      meta = PUBLIC_STORY_SECTIONS.fetch(field)
      sections << {
        key: field,
        label: meta[:label],
        content: content
      }
    end

    sections
  end

  def has_public_story_content?
    public_story_sections.any? || story_overview_from_story?
  end

  private

  def normalize_project_story(value)
    attrs =
      case value
      when ActionController::Parameters
        value.to_unsafe_h
      when Hash
        value.stringify_keys
      else
        {}
      end

    existing = read_attribute(:project_story).presence || {}
    normalized = self.class.default_project_story.merge(existing.stringify_keys)

    attrs.each do |key, content|
      next unless STORY_FIELDS.include?(key.to_s)

      normalized[key.to_s] = content.to_s.strip
    end

    normalized
  end

  def validate_project_story_fields
    STORY_FIELDS.each do |field|
      content = project_story[field].to_s
      next if content.blank?
      next if content.length <= STORY_FIELD_MAX_LENGTH

      errors.add(:project_story, "#{field.humanize} is too long (maximum is #{STORY_FIELD_MAX_LENGTH} characters)")
    end
  end
end
