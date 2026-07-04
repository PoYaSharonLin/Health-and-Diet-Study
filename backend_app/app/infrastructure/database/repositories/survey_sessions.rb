# frozen_string_literal: true

module SurveyTracker
  module Database
    module Repository
      # Repository for survey_sessions table
      class SurveySessions
        def find_by_respondent_id(respondent_id)
          Orm::SurveySession.first(respondent_id:)
        end

        # Idempotent: returns existing session if respondent_id already recorded.
        # Backfills original_url / metadata when the existing row has them blank
        # (e.g. when the row was pre-created by the condition assignment step).
        def find_or_create(respondent_id:, original_url: nil, metadata: nil)
          existing = find_by_respondent_id(respondent_id)
          if existing
            updates = {}
            updates[:original_url] = original_url if existing.original_url.nil? && original_url
            updates[:metadata]     = metadata     if existing.metadata.nil?     && metadata
            existing.update(updates) unless updates.empty?
            return existing
          end

          Orm::SurveySession.create(
            respondent_id:,
            original_url:,
            metadata:,
            started_at: Time.now.utc
          )
        end

        # Assigns the least-used condition among `valid_conditions` to
        # respondent_id, creating a session row if none exists. Idempotent:
        # if respondent_id already has a condition, returns it unchanged.
        # Wrapped in a transaction so concurrent assignments serialize and
        # cannot pick the same bucket from a stale count snapshot.
        def find_or_assign_condition(respondent_id:, valid_conditions:)
          Orm::SurveySession.db.transaction do
            existing = find_by_respondent_id(respondent_id)
            return existing.condition if existing&.condition

            counts = Orm::SurveySession
                     .where(condition: valid_conditions)
                     .group_and_count(:condition)
                     .to_hash(:condition, :count)

            min_count  = valid_conditions.map { |c| counts[c] || 0 }.min
            candidates = valid_conditions.select { |c| (counts[c] || 0) == min_count }
            chosen     = candidates.sample

            if existing
              existing.update(condition: chosen)
            else
              Orm::SurveySession.create(
                respondent_id: respondent_id,
                condition:     chosen,
                started_at:    Time.now.utc
              )
            end

            chosen
          end
        end

        # Persists a queue-drawn condition on the respondent's session unless one
        # is already set. Returns [condition, mine] where `mine` is true only when
        # THIS call stored `condition`; when it is false the caller must release
        # its drawn ticket. `condition` is the authoritative stored value (which
        # may differ from the ticket, or be nil if a session row exists without
        # one yet). A concurrent request that wins the unique-respondent_id race
        # is caught here, so a double-submit neither 500s nor leaks a ticket.
        def persist_condition(respondent_id:, condition:)
          Orm::SurveySession.db.transaction do
            existing = find_by_respondent_id(respondent_id)
            return [existing.condition, false] if existing&.condition

            if existing
              existing.update(condition:)
            else
              Orm::SurveySession.create(
                respondent_id:,
                condition:,
                started_at: Time.now.utc
              )
            end

            [condition, true]
          end
        rescue Sequel::UniqueConstraintViolation
          # A concurrent request created the row first; adopt whatever condition
          # it committed and let the caller release this call's redundant ticket.
          [find_by_respondent_id(respondent_id)&.condition, false]
        end

        def update_ended_at(respondent_id:)
          session = find_by_respondent_id(respondent_id)
          return nil unless session

          session.update(ended_at: Time.now.utc)
          session
        end

        # Called after a successful S3 upload — records the key and marks the session done.
        def mark_completed(respondent_id:, s3_key:)
          session = find_by_respondent_id(respondent_id)
          return nil unless session

          session.update(s3_key:, status: 'completed')
          session
        end

        def update_status(respondent_id:, status:)
          session = find_by_respondent_id(respondent_id)
          return nil unless session

          session.update(status:)
          session
        end
      end
    end
  end
end
