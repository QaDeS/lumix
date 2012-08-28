def aggregate_files(to_file, pattern = '*', &block)
  emits = Hash.new(0)
  emit = proc{|emitted| emits[emitted] += 1}

  Dir.glob(pattern).each do |fname|
    next unless File.file?(fname)
    File.open(fname, 'r') do |f|
      block.call f, emit        
    end
  end

  File.open(to_file, 'w') do |out|
    emits.sort_by{ |(k, v)| k }.each do |(reg, count)|
      out.puts "#{reg}; #{count}"
    end
  end
end

def process_files(to_path, pattern = '*')
  Dir.glob(pattern).each do |fname|
    next unless File.file?(fname)
    path = File.expand_path("../#{to_path}", fname)
    `mkdir -p '#{path}'`
    File.open(File.join(path, File.basename(fname)), 'w') do |out|
      File.open(fname, 'r') do |f|
        yield f, out
      end
    end
  end
end

def process_lines(to_path, pattern = '*')
  process_files(to_path, pattern) do |f, out|
    f.each_line do |line|
      yield out, line if line && !line.strip.empty?
    end
  end
end
