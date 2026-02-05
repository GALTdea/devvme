# frozen_string_literal: true

class AddUniqueIndexToSolidCableMessagesId < ActiveRecord::Migration[7.1]
  def change
    # Rails insert_all/upsert path looks up unique indexes; add explicit unique index
    # on id so "No unique index found for id" is resolved when Solid Cable publishes.
    add_index :solid_cable_messages, :id, unique: true, if_not_exists: true
  end
end
