require 'lumix/batch/abstract_list'

class Acronyms < 
# maximum length of an acronym
MAX_LENGTH = 8

# get all upper case words
up_words = raw_words(/^[A-Z][a-zA-Z]{0,#{MAX_LENGTH-1}}[A-Z]/)

# get those words ignoring case
normal_words =  DB[:words].where(:upper.sql_function(:word) => up_words).map{|e| e[:word]}.
# ignoring the found acronyms
  reject{|w| up_words.member? w}.map(&:upcase)

# words that exist in normal form
acro_words = up_words.reject{|w| normal_words.member? w.upcase}
puts acro_words
Acronyms = words(acro_words)
