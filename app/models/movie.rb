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
end
