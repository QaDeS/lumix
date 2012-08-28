$: << File.dirname(__FILE__)

require 'abstract_line'
require 'abstract_process'

aggregate_files("reg_freq", ARGV[0] || '*') do |f, emit|
  f.readlines.each_with_index do |line, i|
    begin
      next unless l = parse_line(line)
    rescue
      STDERR.puts "Error in #{f.path}:#{i}"
      next
    end 
    if l.file
      emit[l.file.reg]
    else
      STDERR.puts "No file given in line", line
    end
  end
end
