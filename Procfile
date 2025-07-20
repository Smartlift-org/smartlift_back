web: bundle exec puma -C config/puma.rb 
release: bundle exec rails db:migrate && bundle exec rails exercises:import && bundle exec rails db:seed 
