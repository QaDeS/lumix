class AddFulltagged < Sequel::Migration

  def up
    alter_table :texts do
      add_column :fulltagged, String
    end
  end

  def down
    alter_table :texts do
      drop_column :fulltagged
    end
  end

end