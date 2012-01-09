module Lumix
  class LookupFilter

    attr_reader :results, :filter
    
    def initialize(filter, &result_proc)
      @filter = filter
      @result_proc = result_proc

      @re = create_re(filter)
      @results = 0
    end

    def <<(result)
      @results += 1
      @result_proc[*result] if @result_proc
    end

    def apply(lookup, &block)
      results = @re.map do |(type, re)|
        lookup.send("find_#{type}", re)
      end
      lookup.union(*results).each do |id|
        range = lookup.text_range(id, id + @re.size - 1) # TODO make more dynamic
        block[*range] if block and range
      end
    end

    def create_re(filter)
      filter.scan(/(?:(?:\"([^\"]+)\")|(\S+))+/).map do |word, tag|
        word ? [:word, to_re(word)] : [:tag, to_re(tag)]
      end
    end

    def to_re(txt)
      Regexp.new('^' + txt.gsub(/\s/, '_').gsub(/\*/, '\S*').gsub(/\?/, '\S') + '$')
    end

  end
end
