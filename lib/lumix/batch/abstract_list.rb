require 'lumix/text_snippet'
require 'lumix/lookup'
require 'lumix/thread_pool'
require 'lumix/model/sequel_models'
require 'lumix/batch/word_types'

TaggedText.db = DB

#
# Prepare the filters
#

def words(inc, ex = nil)
  select(:words, :word, :id, inc, ex)
end

def tags(inc, ex = nil)
  select(:tags, :tag, :id, inc, ex)
end

def raw_words(inc, ex = nil)
  select(:words, :word, :word, inc, ex)
end

def raw_tags(inc, ex = nil)
  select(:tags, :tag, :tag, inc, ex)
end

def select(table, field, outfield, inc, ex = nil)
  ds = DB[table].select(outfield)
  ds = ds.where(field => inc) if inc
  ds = ds.exclude(field => ex) if ex
  #ds.map{|e| e[outfield]}
  ds
end

#
# Find the hits
#

Filter = Struct.new(:word, :tag, :ex_word, :ex_tag)
Lookup = Lumix::Lookup.new(DB)
P = Pool.new(2)

def find(name, *filters)
  P.schedule do
  File.open(name, 'w')  do |f|
    last_id, t = -1, nil
    Lookup.find(filters.flatten) do |text_id, s_begin, s_end, t_begin, t_end, p_begin, p_end|
            t = TaggedText[text_id] if text_id != last_id
            last_id = text_id

            fname = File.basename(t.filename)
            text_snippet = Lumix::TextSnippet.new(fname, t.text, s_begin, s_end)
            tagged = t.tagged
            tagged[([t_begin, tagged.size].min)..([t_end, tagged.size].min)] = Lookup.reconstruct_tagged(text_id, p_begin, p_end)
            tagged_snippet = Lumix::TextSnippet.new(fname, tagged, t_begin, t_end)
      f.puts "#{text_snippet.name}: #{text_snippet.left} | #{tagged_snippet.to_s} | #{text_snippet.right}"
    end
  end
  end
end

