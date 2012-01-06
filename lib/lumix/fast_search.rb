require 'lumix/filter'
require 'lumix/text_snippet'

module Lumix

  class FastSearch

    TAGGED = /([^\s\|]+)\|(\S+)/m        # Xxx|YYY
    ORIG = /([^\|\s]*)\|([^\|\s]*)\|([^\|\s]*)\|(\S*)/ # X|Y|Z|W

    def initialize(db, progress)
      @db = db
      @progress = progress
    end

    def link_text(id)
      ds = TaggedText[id]
      return ds.fulltagged if ds.fulltagged
      file, text, tagged = ds.filename, ds.text, ds.tagged

      puts "Linking text #{file}"

      txt_pos = 0
      linked = ''
      tagged.scan(TAGGED) do |word, tag|
        tagged_begin = $~.begin(0)

        # expand "x_y_z" notation to "x y z"
        word_re = Regexp.new(Regexp.escape(word).gsub(/_/, '\s*'))
        src_match = text[txt_pos..-1].match(word_re) # find the word
        if src_match
          offset = src_match.begin(0)
          src_begin = txt_pos + offset
          src_end = txt_pos + src_match.end(0)
          txt_pos = src_end

          linked << ' ' unless linked.empty?
          linked << word << '|' << tag << '|' << src_begin.to_s << '|' << src_end.to_s
        else
          STDERR.puts "Could not find match for '#{word}' in text #{file}"
          STDERR.puts text[(txt_pos-10)..(txt_pos+word.size+10)]
          `echo '#{file}:#{txt_pos}:#{tagged_begin} unmatched "#{word}"' >> unlinked.lst`
          return nil
        end
      end
      unless linked.empty?
        ds.fulltagged = linked
        ds.save
      end
      return linked
    rescue => e # TODO remove this crap
      STDERR.puts e
      STDERR.puts e.backtrace
      raise e
    end

    def create_filter(f, &block)
      Lumix::Filter.new('\|(\d+)\|(\d+)', f, &block)
    end

    def find(filters)
      prog = Progress.new(:search, TaggedText.count, "", 0)
      @progress[prog] if @progress


      TaggedText.each_with_index do |t, i|
        # matches to ranges
        filters.each do |f|
          f.scan(t.fulltagged) do |hit, t_begin, t_end, m|
            s_begin = m.captures.first.to_i
            s_end = m.captures.last.to_i

            fname = File.basename(t.filename)
            tagged_snippet = Lumix::TextSnippet.new(fname, t.fulltagged, t_begin, t_end)
            text_snippet = Lumix::TextSnippet.new(fname, t.text, s_begin, s_end)
            f << [text_snippet, tagged_snippet]
          end
        end
        prog.done = i
        @progress[prog] if @progress
      end
    end

  end

end
