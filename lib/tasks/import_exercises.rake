namespace :exercises do
    desc "Import exercises from free-exercise-db repository"
    task import: :environment do
      require "net/http"
      require "json"

      puts "Starting exercise import..."

      url = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json"

      begin
        # Initialize counters
        imported = 0
        skipped = 0
        failed = 0

        uri = URI(url)
        request = Net::HTTP::Get.new(uri)
        request["User-Agent"] = "Ruby/Rails Exercise Importer"

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end

        unless response.is_a?(Net::HTTPSuccess)
          raise "Failed to fetch exercises: HTTP #{response.code} - #{response.message}"
        end

        exercises_data = JSON.parse(response.body)
        puts "Found #{exercises_data.size} exercises in JSON file"

        ActiveRecord::Base.transaction do
          Exercise.delete_all
          puts "Deleted existing exercises from database"

          exercises_data.each do |exercise_data|
            begin
              exercise = Exercise.find_or_initialize_by(name: exercise_data["name"])

              exercise.assign_attributes(
                force: exercise_data["force"],
                level: exercise_data["level"],
                mechanic: exercise_data["mechanic"],
                equipment: exercise_data["equipment"],
                instructions: exercise_data["instructions"] || [],
                primary_muscles: exercise_data["primaryMuscles"] || [],
                secondary_muscles: exercise_data["secondaryMuscles"] || [],
                category: exercise_data["category"],
                images: exercise_data["images"] || []
              )

              if exercise.save
                imported += 1
                print "." if imported % 10 == 0 # Progress indicator
              else
                skipped += 1
                puts "\nSkipped: #{exercise.name} - #{exercise.errors.full_messages.join(', ')}"
              end
            rescue => e
              failed += 1
              puts "\nError importing #{exercise_data['name']}: #{e.message}"
            end
          end
        end

        puts "\nImport completed: #{imported} imported, #{skipped} skipped, #{failed} failed"
      rescue => e
        puts "Import failed with error: #{e.message}"
        raise
      end
    end
  end
