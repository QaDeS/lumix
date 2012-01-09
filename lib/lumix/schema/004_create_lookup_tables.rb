class CreateLookupTables < Sequel::Migration

  def up
    create_table :tags do
      primary_key :id
      String :tag

      index :tag, :unique => true
    end

    create_table :words do
      primary_key :id
      String :word

      index :word, :unique => true
    end

    create_table :tokens do
      primary_key :id
      Integer :text_id, :references => :texts

      Integer :position
      Integer :tag_id, :references => :tags
      Integer :word_id, :references => :words

      Integer :src_begin
      Integer :src_end
      Integer :tagged_begin
      Integer :tagged_end

      index [:text_id, :position], :unique => true
      index :word_id
      index :tag_id
    end

  end

  def down
    drop_table :tokens
    drop_table :words
    drop_table :tags
  end

end