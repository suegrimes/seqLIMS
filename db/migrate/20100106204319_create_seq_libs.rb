class CreateSeqLibs < ActiveRecord::Migration
  def self.up
    create_table :seq_libs do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :seq_libs
  end
end
