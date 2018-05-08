# == Schema Information
#
# Table name: orders
#
#  id             :integer          not null, primary key
#  company_name   :string(50)
#  order_quote    :string(100)
#  date_ordered   :date
#  po_number      :string(20)
#  rpo_or_cwa     :string(6)
#  incl_chemicals :string(1)
#  order_received :string(1)
#  order_number   :string(20)
#  notes          :string(255)
#  created_at     :datetime
#  updated_at     :timestamp
#  updated_by     :integer
#

class Order < ActiveRecord::Base
  has_many :items, :dependent => :destroy
  accepts_nested_attributes_for :items
  
  #validates_presence_of :rpo_or_cwa, :company_name, :incl_chemicals, :po_number
  validates_presence_of :rpo_or_cwa, :company_name, :po_number
  validates_date :date_ordered
  
  after_update :upd_items_recvd
  after_update :save_items
  
  def received?
    order_received == 'y'
  end

  def requisition_nr
    return po_number
  end

  def has_comments?
    (notes.blank? ? false : true)
  end
  
  def enter_or_upd_by
    user = User.find_by_id(updated_by)
    return (user.nil? ? '[unknown]' : user.login)
  end
  
  def new_item_attributes=(item_attributes)
    item_attributes.each do |attributes|
      items.build(attributes)
    end
  end
  
  def existing_item_attributes=(item_attributes)
    items.reject(&:new_record?).each do |item|
      upd_attributes = item_attributes[item.id.to_s]
      if upd_attributes
        item.attributes = upd_attributes
      else
        items.delete(item)
      end
    end
  end
  
  def save_items
    items.each do |item|
      item.save(:validate=>false)
    end
  end
  
  def upd_items_recvd
    if (order_received == 'Y' || order_received == 'N')
      Item.upd_items_recvd_for_order(id, order_received)
    end
  end

  def self.find_for_query(condition_array)
    self.includes(:items).where(sql_where(condition_array)).order('date_ordered DESC').all
  end

end
