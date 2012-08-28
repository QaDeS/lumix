R = /^([^\|]*)\|\s*(.*)\s*\|([^\|]*)$/

def freq(pattern)
  pairs = Hash.new(0)
  files = Dir.glob(pattern)

  files.each do |fname|
    File.open(fname, 'r') do |f|
      f.each_line do |l|
        m = R.match(l)
        next unless m
        left, hit, right = m.captures
        hits = hit.split(/\s/)
        word1 = hits.first.split('|').first
        word2 = hits.last.split('|').first
        pairs[word1.downcase + '_' + word2.downcase] += 1
      end
    end
  end

  pairs
end

def compare_freq(ofile, a, b)
  File.open(ofile, 'w') do |out|
    a.sort_by{|k, v| v}.reverse.each do |(k, v)|
      out.puts "#{k};#{v};#{b[k]}"
    end
  end
end
