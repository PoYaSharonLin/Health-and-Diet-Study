# frozen_string_literal: true

require_relative '../spec_helper'
require 'mock_redis'

describe 'AssignmentQueue' do
  CONDITIONS = %w[woEO-woRAM wEO-woRAM woEO-wRAM wEO-wRAM].freeze
  T0 = Time.utc(2026, 7, 1, 12, 0, 0)

  before do
    @queue = SurveyTracker::Infrastructure::AssignmentQueue.new(redis: MockRedis.new)
  end

  describe 'seed' do
    it 'fills the pool with balanced blocks' do
      @queue.seed(CONDITIONS, 3)

      available = @queue.counts[:available]
      _(available.values.sum).must_equal 12
      CONDITIONS.each { |cond| _(available[cond]).must_equal 3 }
    end
  end

  describe 'push_available' do
    it 'appends a single drawable ticket to the pool' do
      @queue.push_available(CONDITIONS.first)
      @queue.push_available(CONDITIONS.first)

      _(@queue.counts[:available]).must_equal(CONDITIONS.first => 2)
      _(@queue.draw('resp-1', now: T0)).must_equal CONDITIONS.first
    end
  end

  describe 'draw' do
    it 'pops a seeded ticket and tracks it inflight' do
      @queue.seed(CONDITIONS, 1)

      condition = @queue.draw('resp-1', now: T0)

      _(CONDITIONS).must_include condition
      _(@queue.counts[:available].values.sum).must_equal 3
      _(@queue.counts[:inflight]).must_equal(condition => 1)
    end

    it 'returns nil when the pool is empty' do
      _(@queue.draw('resp-1', now: T0)).must_be_nil
    end
  end

  describe 'member parsing (defense in depth)' do
    # Boundary validation should keep '|' out of respondent_id, but the queue
    # must still recover the condition correctly if a delimiter ever slips in.
    it 'recovers the condition when respondent_id contains the delimiter' do
      @queue.push_available(CONDITIONS.first)
      drawn = @queue.draw('a|b|c', now: T0)

      _(drawn).must_equal CONDITIONS.first
      _(@queue.counts[:inflight]).must_equal(CONDITIONS.first => 1)

      recycled = @queue.sweep_expired!(now: T0 + @queue.deadline_seconds + 1)
      _(recycled).must_equal 1
      _(@queue.counts[:available][CONDITIONS.first]).must_equal 1
    end
  end

  describe 'sweep_expired!' do
    it 'recycles only tickets past their deadline' do
      @queue.seed(CONDITIONS, 1)
      early = @queue.draw('resp-early', now: T0)
      late  = @queue.draw('resp-late',  now: T0 + 3600)

      recycled = @queue.sweep_expired!(now: T0 + @queue.deadline_seconds + 1)

      _(recycled).must_equal 1
      _(@queue.counts[:inflight]).must_equal(late => 1)
      _(@queue.counts[:available][early]).must_be :>=, 1
    end

    it 'recycles nothing before any deadline' do
      @queue.seed(CONDITIONS, 1)
      @queue.draw('resp-1', now: T0)

      _(@queue.sweep_expired!(now: T0 + 60)).must_equal 0
    end
  end

  describe 'burn' do
    it 'consumes the ticket so a later sweep cannot recycle it' do
      @queue.seed(CONDITIONS, 1)
      condition = @queue.draw('resp-1', now: T0)

      _(@queue.burn('resp-1', condition)).must_equal true

      recycled = @queue.sweep_expired!(now: T0 + @queue.deadline_seconds + 1)
      _(recycled).must_equal 0
      _(@queue.counts[:available].values.sum).must_equal 3
    end
  end

  describe 'release' do
    it 'returns a drawn ticket straight to the pool' do
      @queue.seed(CONDITIONS, 1)
      condition = @queue.draw('resp-1', now: T0)

      @queue.release('resp-1', condition)

      _(@queue.counts[:inflight]).must_equal({})
      _(@queue.counts[:available].values.sum).must_equal 4
    end
  end

  describe 'clear! and restore_inflight' do
    it 'supports a full rebuild of queue state' do
      @queue.seed(CONDITIONS, 2)
      @queue.draw('resp-1', now: T0)
      @queue.clear!

      _(@queue.counts).must_equal(available: {}, inflight: {})

      @queue.restore_inflight('resp-1', CONDITIONS.first, deadline: T0 + 100)
      _(@queue.counts[:inflight]).must_equal(CONDITIONS.first => 1)

      recycled = @queue.sweep_expired!(now: T0 + 101)
      _(recycled).must_equal 1
    end
  end
end
