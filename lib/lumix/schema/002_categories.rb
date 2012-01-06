class Categories < Sequel::Migration

  def up
    create_table :categories do
      primary_key :id
      Integer :parent_id, :references => :categories
      String :name
      String :key

      index [:parent_id, :id]
    end

    alter_table :texts do
      add_column :category_id, Integer, :references => :categories

      add_index [:category_id, :id]
    end

  end

  def down
    alter_table :texts do
      drop_column :category_id
    end
    drop_table :categories
  end

end