Tuples = File.readlines('../tuples.lst').map(&:chomp)

Tuples.each_slice(20) do |tuples|
  files = []
  search = tuples.map do |tuple|
    w1, w2, count = tuple.split(/\:/)
    files << "#{w1}_#{w2}"
    %Q('"#{w1}" "#{w2}"')
  end.join(' ')
  `jruby -Eutf-8:utf-8 -Ku -U -J-Xmx2048m -I ../../../lib/ ../../../bin/lumix search #{search}`
  files.each do |file|
    `echo #{file} >> ../correlations.lst`
  end
end