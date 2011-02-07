class CreateAlignmentRefs < ActiveRecord::Migration
  def self.up
    create_table :alignment_refs do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :alignment_refs
  end
end
