# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Survey Routes' do
  it 'should create a new session' do
    payload = {
      respondent_id: 'test_user_001',
      original_url: 'http://example.com/survey?uid=test_user_001',
      metadata: { referrer: 'direct' }
    }

    header 'CONTENT_TYPE', 'application/json'
    post '/api/survey/session', payload.to_json

    _(last_response.status).must_equal 201
    _(json_response[:success]).must_equal true
    _(json_response[:data][:respondent_id]).must_equal 'test_user_001'
    _(json_response[:data][:share_url]).must_match(/uid=test_user_001/)
  end

  it 'should retrieve an existing session' do
    # First create it
    SurveyTracker::Database::Orm::SurveySession.create(
      respondent_id: 'existing_user',
      started_at: Time.now.utc
    )

    get '/api/survey/session/existing_user'

    _(last_response.status).must_equal 200
    _(json_response[:success]).must_equal true
    _(json_response[:data][:respondent_id]).must_equal 'existing_user'
  end

  it 'should return 404 for non-existent session' do
    get '/api/survey/session/non_existent'
    _(last_response.status).must_equal 404
  end

  it 'should reject a create with a malformed respondent_id' do
    header 'CONTENT_TYPE', 'application/json'
    post '/api/survey/session', { respondent_id: 'a/../b' }.to_json

    _(last_response.status).must_equal 400
  end
end
