module Lumix
  class LookupFilter

    attr_reader :results, :filter

    Filter = Struct.new(:word, :tag, :ex_word, :ex_tag)

    def initialize(lookup, filter, &result_proc)
      @filter = filter
      @result_proc = result_proc

      @filters = create_filters(lookup, filter)
      @results = 0
    end

    def <<(result)
      @results += 1
      @result_proc[*result] if @result_proc
    end

    def apply(lookup, &block)
      lookup.find(@filters) do |range|
        block[*range] if block and range
      end
    end

    def create_filters(lookup, filter)
      filter.scan(/(?:(?:\"([^\"]+)\")|(\S+))+/).map do |word, tag|
        word_re = to_re(word)
        tag_re = to_re(tag)
        word_ids = lookup.find_word(word_re) if word_re
        tag_ids = lookup.find_tag(tag_re) if tag_re
        Filter.new(word_ids, tag_ids)
      end
    end

    def to_re(txt)
      return nil if txt.nil? || txt.empty?
      Regexp.new('^' + txt.gsub(/\s/, '_').gsub(/\*/, '\S*').gsub(/\?/, '\S') + '$', 'i')
    end

  end
end
