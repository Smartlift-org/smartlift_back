class EnablePgTrgmExtension < ActiveRecord::Migration[7.1]
  def change
    # Enable the pg_trgm extension for fuzzy string matching
    enable_extension 'pg_trgm'
  end
end