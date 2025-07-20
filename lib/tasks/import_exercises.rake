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
          # Use TRUNCATE to delete all records AND reset the primary key sequence
          ActiveRecord::Base.connection.execute("TRUNCATE TABLE exercises RESTART IDENTITY CASCADE")
          puts "Deleted existing exercises from database and reset ID sequence"

          exercises_data.each do |exercise_data|
            begin
              exercise = Exercise.find_or_initialize_by(name: exercise_data["name"])

              # Transformamos los nombres de imágenes a URLs completas
              full_image_urls = (exercise_data["images"] || []).map do |image|
                "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/#{image}"
              end
              
              exercise.assign_attributes(
                level: exercise_data["level"],
                instructions: exercise_data["instructions"] || [],
                primary_muscles: exercise_data["primaryMuscles"] || [],
                images: full_image_urls
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
