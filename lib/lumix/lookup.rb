require 'java_inline'

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
        word_id = @words[word]
        tag_id = @tags[tag]
        return if ENV['OMIT_TOKENS']
        @tokens << {:text_id => text_id, :position => position, :word_id => word_id, :tag_id => tag_id,
          :src_begin => s_begin, :src_end => s_end, :tagged_begin => t_begin, :tagged_end => t_end}
      end

      def flush
        tokens, @tokens = @tokens, [] # make sure no double-flush occurs
        @tokens_ds.multi_insert tokens
      end
    end

    class LookupCollection < Array
      def initialize(ds, column)
        @ds = ds
        @column = column
        super(){ |h,k| h[k] = create(k) }

        @ds.each do |e|
          self[e[:id]] = hashcode(e[@column])
        end
      end

      def [](value)
        h = hashcode(value)
        index(h) || index(self[create(value)] = h)
      end

      def create(value)
        @ds.db.transaction(:isolation => :serializable) do
          @ds.where(@column => value).select(:id).single_value || @ds.insert(@column => value)
        end
      end

      # hashing method tested to produce 0 collisions on the given set
      inline :Java do |builder|
        builder.package "org.mkit.test"
        builder.java "
        public static long hashcode(String s) {
          byte[] str = s.getBytes();
          long hash = 0;
          for(byte b : str) {
            hash = b + ( hash << 6 ) + ( hash << 16 ) - hash;
          }
          return hash;
        }"
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
    def find(filters, &block)
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
        g = {}
        g[:"#{as}__word_id"] = f.ex_word if f.ex_word
        g[:"#{as}__tag_id"] = f.ex_tag if f.ex_tag
        ds = ds.join(:tokens.as(as)){ |j, lj, js| {:text_id.qualify(j) => :text_id.qualify(lj), :position.qualify(j) => :position.qualify(lj) + 1} }.where(h).exclude(g)
      end
      select = ds.select(:t0__text_id.as(:text_id), :t0__src_begin.as(:src_begin), :"t#{i}__src_end".as(:src_end),
        :t0__tagged_begin.as(:tagged_begin), :"t#{i}__tagged_end".as(:tagged_end), :t0__position.as(:pos_begin), :"t#{i}__position".as(:pos_end))

      puts select.sql
      puts select.explain

      select.to_enum.each do |e|
        block.call [e[:text_id], e[:src_begin], e[:src_end], e[:tagged_begin], e[:tagged_end], e[:pos_begin], e[:pos_end]]
      end
    end

    def get_range(text_id, pos_begin, pos_end)
      db[:tokens].where(:text_id => text_id){ (:position >= pos_begin) & (:position <= pos_end) }.order_by(:position).select(:position, :tag_id, :word_id)
    end

    def get_tagged(text_id, pos_begin, pos_end)
      get_range(text_id, pos_begin, pos_end).
        join(:words, :id => :tokens__word_id).join(:tags, :id => :tokens__tag_id).select(:tag, :word)
    end

    def reconstruct_tagged(text_id, pos_begin, pos_end)
      get_tagged(text_id, pos_begin, pos_end).
        map{ |e| "#{e[:word]}|#{e[:tag]}" }.join(" ")
    end

    private
    def find_ids(tbl, opts)
      tbl.where(opts).select(:id)#.map{|e| e[:id]}
    end
    
  end
end
