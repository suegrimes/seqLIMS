class CreateLibSamples < ActiveRecord::Migration
  def self.up
    create_table :lib_samples do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :lib_samples
  end
end
