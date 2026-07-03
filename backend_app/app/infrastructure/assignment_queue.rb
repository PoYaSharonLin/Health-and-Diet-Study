# frozen_string_literal: true

require 'redis'

module SurveyTracker
  module Infrastructure
    # Redis-backed ticket queue for condition assignment.
    #
    #   assignment:available  LIST — condition tickets waiting to be drawn
    #   assignment:inflight   ZSET — drawn tickets, member "respondent_id|condition",
    #                                score = completion deadline (unix seconds)
    #
    # A ticket is drawn at assignment, burned at completion, and recycled back
    # to the pool by sweep_expired! if the deadline passes first — so group
    # balance tracks completions rather than assignments.
    class AssignmentQueue
      AVAILABLE_KEY = 'assignment:available'
      INFLIGHT_KEY  = 'assignment:inflight'
      DEFAULT_DEADLINE_SECONDS = 7200

      def initialize(redis: nil)
        @config = SurveyTracker::Api.config
        @injected = !redis.nil?
        @redis = redis || Redis.new(url: @config.REDIS_URL)
      end

      # False when no REDIS_URL is set — callers fall back to DB-only assignment.
      def configured?
        @injected || !@config.REDIS_URL.to_s.strip.empty?
      end

      def deadline_seconds
        (@config.ASSIGNMENT_DEADLINE_SECONDS || DEFAULT_DEADLINE_SECONDS).to_i
      end

      # Refill the pool with n_blocks shuffled blocks (each block = every
      # condition once), so any prefix of the pool is near-balanced.
      def seed(conditions, n_blocks)
        n_blocks.times { conditions.shuffle.each { |c| push_available(c) } }
      end

      # Append a single available ticket. Primitive shared by seed and the
      # reconcile rake task, which needs to add uneven per-condition counts.
      def push_available(condition)
        @redis.rpush(AVAILABLE_KEY, condition)
        condition
      end

      # Recycle inflight tickets whose completion deadline has passed.
      # Returns the number of tickets recycled.
      def sweep_expired!(now: Time.now)
        return 0 unless configured?

        expired = @redis.zrangebyscore(INFLIGHT_KEY, 0, now.to_i)
        expired.count do |entry|
          condition = entry.split('|', 2).last
          # ZREM guards the RPUSH so two concurrent sweeps can't recycle one ticket twice
          @redis.zrem(INFLIGHT_KEY, entry) && @redis.rpush(AVAILABLE_KEY, condition)
        end
      end

      # Draw a ticket for respondent_id. Returns the condition, or nil when the
      # pool is empty or the queue is not configured.
      def draw(respondent_id, now: Time.now)
        return nil unless configured?

        condition = @redis.lpop(AVAILABLE_KEY)
        return nil unless condition

        @redis.zadd(INFLIGHT_KEY, now.to_i + deadline_seconds, member(respondent_id, condition))
        condition
      end

      # Burn the ticket permanently (survey completed).
      def burn(respondent_id, condition)
        return false unless configured?

        @redis.zrem(INFLIGHT_KEY, member(respondent_id, condition))
      end

      # Put a drawn ticket straight back into the pool (e.g. after losing a
      # same-respondent insert race).
      def release(respondent_id, condition)
        return false unless configured?

        @redis.zrem(INFLIGHT_KEY, member(respondent_id, condition)) &&
          @redis.rpush(AVAILABLE_KEY, condition)
      end

      # Re-register an inflight ticket with an explicit deadline (reconcile path).
      def restore_inflight(respondent_id, condition, deadline:)
        @redis.zadd(INFLIGHT_KEY, deadline.to_i, member(respondent_id, condition))
      end

      # Wipe both keys before a rebuild (rake assignment:reconcile).
      def clear!
        @redis.del(AVAILABLE_KEY, INFLIGHT_KEY)
      end

      # => { available: { condition => count }, inflight: { condition => count } }
      def counts
        {
          available: @redis.lrange(AVAILABLE_KEY, 0, -1).tally,
          inflight:  @redis.zrange(INFLIGHT_KEY, 0, -1).map { |m| m.split('|', 2).last }.tally
        }
      end

      private

      def member(respondent_id, condition) = "#{respondent_id}|#{condition}"
    end
  end
end
