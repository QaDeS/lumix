GenFiles = %w!N1_a_lui_NP  N1_a_Ngen  N1_lui_NP  N1_Ngen!
NNFile = 'N1_Ndiv'

require 'lumix/batch/nn_list'

Gen = GenFiles.inject({}){ |result, name| result.merge name => create_list(name) }
NN = create_list(NNFile).sort_by{|(k,v)| v}.reverse

Gen.each_pair do |name, tuples|
  File.open("nn_vs_#{name}.lst", 'w') do |f|
    NN.each do |(tuple, nn)|
      f.puts "#{tuple}:#{nn}:#{tuples[tuple]}" unless tuples[tuple] == 0
    end
  end
end
