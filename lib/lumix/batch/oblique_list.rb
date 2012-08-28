require 'lumix/batch/abstract_list'

N2 = %w!NN NPN NPRY NSN NSRN NSY!

Ignores = grepit
tn2 = tags(N2) # Common?

find "oblique_stripped", [Filter.new(Ignores, Ngen), Filter.new(Ignores, tn2)]

P.shutdown
