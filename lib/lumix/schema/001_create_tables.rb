class CreateTables < Sequel::Migration

  def up
    create_table :texts do
      primary_key :id
      String :digest
      String :text
      String :tagged
      String :filename
      String :tagged_filename

      index :digest
    end

    create_table :assoc do
      primary_key :id
      Integer :text_id, :references => :texts
      Integer :position
      Integer :src_begin
      Integer :src_end
      Integer :tagged_begin
      Integer :tagged_end

      index [:text_id, :tagged_end]
      index [:text_id, :tagged_begin]
      index [:text_id, :position]
    end
  end

  def down
    drop_table :assoc
    drop_table :texts
  end

end