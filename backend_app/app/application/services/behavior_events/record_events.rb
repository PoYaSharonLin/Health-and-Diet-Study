# frozen_string_literal: true

module SurveyTracker
  module Service
    module BehaviorEvents
      # Records one or many trajectories for a given respondent_id's session.
      class RecordEvents < ApplicationOperation

        VALID_EVENT_TYPES = %w[
          pointer-move pointer-down pointer-up pointer-over pointer-out
          key-down key-up highlight scroll slider-change
          focus blur visibility-change page-show page-hide
          viewport element-rect
        ].freeze

        def call(respondent_id:, events:)
          return Failure(bad_request('events must be an array')) unless events.is_a?(Array)
          return Failure(bad_request('events array is empty'))   if events.empty?

          session_record = Database::Repository::SurveySessions.new.find_by_respondent_id(respondent_id)
          return Failure(not_found("No session for respondent_id: #{respondent_id}")) unless session_record

          events.each do |evt|
            unless VALID_EVENT_TYPES.include?(evt[:type].to_s)
              return Failure(bad_request("Invalid event type: #{evt[:type]}"))
            end
          end

          Database::Repository::BehaviorEvents.new.create_batch(
            survey_session_id: session_record.id,
            events:
          )

          Success(created("#{events.size} event(s) recorded"))
        rescue StandardError => e
          Failure(internal_error(e.message))
        end
      end
    end
  end
end
