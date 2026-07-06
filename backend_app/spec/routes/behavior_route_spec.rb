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

    it 'rejects a respondent_id with disallowed characters (400) before any work' do
      header 'CONTENT_TYPE', 'application/json'
      post '/api/behavior/bad.id/confirm-upload',
           { key: 'behavior_data/whatever.bin' }.to_json

      _(last_response.status).must_equal 400
    end

    it 'rejects a key that belongs to a different respondent (IDOR) and stores nothing' do
      SurveyTracker::Database::Orm::SurveySession.create(
        respondent_id: 'attacker', condition: 'wEO-wRAM', started_at: Time.now.utc
      )

      header 'CONTENT_TYPE', 'application/json'
      post '/api/behavior/attacker/confirm-upload',
           { key: 'behavior_data/victim_1712345678.bin' }.to_json

      _(last_response.status).must_equal 400
      _(SurveyTracker::Database::Orm::SurveySession.first(respondent_id: 'attacker').s3_key).must_be_nil
    end

    it 'rejects a key from a shorter respondent_id that prefixes a longer one' do
      SurveyTracker::Database::Orm::SurveySession.create(
        respondent_id: 'user', condition: 'wEO-wRAM', started_at: Time.now.utc
      )

      header 'CONTENT_TYPE', 'application/json'
      # 'user' must not be able to claim 'user_001's key
      post '/api/behavior/user/confirm-upload',
           { key: 'behavior_data/user_001_5.bin' }.to_json

      _(last_response.status).must_equal 400
    end
  end

  describe 'GET /api/behavior/:respondent_id/presigned-url' do
    it 'rejects a bad respondent_id (400) without building an S3 key' do
      # A valid id here would attempt a live S3 presign; the guard must reject
      # this id first, so the test needs no S3 stub.
      get '/api/behavior/bad.id/presigned-url'

      _(last_response.status).must_equal 400
    end
  end
end
