namespace :imdb do

  desc "Populate the database from a directory"
  task :populate => :environment do

    dir_name = ENV['dirname']
    Dir.entries(dir_name).each do |name|
      if name.gsub(".","").present?
        title = name.split(".").first
        movie = Movie.create_from_title(title) rescue next
        if movie
          movie.local_path(File.join(dir_name, name))
          movie.save
        end
        sleep 5
      end
    end
  end
end
