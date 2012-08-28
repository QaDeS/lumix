def words_before(word, distance = 1, &block)
  words_in_proximity(-distance, word, &block)
end

def words_after(word, distance = 1, &block)
  words_in_proximity(distance, word, &block)
end

def words_in_proximity(proximity, word, &block)
  DB[:tokens___hits].where(:hits__word_id => DB[:words].where(:word => word).select(:words__id)).
    join(:tokens___before, :text_id => :text_id){|l,r,j| {:position.qualify(l) => :position.qualify(r) + proximity} }.
    join(:words, :id => :before__word_id).
    distinct(:words__word).select(:words__word).
    each{|e| block.call e[:word] if block}
end