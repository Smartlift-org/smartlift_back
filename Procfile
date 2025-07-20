web: bundle exec puma -C config/puma.rb && bundle exec rails db:seed 
release: bundle exec rails db:migrate && bundle exec rails exercises:import 
