FName = ARGV[0]

N1 = Hash.new(0)
N2 = Hash.new(0)
C = /^([^\|]*\|[^\|]*\|[^\|]*\|NP).*(\|\s[^\|]*)$/
R = /^([^\|]*)\|\s*(.*)\s*\|([^\|]*)$/

line = 0
CorrectedLines = File.readlines(FName).map do |l|
  line += 1
  puts line unless l[C,1]
  l.sub(C){$1 + ' ' + $2}
  R.match(l)
end

Lines = CorrectedLines.compact.sort_by do |l|
  left, hit, right = l.captures
  tokens = hit.split(/\s/)

  n1 = tokens.first.split('|').first
  n2 = tokens.last.split('|').first
  puts l unless n2

  N1[n1.downcase] += 1 if n1
  N2[n2.downcase] += 1 if n2
  n2
end

File.open("#{FName}_N1.csv", 'w') do |out|
  N1.sort_by{|k, v| v}.reverse.each do |(k, v)|
    out.puts "#{k};#{v}"
  end
end

File.open("#{FName}_N2.csv", 'w') do |out|
  N2.sort_by{|k, v| v}.reverse.each do |(k, v)|
    out.puts "#{k};#{v}"
  end
end

