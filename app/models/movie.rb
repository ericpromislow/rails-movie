class Movie < ActiveRecord::Base
  serialize :runtime
  serialize :genres
  serialize :language
  serialize :writers
  serialize :directors
  serialize :actors
  serialize :country
  serialize :also_known_as
  serialize :episodes

  include Tire::Model::Search
  include Tire::Model::Callbacks

  def self.search(params)
    tire.search(load: true) do
      query { string params[:query], default_operator: "AND" } if params[:query].present?
    end
  end

  def self.create_from_title(intitle)
    url = "http://imdbapi.org/?q=#{intitle}"
    content, redirect_url, headers  = CachedWeb.get(:url=>url)
    ret = JSON.parse(content)
    if m = ret.first and (not ret.is_a?(Hash))
      puts "Create movie: #{m}"
      if movie = Movie.find_by_title(m['title'].to_s)
        return movie
      else
        @movie = Movie.new(m)
        return @movie
      end
    end
    return nil
  end
end
