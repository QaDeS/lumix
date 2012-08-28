require 'lumix/batch/abstract_list'
require 'lumix/batch/abstract_freq'

NNPattern = '/home/mklaus/Dropbox/me/Stefan_Corectate/N*'

FreqJobs = []
def do_freq(name, filters)
  find name, filters
  # frequencies take place after all data is gathered
  FreqJobs << proc{|nn| compare_freq "nn_vs_#{name}.csv", nn, freq(name) }
end

def nn_vs_x(name, x, alt_x = x)
  # 1. N1 + N2 versus N1 COMMON + analytical GENITIVE + N2 x
  do_freq 'Ncommon_a_' + name, [Filter.new(nil, Common), Filter.new(A, nil), x]

  # 2. N1 + N2 versus N1 COMMON + synthetic GENITIVE + N2 x
  do_freq 'Ncommon_' + name, [Filter.new(nil, Common), x])

  # 3. N1 + N2 versus N1 COMMON + PREPOSITION + N2 alt_x
  do_freq 'Ncommon_S_' + name, [Filter.new(nil, Common), Filter.new(nil, S), alt_x])
end

# 1., 2., 3.
nn_vs_x 'Ngen', Filter.new(nil, Ngen), Filter.new(nil, Common)
# 4., 5., 6.
nn_vs_x 'NP', Filter.new(nil, NP)
# 7., 8., 9.
nn_vs_x 'Acro', Filter.new(acronyms, nil)


P.shutdown

nn = freq(NNPattern)
FreqJobs.each {|fj| fj.call nn}
