module Lumix
  class Filter

    HANDLERS = %w[handle_wildcard handle_choice handle_literals
              handle_dangling_tags handle_multiplicators ensure_wordbounds]

    attr_reader :results, :filter
    
    def initialize(suffix, filter, &result_proc)
      @suffix = suffix.gsub(/\\\|/, '[\|]') # workaround to make handle_dangling_tags play nicely
      @filter = filter
      @result_proc = result_proc

      @re = to_re(filter)
      @results = 0
    end

    def <<(result)
      @results += 1
      @result_proc[*result] if @result_proc
    end

    def scan(text, &block)
      results = []
      return results unless text
      (' ' + text + ' ').scan(@re) do |s|
        t_begin = $~.begin(0) - 1
        t_end = $~.end(0) - 1

        s = block ? block[s, t_begin, t_end, $~] : s
        results << s
      end
      results
    end

    def to_re(filter)
      re = HANDLERS.inject(filter) do |filter, handler|
        puts filter
        puts "#{handler} -->"
        send handler, filter
      end
      puts re
      Regexp.new(re)
    end

    # character wildcard replacement
    def handle_wildcard(re)
      re.gsub(/([^\)])\*/, '\1[^\s\|]*')
    end

    # Takes (!A B C) and transforms it
    def handle_choice(re)
      re.gsub(/\(\!([^\)]+)\)/) do
        c = $1.split.map{ |t| '(?!' + t + ')' }.join
        '(?:' + c + '[^\s\|]*' + @suffix + ')'
      end
    end
    
    # transforms literals delimited by ""
    def handle_literals(re)
      re.gsub(/\"([^\"]*)\"(?:\|(\S+?))?/) do
        str = $1
        tag = $2 || '[^\s\|]+'
        str.gsub(/ /, '_') + '\|' + tag
      end
    end
    
    # add wildcard word match on tag-only search criteria
    def handle_dangling_tags(re)
      re.split(/ /).map do |s|
        if s =~ /\|[^\]]/
          s + @suffix
        else
          s.gsub(/(\(?)([^\)]+)(\S*)/, '\1[^\s\|]+\|\2' + @suffix + '\3')
        end
      end.join('\s+')
    end
    
    # Handles the + * ? and {} qualifiers
    def handle_multiplicators(re)    
      re.gsub(/\(([^\)]+)(\)((\{[^\}]+\})|\*|\+|\?)\s?)/, '(?:\1\s\2')
    end
    
    def ensure_wordbounds(re)
      re # ending wordbounds is being taken of earlier
    end

  end
end
