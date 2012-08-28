require 'lumix/batch/abstract_list'

# maximum length of an acronym
MAX_LENGTH = 8

# get all upper case words
up_words = raw_words(/^[A-Z]{2,#{MAX_LENGTH}}$/)

# get those words ignoring case
mixed_words =  DB[:words].where(:upper.sql_function(:word) => up_words).map{|e| e[:word]}.
# ignoring the all uppercase ones
  reject{|w| w.upcase == w}

# remove mixed words from the upper case ones
Acronyms = words(up_words - mixed_words.map(&:upcase))
N = tags(/^N.*/)

find "N_acro", [Filter.new(nil, N), Filter.new(Acronyms, nil)]

P.shutdown