# frozen_string_literal: true

module ProjectStoryBuilder
  class ApplyService
    class ApplyError < StandardError; end

    def self.call(project:, suggestions:, selections:)
      new.call(project:, suggestions:, selections:)
    end

    def call(project:, suggestions:, selections:)
      raise ApplyError, "Project is required" if project.blank?
      raise ApplyError, "No suggestions to apply" if suggestions.blank?

      suggested_fields = suggestions.fetch("fields", {})
      selected_fields = normalize_selections(selections)
      raise ApplyError, "Select at least one field to apply" if selected_fields.empty?

      updates = {}
      selected_fields.each do |field, mode|
        next unless ProjectStory::PUBLIC_STORY_FIELDS.include?(field)

        suggested_value = suggested_fields[field].to_s.strip
        next if suggested_value.blank?

        existing_value = project.project_story[field].to_s.strip
        next unless should_apply?(mode:, existing_value:)

        updates[field] = suggested_value
      end

      raise ApplyError, "No selected suggestions were eligible to apply" if updates.empty?

      merged_story = project.project_story.merge(updates)
      project.update!(project_story: merged_story)
      updates.keys
    end

    private

    def normalize_selections(selections)
      case selections
      when ActionController::Parameters
        selections.to_unsafe_h.stringify_keys
      when Hash
        selections.stringify_keys
      else
        {}
      end.select do |field, mode|
        ProjectStory::PUBLIC_STORY_FIELDS.include?(field.to_s) && mode.present?
      end.transform_keys(&:to_s)
    end

    def should_apply?(mode:, existing_value:)
      case mode.to_s
      when "replace"
        true
      when "blank_only"
        existing_value.blank?
      else
        false
      end
    end
  end
end
