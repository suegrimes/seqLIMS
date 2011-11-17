class InventoryDB < ActiveRecord::Base
  self.abstract_class = true
  establish_connection(:inventory) if RAILS_ENV != 'demo' 
end