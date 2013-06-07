namespace :imdb do

  desc "Populate the database from a directory"
  task :populate => :environment do

    dir_name = ENV['dirname']
    Dir.entries(dir_name).each do |name|
      if name.gsub(".","").present?
          title = name.split(".").first
          url = "http://imdbapi.org/?q=#{title}"
          content, redirect_url, headers  = CachedWeb.get(:url=>url) rescue next
          ret = JSON.parse(content)
          if m = ret.first and (not ret.is_a?(Hash))
            puts "Create movie: #{m}"
            unless Movie.find_by_title(m['title'].to_s)
              @movie = Movie.new(m)
              @movie.save
            end
          end

      end
    end
  end
end
