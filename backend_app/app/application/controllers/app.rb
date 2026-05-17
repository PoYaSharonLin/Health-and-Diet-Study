# frozen_string_literal: true

require 'roda'
require 'json'
require_relative '../../infrastructure/database/orm/survey_session'
require_relative './routes/survey'
require_relative './routes/behavior'
require_relative './routes/assignment'
require 'rack/ssl-enforcer'

module SurveyTracker
  class Api < Roda # rubocop:disable Style/Documentation
    plugin :render
    plugin :public, root: 'dist'
    plugin :all_verbs
    plugin :halt
    plugin :multi_route

    if ENV['RACK_ENV'] == 'production'
      use Rack::SslEnforcer, hsts: true
    end

    plugin :error_handler do |e|
      case e
      when Sequel::NoMatchingRow
        response.status = 404
        { error: 'Not Found' }.to_json
      else
        response.status = 500
        { error: 'Internal Server Error', details: e.message }.to_json
      end
    end

    route do |r|
      r.public

      r.on 'api' do
        # Survey session management: POST/GET /api/survey/session(/:respondent_id)
        r.on 'survey' do
          r.run Routes::Survey
        end

        # Behavior event ingestion: POST /api/behavior/:respondent_id/events
        r.on 'behavior' do
          r.run Routes::Behavior
        end

        # Condition assignment: POST /api/assignment/next
        r.on 'assignment' do
          r.run Routes::Assignment
        end

        r.get do
          response['Content-Type'] = 'application/json'
          { success: true, message: 'Welcome to the Survey Tracker API' }.to_json
        end
      end

      # Serve the Vue SPA for all non-API routes
      r.root do
        File.read(File.join('dist', 'index.html'))
      end

      r.get [String, true], [String, true], [String, true], [true] do
        File.read(File.join('dist', 'index.html'))
      end
    end
  end
end
