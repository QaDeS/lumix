module Lumix

  class SlowSearch
    TAGGED = /([^\s\|]+)\|(\S+)/m        # Xxx|YYY

    def initialize(db, progress)
      @db = db
      @progress = progress
    end

    def concurrent_link?
      true
    end

    def link_text(id)
      t = TaggedText[id]
      text = t.text
      puts "Linking text #{t.filename}"

      src_last = 0
      position = 0
      assoc = []
      t.tagged.scan(TAGGED) do |word, tag|
        tagged_begin = $~.begin(0)
        tagged_end = $~.end(0)

        word_re = Regexp.new(Regexp.escape(word).gsub(/_/, '\s*'))
        src_match = text[src_last..-1].match(word_re) # find the word
        if src_match
          src_begin = src_last + src_match.begin(0)
          src_end = src_last + src_match.end(0)

          src_last = src_end
          assoc << {:text_id => id, :position => position, :src_begin => src_begin, :src_end => src_end, :tagged_begin => tagged_begin, :tagged_end => tagged_end}
        else
          STDERR.puts "Could not find match for '#{word}' in text #{t.filename}"
          `echo '#{t.filename}:#{tagged_begin}:#{src_last} unmatched "#{word}"' >> unlinked.lst`
          return nil
        end
        position += 1
      end
      @db[:assoc].multi_insert(assoc)
    rescue => e
      STDERR.puts e
      STDERR.puts e.backtrace
      raise e
    end

    def create_filter
      @filter ||= Filter.new('')
    end

    def find(filter, &block)
      yield_text = block && block.arity >= 1
      yield_tagged = block && block.arity >= 2

      prog = Progress.new(:search, TaggedText.count, filter)
      @progress[prog]

      re = Filter.to_re(filter)

      index = 0
      TaggedText.inject(0) do |result, t|
        fname = File.basename(t.filename)

        # matches to ranges
        results = []
        t.tagged.scan(re) do |hit|
          t_begin = $~.begin(0)
          t_end = $~.end(0)
          # TODO decouple database operations for performance
          results << find_range(t.id, t_begin, t_end, yield_text)
        end

        result += results.inject(0) do |res, f|
          if yield_tagged
            tagged_snippet = TextSnippet.new(fname, t.tagged, f[:tagged_begin].to_i, f[:tagged_end].to_i)
            if yield_text
              text_snippet = TextSnippet.new(fname, t.text, f[:src_begin].to_i, f[:src_end].to_i)
              yield text_snippet, tagged_snippet
            else
              yield tagged_snippet
            end
          end
          res += 1
        end
        @progress[prog, (index += 1)]
        result
      end
    end

    def find_range(t_id, t_begin, t_end, process_original)
      if process_original
        ds = @db[:assoc].filter(:text_id => t_id).filter{tagged_end >= t_begin}.filter{tagged_begin < t_end}
        ds.select{[{min(:src_begin) => :src_begin},{ max(:src_end) => :src_end}, {min(:tagged_begin) => :tagged_begin}, {max(:tagged_end) => :tagged_end}]}.first
      else
        {:tagged_begin => t_begin, :tagged_end => t_end}
      end
    end

  end

  SearchStrategy = SlowSearch
end