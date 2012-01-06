require 'yaml'

module Lumix
  Texts = {:search => "Searching...", :read => "Importing files", :link => "Linking texts"}

  CONF = 'config.yaml'
  ConfigStruct = Struct.new(:database_uri)
  CConfig = if File.exists?(CONF)
    YAML.load_file(CONF)
  else
    conf = ConfigStruct.new('jdbc:postgresql://localhost:5433/concordancer?user=concordancer&password=concordancer')
    File.open(CONF, 'w') do |f|
      f.write(conf.to_yaml)
    end
    conf
  end

  def conc
    @conc ||= create_concordancer
  end

  def import_files(lang, *path)
    conc.tp.lang = lang
    conc.read(path)
  end

  def relink
    conc.link!
  end

  def reconnect(opts = {})
    @conc = create_concordancer(opts)
  end

  def correct(*ids)
    conc.correct *ids
  end
  
  def to_filename(filter)
    filter.gsub(/\s+/, "_").gsub(/[\.\"]/, '')
  end

  def create_concordancer(opts = {})
    Concordancer.new(CConfig.database_uri, opts.merge(:progress_proc => progress_proc))
  end
end
require 'lumix/concordancer'
