# frozen_string_literal: true

class ArchitectSessionPolicy < ApplicationPolicy
  # Only the session owner can access their Career Architect sessions.

  def create?
    user.present?
  end

  def show?
    owner?
  end

  def message?
    owner?
  end

  def accept?
    owner?
  end

  def destroy?
    owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user.present?

      scope.where(user: user)
    end
  end

  private

  def owner?
    user.present? && record.user_id == user.id
  end
end
