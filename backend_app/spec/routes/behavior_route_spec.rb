# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Behavior Routes' do
  describe 'POST /api/behavior/:respondent_id/confirm-upload' do
    it 'stores the S3 key and marks the session completed' do
      # A condition is set so the burn path runs; with no REDIS_URL configured
      # in the test environment the ticket burn is a safe no-op.
      SurveyTracker::Database::Orm::SurveySession.create(
        respondent_id: 'confirm_user',
        condition: 'wEO-wRAM',
        started_at: Time.now.utc
      )

      header 'CONTENT_TYPE', 'application/json'
      post '/api/behavior/confirm_user/confirm-upload',
           { key: 'behavior_data/confirm_user_1712345678.bin' }.to_json

      _(last_response.status).must_equal 200
      _(json_response[:success]).must_equal true

      session = SurveyTracker::Database::Orm::SurveySession.first(respondent_id: 'confirm_user')
      _(session.s3_key).must_equal 'behavior_data/confirm_user_1712345678.bin'
      _(session.status).must_equal 'completed'
    end

    it 'returns 400 when key is missing' do
      header 'CONTENT_TYPE', 'application/json'
      post '/api/behavior/whoever/confirm-upload', {}.to_json

      _(last_response.status).must_equal 400
    end

    it 'returns 404 when the session does not exist' do
      header 'CONTENT_TYPE', 'application/json'
      post '/api/behavior/ghost/confirm-upload',
           { key: 'behavior_data/ghost_1.bin' }.to_json

      _(last_response.status).must_equal 404
    end
  end
end
