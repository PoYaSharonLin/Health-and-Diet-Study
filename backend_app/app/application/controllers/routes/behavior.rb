# frozen_string_literal: true

require 'json'
require 'dry/monads'

module SurveyTracker
  module Routes
    # Behavior data routes:
    #   GET  /api/behavior/:respondent_id/presigned-url   → get a presigned PUT URL for direct S3 upload
    #   POST /api/behavior/:respondent_id/confirm-upload  → save the S3 key and mark session completed
    #   GET  /api/behavior/:respondent_id/download-url    → get a presigned GET URL for downloading the object
    class Behavior < Roda
      include Dry::Monads[:result]

      plugin :all_verbs
      plugin :request_headers

      route do |r|
        response['Content-Type'] = 'application/json'

        r.on String do |respondent_id|
          # Reject untrusted ids before they reach an S3 key or the queue.
          unless Domain::Shared::RespondentId.valid?(respondent_id)
            response.status = 400
            next({ error: 'invalid respondent_id' }.to_json)
          end

          # GET /api/behavior/:respondent_id/presigned-url
          # Returns a short-lived (10 min) presigned PUT URL for the frontend to upload
          # the binary blob directly to S3. Generate this only at submit time.
          r.on 'presigned-url' do
            r.get do
              result = Infrastructure::S3Service.new.presign_upload_url(respondent_id)

              if result[:success]
                response.status = 200
                { url: result[:url], key: result[:key], expires_at: result[:expires_at] }.to_json
              else
                response.status = 502
                { success: false, error: result[:error] }.to_json
              end
            end
          end

          # POST /api/behavior/:respondent_id/confirm-upload
          # Body: { "key": "behavior_data/abc123_1712345678.bin" }
          # Called by the frontend after the S3 PUT succeeds. Persists the S3 key
          # and marks the session as completed.
          r.on 'confirm-upload' do
            r.post do
              body = JSON.parse(r.body.read, symbolize_names: true)
              key  = body[:key]

              if key.nil? || key.strip.empty?
                response.status = 400
                next({ error: 'key is required' }.to_json)
              end

              # The key must be the exact object this respondent's presigned-url
              # minted for them (behavior_data/<respondent_id>_<unix>.bin), not an
              # arbitrary path. Otherwise a caller could store another user's key
              # and have download-url presign it (IDOR). The unix timestamp has no
              # underscore, so this also stops a shorter id matching a longer one.
              own_key = %r{\Abehavior_data/#{Regexp.escape(respondent_id)}_\d+\.bin\z}
              unless key.match?(own_key)
                response.status = 400
                next({ error: 'key does not belong to this respondent' }.to_json)
              end

              session = Database::Repository::SurveySessions.new.mark_completed(
                respondent_id:,
                s3_key: key
              )

              if session
                burn_assignment_ticket(respondent_id, session.condition)
                response.status = 200
                { success: true }.to_json
              else
                response.status = 404
                { success: false, error: 'session not found' }.to_json
              end
            rescue JSON::ParserError => e
              response.status = 400
              { error: 'Invalid JSON', details: e.message }.to_json
            end
          end

          # GET /api/behavior/:respondent_id/download-url
          # Looks up the stored S3 key for this user and returns a presigned GET URL
          # (valid 1 hour) so a researcher can download the object without AWS credentials.
          r.on 'download-url' do
            r.get do
              session = Database::Repository::SurveySessions.new.find_by_respondent_id(respondent_id)

              unless session
                response.status = 404
                next({ error: 'session not found' }.to_json)
              end

              unless session.s3_key
                response.status = 404
                next({ error: 'no upload on record for this user' }.to_json)
              end

              result = Infrastructure::S3Service.new.presign_download_url(session.s3_key)

              if result[:success]
                response.status = 200
                { url: result[:url], expires_at: result[:expires_at] }.to_json
              else
                response.status = 502
                { success: false, error: result[:error] }.to_json
              end
            end
          end

        end
      end

      private

      # Burn the respondent's assignment ticket once their upload is confirmed,
      # so the queue balances on completions rather than starts. No-op when the
      # queue is unconfigured or the condition came from the DB fallback; a Redis
      # outage must never fail an otherwise-successful completion.
      def burn_assignment_ticket(respondent_id, condition)
        return if condition.nil? || condition.to_s.strip.empty?

        Infrastructure::AssignmentQueue.new.burn(respondent_id, condition)
      rescue Redis::BaseError
        nil
      end
    end
  end
end
