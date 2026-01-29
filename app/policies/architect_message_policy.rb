# frozen_string_literal: true

class ArchitectMessagePolicy < ApplicationPolicy
  # Access to messages is via session ownership: only the session owner can access.

  def show?
    session_owner?
  end

  def create?
    session_owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user.present?

      scope.joins(:architect_session).where(architect_sessions: { user_id: user.id })
    end
  end

  private

  def session_owner?
    user.present? && record.architect_session.user_id == user.id
  end
end
