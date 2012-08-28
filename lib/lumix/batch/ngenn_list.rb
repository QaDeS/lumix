require 'lumix/batch/abstract_list'

N1 = n_without('NP')

find('N1_a_Ngen', [Filter.new(nil, N1), Filter.new(A, nil), Filter.new(nil, Ngen)])
find('N1_a_lui_NP', [Filter.new(nil, N1), Filter.new(A, nil), Filter.new(Lui, nil), Filter.new(nil, NP)])
find('N1_lui_NP', [Filter.new(nil, N1), Filter.new(Lui, nil), Filter.new(nil, NP)])
find('N1_Ngen', [Filter.new(nil, N1), Filter.new(nil, Ngen)])
find('N1_Ndiv', [Filter.new(nil, N1), Filter.new(nil, Ndiv)])

P.shutdown
