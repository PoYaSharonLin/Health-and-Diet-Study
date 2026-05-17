# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  up do
    unless schema(:survey_sessions).map(&:first).include?(:condition)
      add_column :survey_sessions, :condition, String
    end
    add_index :survey_sessions, :condition unless indexes(:survey_sessions).key?(:survey_sessions_condition_index)
  end

  down do
    drop_index :survey_sessions, :condition if indexes(:survey_sessions).key?(:survey_sessions_condition_index)
    drop_column :survey_sessions, :condition
  end
end
