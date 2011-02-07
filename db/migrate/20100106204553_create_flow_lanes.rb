class CreateFlowLanes < ActiveRecord::Migration
  def self.up
    create_table :flow_lanes do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :flow_lanes
  end
end
