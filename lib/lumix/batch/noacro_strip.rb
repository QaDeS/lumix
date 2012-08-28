
ignores = File.readlines("/home/mklaus/Dropbox/me/grepit").map(&:strip).reject(&:empty?)
Ignores = Regexp.new("^" + Regexp.union(ignores).source + "$", 'i')

Lines = File.readlines('/home/mklaus/Dropbox/me/noacro_sorted_restripped_N2').map(&:strip).reject do |s|
  pre, hit, post = s.split(" \| ")
  n1, n2 = hit.strip.split(' ').map{|s| s.split('\|').first }
  n1 =~ Ignores || n2 =~ Ignores
end

File.open('/home/mklaus/Dropbox/me/noacro_sorted_restripped_grepped_N2', 'w') do |f|
  f.puts Lines
end
