module Lumix

  class Lookup
    class Document
      def initialize(lookup)
        @tokens_ds = lookup.tokens
        @words = lookup.words
        @tags = lookup.tags
        @tokens = []
      end

      def add_token(text_id, position, word, tag, s_begin, s_end, t_begin, t_end)
        @tokens << {:text_id => text_id, :position => position, :word_id => @words[word], :tag_id => @tags[tag],
          :src_begin => s_begin, :src_end => s_end, :tagged_begin => t_begin, :tagged_end => t_end}
      end

      def flush
        tokens, @tokens = @tokens, [] # make sure no double-flush occurs
        @tokens_ds.multi_insert tokens
      end
    end

    class LookupCollection < Hash
      def initialize(ds, column)
        @ds = ds
        @column = column
        super(){ |h,k| h[k] = create(k) }

        @ds.each do |e|
          self[e[@column]] = e[:id]
        end
      end

      def create(value)
        @ds.db.transaction(:isolation => :serializable) do
          @ds.where(@column => value).select(:id).single_value || @ds.insert(@column => value)
        end
      end
    end

    attr_reader :tokens, :db

    def initialize(db)
      puts "Lookup"
      @db = db
      @tokens = db[:tokens]
    end

    def tags
      # TODO create only in the context of linking
      @tags ||= LookupCollection.new(db[:tags], :tag)
    end

    def words
      @words ||= LookupCollection.new(db[:words], :word)
    end

    def process(text_id)
      return true unless tokens.where(:text_id => text_id).empty?
      doc = Document.new(self)
      result = yield(doc) if block_given?
      doc.flush if result
      result
    end

    def find_word(re)
      find_ids(db[:words], :word => re)
    end

    def find_tag(re)
      find_ids(db[:tags], :tag => re)
    end

    # kindly crafted by jeremyevans
    def find(filters)
      ds = db[:tokens.as(:t0)]
      f = filters[0]
      ds = ds.where(:t0__word_id=>f.word) if f.word
      ds = ds.where(:t0__tag_id=>f.tag) if f.tag
      i = 0
      filters[1..-1].each do |f|
        as = "t#{i+=1}"
        h = {}
        h[:"#{as}__word_id"] = f.word if f.word
        h[:"#{as}__tag_id"] = f.tag if f.tag
        ds = ds.join(:tokens.as(as)){ |j, lj, js| {:text_id.qualify(j) => :text_id.qualify(lj), :position.qualify(j) => :position.qualify(lj) + 1} }.where(h)
      end
      select = ds.select(:t0__text_id.as(:text_id), :t0__src_begin.as(:src_begin), :"t#{i}__src_end".as(:src_end),
        :t0__tagged_begin.as(:tagged_begin), :"t#{i}__tagged_end".as(:tagged_end))

      puts select.sql
      puts select.explain

      select.each do |e|
        yield [e[:text_id], e[:src_begin], e[:src_end], e[:tagged_begin], e[:tagged_end]]
      end
    end

    private
    def find_ids(tbl, opts)
      tbl.where(opts).select(:id).map{|e| e[:id]}
    end
    
  end
end
