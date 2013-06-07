class CreateMovies < ActiveRecord::Migration
  def self.up
    create_table :movies do |t|
      t.string :title
      t.string :runtime
      t.string :genres
      t.string :language
      t.string :filming_locations
      t.string :poster
      t.string :imdb_url
      t.string :writers
      t.string :directors
      t.string :actors
      t.string :episodes
      t.text :plot_simple
      t.string :country
      t.string :type
      t.string :release_date
      t.string :also_known_as
      t.string :year
      t.string :rated
      t.string :imdb_id
      t.string :rating
      t.string :rating_count

      t.timestamps
    end
  end

  def self.down
    drop_table :movies
  end
end
