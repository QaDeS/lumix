require 'lumix/lookup_filter'
require 'lumix/text_snippet'
require 'lumix/lookup'

module Lumix

  class LookupSearch

    TAGGED = /([^\s\|]+)\|(\S+)/m        # Xxx|YYY

    def initialize(db, progress)
      @lookup = Lookup.new(db)
      @progress = progress
    end

    def concurrent_link?
      true
    end

    def simulate!
      @simulate = true
    end

    def link_text(id)
      ds = TaggedText[id]
      @lookup.process id do |doc|
        result = true

        file, text, tagged = ds.filename, ds.text, ds.tagged

        puts "Linking text #{file}"

        txt_pos = 0
        position = 0
        tagged.scan(TAGGED) do |word, tag|
          tagged_begin = $~.begin(0)
          tagged_end = $~.end(0)

          # expand "x_y_z" notation to "x y  z"
          word_re = Regexp.new(Regexp.escape(word).gsub(/\_/, '\s+'))
          src_match = text[txt_pos..-1].match(word_re) # find the word
          if src_match
            offset = src_match.begin(0)
            src_begin = txt_pos + offset
            src_end = txt_pos + src_match.end(0)
            txt_pos = src_end

            unless @simulate
              doc.add_token(id, position, word, tag, src_begin, src_end, tagged_begin, tagged_end)
            end
          else
            STDERR.puts "Could not find match for '#{word}' in text #{file}"
            STDERR.puts text[(txt_pos-10)..(txt_pos+word.size+10)]
            `echo '#{file}:#{txt_pos}:#{tagged_begin} unmatched "#{word}"' >> unlinked.lst`
            result = nil
            break
          end
          position += 1
        end
        result
      end
    rescue => e # TODO remove this crap
      STDERR.puts e
      STDERR.puts e.backtrace
      raise e
    end

    def create_filter(f, &block)
      Lumix::LookupFilter.new(@lookup, f, &block)
    end

    def find(*filters, &block)
      p = Pool.new(Lumix::CONNECTIONS)
      filters.flatten.each do |f|
        p.schedule do
          last_id = -1
          t = nil
          f.apply(@lookup) do |text_id, s_begin, s_end, t_begin, t_end, p_begin, p_end|
            t = TaggedText[text_id] if text_id != last_id
            last_id = text_id
          
            fname = File.basename(t.filename)
            text_snippet = Lumix::TextSnippet.new(fname, t.text, s_begin, s_end)
            tagged = t.tagged
            tagged[([t_begin, tagged.size].min)..([t_end, tagged.size].min)] = @lookup.reconstruct_tagged(text_id, p_begin, p_end)
            tagged_snippet = Lumix::TextSnippet.new(fname, tagged, t_begin, t_end)
            f << [text_snippet, tagged_snippet]
          end
        end
      end
      p.shutdown
    end

  end

  SearchStrategy = LookupSearch
end
