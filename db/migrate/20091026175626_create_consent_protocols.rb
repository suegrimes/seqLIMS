class CreateConsentProtocols < ActiveRecord::Migration
  def self.up
    create_table :consent_protocols do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :consent_protocols
  end
end
