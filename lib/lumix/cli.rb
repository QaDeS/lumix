require 'lumix/base'

include Lumix

def help
  puts "lumix-cli import <en|ro> <path>"
  puts "lumix-cli [search] 'search string' ..."
  puts "lumix-cli relink"
  exit
end

def search(*filters)
  files = []
  fs = filters.map do |filt|
    file = create_findings_file(filt)
    next unless file
    files << file
    conc.create_filter(filt) do |text, tagged|
      file.puts "#{text.name}: #{text.left} | #{tagged.to_s} | #{text.right}"
      #file.puts "#{text.name}: #{tagged.to_s}"
    end
  end.compact

  conc.find(fs) unless fs.empty?

  fs.each do |f|
    puts "Found #{f.results == 0 ? 'no' : f.results} matches for #{f.filter}"
  end
ensure
  files.each{ |f| f.close }
end

def create_findings_file(filter, filename = to_filename(filter), &block)
  if File.exists?(filename)
    puts "File #{filename} already exists! Ignoring."
  else
    File.open(filename, 'w', &block)
  end
end

def tag(lang, file)
  conc.tp.lang = lang
  puts conc.tp.process(File.read(file))
end

def import!(lang, *files)
  conc.link_on_import!
  import_files(lang, *files)
end

def tag(lang, *files)
  p = Pool.new(10)
  conc.tp.lang = lang
  conc.tp.to_filelist(files).each do |file|
    p.schedule do
      tagged = conc.tp.create_tagged_filename(file)
      conc.tp.process_file(file, tagged) unless File.exists?(tagged)
    end
  end
  p.shutdown
end

private
def progress_proc
  task = nil
  percent = 0
  proc do |p|
    if !task or p.task != task
      task = p.task
      percent = 0
      puts Texts[task] || task
    end
    if p.done == p.work
      puts "Done"
    else
      new_percent = (100 * p.done / p.work).to_i
      if new_percent > percent
        print "." * ((new_percent - percent) / 2)
        percent = new_percent
      end
    end
  end
end


cmd, *args = ARGV
if !cmd
  #help
  cmd, *args = 'search', 'N "de" N'
end

c = cmd.downcase.to_sym
cmd = :help if c =~ /^-{1,2}help$/i
cmd = :search if !respond_to?(c)

send c, *args
