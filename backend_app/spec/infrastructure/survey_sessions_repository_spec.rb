# frozen_string_literal: true

require_relative '../spec_helper'

describe 'SurveySessions#persist_condition' do
  before do
    @repo = SurveyTracker::Database::Repository::SurveySessions.new
  end

  it 'stores and claims a condition for a brand-new respondent' do
    condition, mine = @repo.persist_condition(respondent_id: 'p_new', condition: 'wEO-wRAM')

    _(condition).must_equal 'wEO-wRAM'
    _(mine).must_equal true
    _(SurveyTracker::Database::Orm::SurveySession.first(respondent_id: 'p_new').condition).must_equal 'wEO-wRAM'
  end

  it 'attaches a condition to a session row that has none yet, and claims it' do
    SurveyTracker::Database::Orm::SurveySession.create(respondent_id: 'p_bare', started_at: Time.now.utc)

    condition, mine = @repo.persist_condition(respondent_id: 'p_bare', condition: 'wEO-wRAM')

    _(condition).must_equal 'wEO-wRAM'
    _(mine).must_equal true
  end

  it 'yields to an already-assigned condition and does NOT claim (caller releases its ticket)' do
    SurveyTracker::Database::Orm::SurveySession.create(
      respondent_id: 'p_has', condition: 'woEO-woRAM', started_at: Time.now.utc
    )

    condition, mine = @repo.persist_condition(respondent_id: 'p_has', condition: 'wEO-wRAM')

    _(condition).must_equal 'woEO-woRAM' # existing assignment wins
    _(mine).must_equal false             # so the drawn 'wEO-wRAM' ticket is released
  end
end
