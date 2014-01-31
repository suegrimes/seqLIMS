# == Schema Information
#
# Table name: publications
#
#  id               :integer          not null, primary key
#  title_abbrev     :string(50)       default(""), not null
#  title_full       :string(255)
#  publication_name :string(50)       default(""), not null
#  date_published   :date
#  comments         :string(255)
#  created_at       :datetime
#  updated_at       :timestamp
#

class Publication < ActiveRecord::Base
  has_and_belongs_to_many :flow_lanes, :join_table => :publication_lanes
  has_and_belongs_to_many :researchers, :join_table => :publication_authors
end
  
