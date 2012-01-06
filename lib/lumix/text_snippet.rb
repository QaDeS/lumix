module Lumix
  
  class TextSnippet
    attr_reader :name, :text, :begin, :end
    def initialize(name, text, first, last)
      @name = name
      @text = text
      @begin = first
      @end = last
    end
    def to_s
      cleanup(@text[@begin...@end])
    end
    def left(context = 5)
      ctx = [@begin - context * 10, 0].max
      @text[ctx...@begin].split(/\s+/).last(context).join(' ')# =~ /((\S+\s+){0,#{context}}\S*)\z/m
      #cleanup($1)
    end
    def right(context = 5)
      ctx = [@end + context * 10, @text.size].min
      @text[@end..ctx].split(/\s+/).first(context).join(' ')# =~ /\A(\S*(\s+\S+){0,#{context}})/m
      #cleanup($1)
    end
    def cleanup(txt)
      txt.gsub(/\s+/, ' ')
    end
  end

end