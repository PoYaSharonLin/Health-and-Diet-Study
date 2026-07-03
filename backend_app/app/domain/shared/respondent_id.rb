# frozen_string_literal: true

module SurveyTracker
  module Domain
    module Shared
      # respondent_id enters as an untrusted URL query param (?uid=...) and then
      # flows into Redis queue member keys, S3 object keys, and the share_url.
      # Restricting it to an allowlist at every entry point means no downstream
      # context has to escape delimiter / path / URL metacharacters.
      module RespondentId
        FORMAT = /\A[A-Za-z0-9_-]{1,64}\z/

        def self.valid?(value)
          value.is_a?(String) && value.match?(FORMAT)
        end
      end
    end
  end
end
