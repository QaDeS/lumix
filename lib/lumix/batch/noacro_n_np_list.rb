require 'lumix/batch/abstract_list'

# maximum length of an acronym
MAX_LENGTH = 8

NoAcronyms = words(nil, /^[A-Z][a-zA-Z]{0,#{MAX_LENGTH-1}}[A-Z]/)
N1 = n_widhout('NP')

find "noacro_N*_NP", [Filter.new(NoAcronyms, N1), Filter.new(NoAcronyms, NP)]

P.shutdown
