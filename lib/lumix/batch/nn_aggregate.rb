Tuples = File.readlines('tuples.lst').map(&:chomp)
Files = File.readlines('correlations.lst').map(&:chomp)

NSN = Hash.new(0)
NN = Hash.new(0)

Tuples.each do |tuple|
  w1, w2, nsn_count = tuple.split(/\:/)
  fname = "#{w1}_#{w2}"
  next unless Files.member?(fname)

  file = "nn/#{fname}"
  next unless File.exists?(file)

  nn_count = `wc -l #{file}`.split.first
  key = fname.downcase
  NSN[key] += nsn_count.to_i
  NN[key] += nn_count.to_i
end

File.open('nsn_vs_nn.lst', 'w') do |f|
  NN.sort_by{|(k,v)| v}.reverse.each do |(tuple, nn)|
    f.puts "#{tuple}:#{nn}:#{NSN[tuple]}"
  end
end

