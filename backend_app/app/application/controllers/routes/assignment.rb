# frozen_string_literal: true

require 'json'
require 'dry/monads'

module SurveyTracker
  module Routes
    # Condition assignment:
    #   POST /api/assignment/next   { respondent_id } → { condition }
    class Assignment < Roda
      include Dry::Monads[:result]

      plugin :all_verbs

      route do |r|
        r.on 'next' do
          response['Content-Type'] = 'application/json'

          r.post do
            body = JSON.parse(r.body.read, symbolize_names: true)
            respondent_id = body[:respondent_id]

            case Service::Assignments::AssignCondition.new.call(respondent_id:)
            in Success(api_result)
              response.status = api_result.http_status_code
              { success: true, data: api_result.message }.to_json
            in Failure(api_result)
              response.status = api_result.http_status_code
              api_result.to_json
            end
          rescue JSON::ParserError => e
            response.status = 400
            { error: 'Invalid JSON', details: e.message }.to_json
          end
        end
      end
    end
  end
end
