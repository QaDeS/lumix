require 'lumix/batch/abstract_list'

Acronyms = acronyms()
NP = tags('NP')

find "acro_NP", [Filter.new(Acronyms, nil), Filter.new(nil, NP)]

P.shutdown
