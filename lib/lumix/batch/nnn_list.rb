require 'lumix/batch/abstract_list'

N = Filter.new(nil, Common)

find "nnn", [N, N, N]
find "nnnn", [N, N, N, N]

P.shutdown
