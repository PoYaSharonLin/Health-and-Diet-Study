# frozen_string_literal: true

module SurveyTracker
  module Service
    module Assignments
      # Assigns a study condition to a respondent using a least-count rule:
      # whichever condition currently has the fewest survey_sessions wins
      # (random tiebreak). The choice is persisted on a new or existing
      # survey_sessions row so subsequent calls with the same respondent_id
      # return the same condition (idempotent).
      class AssignCondition < ApplicationOperation
        VALID_CONDITIONS = %w[woEO-woRAM wEO-woRAM woEO-wRAM wEO-wRAM].freeze

        def call(respondent_id:)
          return Failure(bad_request('respondent_id is required')) if respondent_id.nil? || respondent_id.strip.empty?

          condition = Database::Repository::SurveySessions.new.find_or_assign_condition(
            respondent_id:,
            valid_conditions: VALID_CONDITIONS
          )

          Success(ok({ respondent_id:, condition: }))
        rescue StandardError => e
          Failure(internal_error(e.message))
        end
      end
    end
  end
end
