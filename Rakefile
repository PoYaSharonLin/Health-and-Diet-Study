# frozen_string_literal: true

require 'rake/testtask'
require_relative './require_app'

desc 'Run all tests'
Rake::TestTask.new(:spec) do |t|
  t.pattern = 'backend_app/spec/**/*_spec.rb'
  t.warning = false
end

desc 'Run all tests'
task test: :spec

task default: :spec

desc 'Setup project for first time (install dependencies, configure secrets)'
task :setup do
  puts '==> Installing backend dependencies...'
  sh 'bundle config set --local without production'
  sh 'bundle install'

  puts "\n==> Installing frontend dependencies..."
  sh 'npm install'

  # Setup backend secrets
  secrets_src = 'backend_app/config/secrets_example.yml'
  secrets_dst = 'backend_app/config/secrets.yml'
  unless File.exist?(secrets_dst)
    puts "\n==> Copying #{secrets_src} to #{secrets_dst}..."
    cp secrets_src, secrets_dst
  end

  # Setup frontend environment
  env_src = 'frontend_app/.env.local.example'
  env_dst = 'frontend_app/.env.local'
  unless File.exist?(env_dst)
    puts "\n==> Copying #{env_src} to #{env_dst}..."
    cp env_src, env_dst
  end

  puts "\n==> Setup complete! Next steps:"
  puts '    1. Setup databases:'
  puts '       bundle exec rake db:setup              # Development'
  puts '       RACK_ENV=test bundle exec rake db:setup # Test'
end

namespace :db do
  task :config do
    require('sequel')
    require_app('config')
  end

  desc 'Migrate the database to the latest version'
  task migrate: [:config] do
    Sequel.extension :migration

    migration_path = File.expand_path('backend_app/db/migrations', __dir__)

    Dir.glob("#{migration_path}/*.rb").each { |file| require file }
    Sequel::Migrator.run(SurveyTracker::Api.db, migration_path)
  end

  desc 'Delete dev or test database file'
  task drop: [:config] do
    @app = SurveyTracker::Api
    if @app.environment == :production
      puts 'Cannot wipe production database!'
      return
    end

    db_filename = "backend_app/db/store/#{@app.environment}.db"
    FileUtils.rm(db_filename) if File.exist?(db_filename)
    puts "Deleted #{db_filename}"
  end

  desc 'Setup database (migrate)'
  task setup: %i[migrate]

  desc 'Reset database (drop, migrate)'
  task reset: %i[drop migrate]
end

namespace :s3 do
  task :config do
    require_app('config')
    @bucket = SurveyTracker::Api.config.S3_BUCKET_NAME
  end

  desc 'Configure CORS on the S3 bucket (run once during setup)'
  task :configure_cors do
    require_app('infrastructure')
    origins = ENV.fetch('CORS_ORIGINS', 'http://localhost:8080').split(',').map(&:strip)
    puts "==> Configuring CORS on S3 bucket for origins: #{origins.inspect}"
    result = SurveyTracker::Infrastructure::S3Service.new.configure_bucket_cors(allowed_origins: origins)
    if result[:success]
      puts '==> CORS configured successfully.'
    else
      puts "==> CORS configuration failed: #{result[:error]}"
      exit 1
    end
  end

  desc 'List all uploaded session blobs in S3'
  task list: [:config] do
    sh "aws s3 ls s3://#{@bucket}/behavior_data/"
  end

  desc 'Sync all session blobs from S3 to a local directory (default ./data/)'
  task :sync, [:dest] => [:config] do |_t, args|
    dest = args[:dest] || './data/'
    sh "aws s3 sync s3://#{@bucket}/behavior_data/ #{dest}"
  end
end

namespace :run do
  desc 'Run backend API server for development'
  task :api do
    pid = `lsof -ti :9292`.strip
    unless pid.empty?
      puts "==> Killing process on port 9292 (PID #{pid})..."
      sh "kill -9 #{pid}"
    end
    sh 'puma config.ru -t 1:5 -p 9292'
  end

  desc 'Run frontend webpack dev server'
  task :frontend do
    pid = `lsof -ti :8080`.strip
    unless pid.empty?
      puts "==> Killing process on port 8080 (PID #{pid})..."
      sh "kill -9 #{pid}"
    end
    sh 'npm run dev'
  end
end
