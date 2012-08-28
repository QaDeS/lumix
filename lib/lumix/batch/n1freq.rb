N1 = Hash.new(0)
Files = Dir.glob('N*_*')

Files.each do |fname|
  File.open(fname, 'r') do |f|
    f.each_line do |l|
      m = R.match(l)
      next unless m
      left, hit, right = m.captures
      word = hit.split(/\s/).first.split('|').first
      #puts "#{fname}: #{l}" unless word
      N1[word.downcase] += 1
    end
  end
end

File.open('N1_common.csv', 'w') do |out|
  N1.sort_by{|k, v| v}.reverse.each do |(k, v)|
    out.puts "#{k};#{v}"
  end
end
