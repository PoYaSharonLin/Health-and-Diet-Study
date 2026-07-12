# frozen_string_literal: true

require_relative '../spec_helper'

describe 'AssignCondition' do
  include Dry::Monads[:result]

  it 'rejects a malformed respondent_id' do
    result = SurveyTracker::Service::Assignments::AssignCondition.new.call(respondent_id: 'a|b')

    _(result).must_be_kind_of Dry::Monads::Result::Failure
    _(result.failure.http_status_code).must_equal 400
  end

  it 'falls back to least-count assignment when the queue is unconfigured' do
    # No REDIS_URL in the test environment, so draw_from_queue returns nil and
    # the service assigns via the survey_sessions least-count rule.
    result = SurveyTracker::Service::Assignments::AssignCondition.new.call(respondent_id: 'fallback_user')

    _(result).must_be_kind_of Dry::Monads::Result::Success
    condition = result.value!.message[:condition]
    _(SurveyTracker::Service::Assignments::AssignCondition::VALID_CONDITIONS).must_include condition

    # A respondent still in progress is not flagged as completed.
    _(result.value!.message[:completed]).must_equal false

    # Idempotent: a second call returns the same condition.
    again = SurveyTracker::Service::Assignments::AssignCondition.new.call(respondent_id: 'fallback_user')
    _(again.value!.message[:condition]).must_equal condition
  end

  it 'flags a respondent whose session is already completed' do
    id = 'completed_user'
    SurveyTracker::Service::Assignments::AssignCondition.new.call(respondent_id: id)
    SurveyTracker::Database::Repository::SurveySessions.new.mark_completed(
      respondent_id: id, s3_key: "behavior_data/#{id}_1.bin"
    )

    result = SurveyTracker::Service::Assignments::AssignCondition.new.call(respondent_id: id)

    _(result).must_be_kind_of Dry::Monads::Result::Success
    _(result.value!.message[:completed]).must_equal true
  end
end
