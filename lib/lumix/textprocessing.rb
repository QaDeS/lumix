$KCODE='UTF-8'

require 'cgi'
require 'soap/wsdlDriver'
#require 'curb'
#require 'savon'
require 'lumix/charset' unless RUBY_ENGINE =~ /maglev/i

class TextProcessing

  attr_accessor :lang

  def initialize(lang = 'ro')
    @lang = lang
  end

  def rpc
#    Thread.current[:rpc] ||= begin
#      wsdl = SOAP::WSDLDriverFactory.new('http://www.racai.ro/webservices/TextProcessing.asmx?WSDL')
#      wsdl.create_rpc_driver
#      Savon::Client.new('http://www.racai.ro/webservices/TextProcessing.asmx?WSDL')
#    end
    @rpc ||= SOAP::WSDLDriverFactory.new('http://www.racai.ro/webservices/TextProcessing.asmx?WSDL').create_rpc_driver
  end

  # the core processing routing using the webservice
  def process(text)
    response = rpc.Process(:input => text.to_utf, :lang => lang)
    response.processResult
#    response = rpc.request(:process) do
#      soap.body = {:input => text, :lang => lang}
#    end
#    response.to_hash[:process_response][:process_result]
  end

  def cleanup(file)
    @entities ||= HTMLEntities.new
    @entities.decode()
  end

  # inserts "tagged" as the second to last part in the filename and as parent folder
  # e.g.
  #   test.txt -> tagged/test.tagged.txt
  # special case when no extension is present:
  #   README -> README.tagged
  def create_tagged_filename(infile)
    path = infile.split(/\//)

    # take care of the filename...
    components = path.pop.split(/\./)
    position = [1, components.size-1].max
    components.insert position, 'tagged'
    path.push components.join('.')

    # ...and of the path
    path.insert -2, 'tagged'
    path.join '/'
  end

  def to_filelist(*files)
    files = files.flatten.map do |filename|
      if File.directory?  filename
        Dir.glob File.join(filename, '**/*') # add all files from that directory
      else
        filename
      end
    end.flatten.compact.uniq # make sure every file is only processed once
    files.delete_if { |filename| File.directory?(filename) ||  filename['.tagged']} # remove remaining folders
  end

  def process_stdin
    puts process($stdin.read)
  end

  # takes the text from infile and outputs the result into the outfile
  def process_file(infile, outfile = create_tagged_filename(infile))
    result = process(File.read(file).to_utf)
    File.open(outfile, 'w') do |out|
      out.write result
    end
  end

end


# process the args if called as main script
if __FILE__ == $0
  args = ARGV
  tp = if args.first == '-lang'
    args.shift
    TextProcessing.new(args.shift)
  else
    TextProcessing.new
  end

  if args.empty?
    tp.process_stdin
  else
    files = tp.to_filelist(args)

    puts "Processing files:"
    for infile in files
      outfile = tp.create_tagged_filename(infile)
      puts "#{infile} -> #{outfile}"
      tp.process_file(infile, outfile) unless File.exist?(outfile)
    end
  end
end
