$: << File.dirname(__FILE__)

require 'abstract_words'
require 'abstract_process'

process_files('sorted', ARGV[0] || '*') do |f, out|
  begin
    cleaned = f.readlines.map do |s|
      begin
        s.strip
      rescue
        puts s
      end
    end
    out.puts cleaned.compact.sort_by{ |w| "#{w.n1}:#{w.n2}".downcase }
  end
end
