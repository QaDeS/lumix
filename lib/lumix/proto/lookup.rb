require 'msgpack'

module Lumix

  TEXT_ID = 0
  S_BEGIN = 1
  S_END = 2
  T_BEGIN = 3
  T_END = 4

  class Lookup
    def initialize
      puts "Lookup"
      @tags = {} # tag => token_id[]
      @words = {} # word => token_id[]
      @tokens = [] # :text_id, :s_begin, :s_end, :t_begin, :t_end
      @texts = [] # text_id
      Signal.trap('INT'){exit}
      at_exit do
        save
      end
      load
    end

    def load
      @dirty = false
      return unless File.exists?('lookup.dat')
      puts "Loading"
      load_file :tags
      load_file :words
      load_file :texts
      load_file :tokens
    end

    def save
      return unless @dirty
      @saving = true
      puts "Saving"
      save_file :tags
      save_file :words
      save_file :texts
      save_file :tokens
      @saving = false
    end

    def with(*types)
      args = types.flatten.map{|name| instance_variable_get("@#{name}") || instance_variable_get("@#{name}",load_file(name)) }
      yield *args
    end

    def save_file(name)
      data = instance_variable_get("@#{name}")
      File.open(name.to_s + '.dat', 'w') do |f|
        f.print MessagePack.pack(data)
      end
    end

    def load_file(name)
      MessagePack.unpack(File.read(name.to_s + '.dat'))
    end

    def process(text_id)
      return if @saving
      @dirty = true
      return true if @texts.member?(text_id)
      @texts << text_id

      yield if block_given?
    end

    def add_token(text_id, word, tag, s_begin, s_end, t_begin, t_end)
      return if @saving
      @dirty = true
      id = (@tokens << [text_id, s_begin, s_end, t_begin, t_end]).size - 1
      (@words[word] ||= []) << id
      (@tags[tag] ||= []) << id
    end

    def find_word(re)
      find_ids @words, re
    end

    def find_tag(re)
      find_ids @tags, re
    end

    # returns the start indices of matching sequences
    def union(*id_sets)
      unified = id_sets.each_with_index.map{|c,i| c.map{|e| e-i}}
      unified.inject(:&)
    end

    def text_range(t_begin, t_end)
      a, b = @tokens[t_begin], @tokens[t_end]
      return nil unless a[TEXT_ID] == b[TEXT_ID]
      return a[TEXT_ID], a[S_BEGIN], b[S_END], a[T_BEGIN], b[T_END]
    end

    private
    def find_ids(arr, re)
      elems = arr.keys.grep(re)
      elems.map{|e| arr[e]}.flatten
    end
  end
end