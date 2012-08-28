$: << File.dirname(__FILE__)

require 'abstract_line'
require 'pp'

def read_config(lines)
  token_no = 0
  target = nil
  mappings = Hash.new{ |h,k| h[k] = [] }
  lines.each do |line|
    if line.strip.empty?
      target = nil
    elsif line.start_with?('##')
      target = line[/^##\s+(.*)$/, 1].gsub(/\s+/, '_')
    elsif line.strip.end_with?('=')
      token_no = line[/.*(\d+)\s*=/, 1].to_i - 1
    else
      mappings[target][token_no] ||= []
      new_words = line.split(',').map(&:strip).reject(&:'empty?').map do |w|
        if w.start_with? '-'
          Regexp.new('.*' + w[1..-1], Regexp::IGNORECASE)
        else
          w
        end
      end
      mappings[target][token_no] += new_words      
    end
  end
  result = {}
  mappings.each_pair do |target, tokens|
    next unless target
    result[target] = tokens.map do |words|
      next unless words
      next if  words.empty?
      word_re = Regexp.new(Regexp.union(words).source, Regexp::IGNORECASE)
      /^#{word_re}\|/
    end
  end
  result.tap{|r| pp r}
end

def perform_match(res, l)
  m = nil
  res.each_with_index do |re, i|
    next unless re
    l.hit.tokens.each do |token|
      m ||= re.match(token.raw)
    end
  end
  m
end

DefaultTarget = 'remainder'
def split_file(filename, config)
  default_file = File.open(DefaultTarget, 'w')
  config.keys.each do |fname|
    config[File.open(fname, 'w')] = config.delete(fname)
  end

  File.readlines(filename).each_with_index do |line, i|
    begin
      l = parse_line(line.strip)
    rescue
      STDERR.puts "Error in #{filename}:#{i}"
    end    
    next unless l
    match = config.detect { |f, res| perform_match(res, l) }
    out = if match
      match.first # the file
    else
      default_file
    end
    out.puts l.raw 
  end
end

config = ARGV[0]
filename = ARGV[1]
if config && filename
  split_file filename, read_config(File.readlines(config))
else
  puts "splitit <config-file> <data-file>"
end
