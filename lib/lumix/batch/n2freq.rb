N2 = Hash.new(0)
R = /^([^\|]*)\|\s*(.*)\s*\|([^\|]*)$/
Files = Dir.glob('N*_*')

Files.each do |fname|
  File.open(fname, 'r') do |f|
    f.each_line do |l|
      m = R.match(l)
      next unless m
      left, hit, right = m.captures
      word = hit.split(/\s/).last.split('|').first
      #puts "#{fname}: #{l}" unless word
      N2[word.downcase] += 1
    end
  end
end

File.open('acro_N2.csv', 'w') do |out|
  N2.sort_by{|k, v| v}.reverse.each do |(k, v)|
    out.puts "#{k};#{v}"
  end
end
