def word(token)
  token.split(/\|/).first
end

def write_target(filename, ranking)
  File.open(filename, 'w') do |f|
    ranking.each do |(tuple, count)|
      f.puts "#{tuple}:#{count}"
    end
  end
end

LineRE = /^([^\:]+)\:([^\|]+)\|(.*)\|([^\|]*)$/

def create_list(source, tuples = nil)
  raise "Input filename must be given" unless source
  tuples = Hash.new(0) unless tuples

  dir = "ngenn/#{source}"
  `mkdir -p #{dir}`
  File.open(source, 'r') do |f|
    begin
      while line = f.readline
        line.chomp!
        filename, lcontext, hit, rcontext = LineRE.match(line).captures
        hits = hit.strip.split(/\s/)
        begin
          tuple = [word(hits.first), word(hits.last)].join('_')
          key = tuple.downcase
          File.open("#{dir}/#{key}", 'a') do |out|
            out.puts line
          end
          tuples[key] += 1
        rescue NoMethodError
          puts "Error with '#{line}'"
        end
      end
    rescue EOFError
    end
  end
  tuples
end

def create_lists(sources)
  sources.inject(nil){|r, s| create_list(s, r).tap{|h| puts "Got #{h.size} intermediate results"}}
end

def write_list(source)
  tuples = create_list(tuples)
  ranking = tuples.sort_by{|(k,v)| v}.reverse
  write_target(source + '.tuples', ranking)
end

if $0 == __FILE__
  ARGV.each{ |f| write_list(f) }
end