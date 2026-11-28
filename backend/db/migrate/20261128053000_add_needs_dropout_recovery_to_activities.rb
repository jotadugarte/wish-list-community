# frozen_string_literal: true

class AddNeedsDropoutRecoveryToActivities < ActiveRecord::Migration[8.1]
  def change
    add_column :activities, :needs_dropout_recovery, :boolean, null: false, default: false
  end
end
