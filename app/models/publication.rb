class Publication < ActiveRecord::Base
  has_and_belongs_to_many :flow_lanes, :join_table => :publication_lanes
  has_and_belongs_to_many :researchers, :join_table => :publication_authors
end
  