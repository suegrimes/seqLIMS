# == Schema Information
#
# Table name: pools
#
#  id                  :integer(4)      not null, primary key
#  pool_name           :string(35)      default(""), not null
#  tube_label          :string(15)      default(""), not null
#  pool_description    :string(80)
#  from_pools          :string(100)
#  from_plates         :string(100)
#  total_oligos        :integer(4)      default(0), not null
#  cherrypick_oligos   :integer(4)      default(0), not null
#  enzyme_code         :string(50)
#  source_conc_um      :decimal(8, 3)
#  pool_volume         :decimal(8, 3)
#  project_id          :integer(2)
#  storage_location_id :integer(2)
#  notes               :string(255)
#  updated_at          :timestamp
#

class Pool < InventoryDB
  has_and_belongs_to_many :primers
  validates_presence_of :primer_name
  validates_uniqueness_of :primer_name
  
  USING_POOLS = (self.find(:first).total_oligos == 0 && self.find(:all).size == 1 ? nil : 'yes')
  
  HUMAN_ATTRIBUTE_NAMES = {
    :pool_name => [POOL_TYPE, ' Pool'].join,
    :gene_code => 'Gene'
  }

  class << self
    def human_attribute_name attribute_name
      HUMAN_ATTRIBUTE_NAMES[attribute_name.to_sym] || super
    end
  end
 
  def pool_string
    return [tube_label, pool_name].join('/')
  end
  
  def self.get_pool_name(id=nil)
    pool = self.find(id) if !id.nil?
    return (pool.nil? ? '' : pool.pool_name)
  end
  
  def self.get_pool_label(id=nil)
    pool = self.find(id) if !id.nil?
    return (pool.nil? ? '' : pool.tube_label)
  end
  
  def self.populate_dropdown(lib_or_flowcell='lib')
    like_or_not = (lib_or_flowcell == 'lib' ? 'NOT LIKE' : 'LIKE')
    return self.find(:all, :order => "tube_label", :conditions => "tube_label #{like_or_not} 'OS%'")
  end

end
