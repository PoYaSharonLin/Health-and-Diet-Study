# frozen_string_literal: true

module SurveyTracker
  module Service
    module Assignments
      # Assigns a study condition to a respondent by drawing a ticket from the
      # Redis-backed AssignmentQueue, so group balance tracks completions:
      # tickets of dropouts are recycled by the lazy sweep at each draw.
      # Falls back to a least-count rule over survey_sessions when the queue
      # is unconfigured, empty, or unreachable. The choice is persisted on a
      # new or existing survey_sessions row so subsequent calls with the same
      # respondent_id return the same condition (idempotent).
      class AssignCondition < ApplicationOperation
        VALID_CONDITIONS = %w[woEO-woRAM wEO-woRAM woEO-wRAM wEO-wRAM].freeze

        def initialize(queue: Infrastructure::AssignmentQueue.new)
          @queue = queue
        end

        def call(respondent_id:)
          return Failure(bad_request('respondent_id is required')) if respondent_id.nil? || respondent_id.strip.empty?
          return Failure(bad_request('respondent_id has an invalid format')) unless Domain::Shared::RespondentId.valid?(respondent_id)

          repository = Database::Repository::SurveySessions.new
          condition = repository.find_by_respondent_id(respondent_id)&.condition
          condition ||= draw_from_queue(repository, respondent_id)
          condition ||= repository.find_or_assign_condition(
            respondent_id:,
            valid_conditions: VALID_CONDITIONS
          )

          Success(ok({ respondent_id:, condition: }))
        rescue StandardError => e
          Failure(internal_error(e.message))
        end

        private

        # Returns nil when the queue is unconfigured, empty, or unreachable,
        # so the caller falls back to least-count assignment.
        def draw_from_queue(repository, respondent_id)
          return nil unless @queue.configured?

          @queue.sweep_expired!
          ticket = @queue.draw(respondent_id)
          return nil unless ticket

          condition, mine = repository.persist_condition(respondent_id:, condition: ticket)
          @queue.release(respondent_id, ticket) unless mine
          condition
        rescue Redis::BaseError
          nil
        end
      end
    end
  end
end
