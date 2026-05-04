# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  up do
    unless schema(:survey_sessions).map(&:first).include?(:status)
      add_column :survey_sessions, :status, String, default: 'in_progress'
    end

    # Backfill sessions that already have an s3_key — they are completed.
    run("UPDATE survey_sessions SET status = 'completed' WHERE s3_key IS NOT NULL")
  end

  down do
    drop_column :survey_sessions, :status
  end
end
