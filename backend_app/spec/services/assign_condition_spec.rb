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

    # Idempotent: a second call returns the same condition.
    again = SurveyTracker::Service::Assignments::AssignCondition.new.call(respondent_id: 'fallback_user')
    _(again.value!.message[:condition]).must_equal condition
  end
end
