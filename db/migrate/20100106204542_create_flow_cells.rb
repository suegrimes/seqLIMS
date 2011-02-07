class CreateFlowCells < ActiveRecord::Migration
  def self.up
    create_table :flow_cells do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :flow_cells
  end
end
