correct_path = ARGV.pop || '*'
correct_file = ARGV[0] || '/home/mklaus/Dropbox/me/grepit'

Ignores = Regexp.new(" (#{File.readlines(correct_file).map(&:strip).map{|s| Regexp.quote(s) }.join('|')})\\|", 'i')
puts Ignores.to_s
Dir.glob(correct_path).each do |file|
  path = File.expand_path("../clean", file)
  `mkdir -p '#{path}'`
  File.open(File.join(path, File.basename(file)), 'w') do |out|
    File.readlines(file).each do |line|
      begin
        unless line =~ Ignores
          out.puts(line)
        else
          puts line if line =~ /ocupatie/
        end
      rescue
        puts line
      end
    end
  end
end