#!/bin/env ruby

# TODO take care of 's problem
# TODO remove Word count line

require 'rubygems'
require 'digest/md5'
require 'sequel'
require 'sequel/extensions/migration'

require 'lumix/model/sequel_models'

require 'lumix/thread_pool'
require 'lumix/textprocessing'
require 'lumix/lookup_search'
#require 'lumix/fast_search'

module Lumix
  WORKERS = (ENV['LUMIX_WORKERS'] || 20).to_i
  RELINK = ENV['LUMIX_RELINK']

  DB_VERSION = 4

  class ::String
    def digest
      return @digest if @digest
      digest = Digest::MD5.new
      digest.update self
      @digest = digest.hexdigest
    end
  end

  Progress = Struct.new(:task, :work, :data, :done)

  class Concordancer

    class << self
    end

    attr_reader :db, :tp
    attr_accessor :progress_proc
    attr_writer :link_on_import

    def initialize(db_uri, options = {})
      @progress_proc = options[:progress_proc]
      @db = connect(db_uri)
      if options[:recreate]
        db.tables.each{ |t| db.drop_table t }
        migrate(db)
      end

      @ids = all
      @tp = TextProcessing.new
    end

    def strategy
      @strategy ||= SearchStrategy.new(@db, @progress_proc)
    end

    def create_link_pool
      Pool.new(strategy.concurrent_link? ? 4 : 1)
    end

    def link_on_import?
      @link_on_import
    end

    def link_on_import!
      @link_on_import = true
    end

    def get_id(file)
      text = File.read(file).to_utf
      saved = TaggedText[:digest => text.digest]
      saved ? saved.id : nil
    end

    def read(*files)
      files = tp.to_filelist(*files)
      prog = Progress.new(:read, files.size)
      puts "Reading #{files.size} files"
      @unprocessed = if File.exists?('unprocessed.lst')
        File.readlines('unprocessed.lst').map(&:chomp)
      else
        []
      end

      File.open('unprocessed.lst', 'a') do |up|
        l = create_link_pool
        p = Pool.new(WORKERS)

        l.schedule{ link! } if RELINK

        files.each_with_index do |file, index|
          if @unprocessed.member?(file)
            puts "Ignoring #{file}"
            next
          end
          p.schedule do
            begin
              id = read_file(file)
              l.schedule { link id } if id and link_on_import?
            rescue
              puts "Error on file #{file}: #{$!}", $!.backtrace
              @unprocessed << file
              up.puts file
            end
            progress(prog, index + 1)
          end
        end
        l.schedule { link } if link_on_import? # make sure everything is linked
        p.shutdown
        l.shutdown
      end
    end

    def read_file(file)
      text = File.read(file).to_utf
      saved = TaggedText.exists?(:filename => file, :digest => text.digest)

      unless saved
        puts "Reading file #{file}"
        # retrieve the tagged version
        tagged_file = tp.create_tagged_filename(file)
        tagged = if File.exists?(tagged_file)
          File.read(tagged_file)
        else
          tagged = tp.process(text)
          File.open(tagged_file, 'w') do |out|
            out.write tagged
          end
          tagged
        end

        retagged = retag(tagged)
        tt = TaggedText.create(:digest => text.digest, :text => text, :tagged => retagged, :filename => file, :tagged_filename => tagged_file)
        @ids << tt.id
        yield tt if block_given?
        tt
      end
    end

    def correct(*ids)
      ids = all if ids.empty?
      ids.flatten.each do |id|
        id = id.to_i
        d = TaggedText[id]
        next unless d

        file = d.filename

        text = File.read(file).to_utf
        d.text = text

        expected = text.digest
        if d.digest != expected
          puts "Correcting text #{file}"
          d.digest = expected
        end
        d.save
      end
    end

    def all
      TaggedText.ids
    end

    def simulate!
      strategy.simulate!
    end

    def link!(*ids)
      link(*ids) do |ds|
        ds.delete
      end
    end

    def link(*ids)
      ids = all if ids.empty?
      ids.flatten!
      prog = Progress.new(:link, ids.size)
      progress(prog)

      p = create_link_pool
      ids.each_with_index do |id, index|
        #ds = db[:assoc].filter(:text_id => id)
        #yield ds if block_given?

        # TODO implement force
        p.schedule do
          strategy.link_text(id) #if ds.empty?
          progress(prog, index + 1)
        end
      end
      p.shutdown
    end

    def create_filter(f, &block)
      strategy.create_filter(f, &block)
    end

    def find(filters)
      strategy.find(filters)
    end

    private
    def connect(db_uri)
      db = Sequel.connect(db_uri)
      begin
        db.get(1)
      rescue Exception => e
        puts 'Falling back to sqlite'
        puts e
        db = Sequel.connect('jdbc:sqlite://concordancer.db')
      end
      migrate(db)
      TaggedText.db = db
    end

    def migrate(db)
      migration_path = File.join(File.dirname(__FILE__), 'schema')
      Sequel::Migrator.apply(db, migration_path, DB_VERSION)
    end

    def progress(prog, done = 0, data = prog.data)
      if progress_proc
        prog.done = done
        prog.data = data
        progress_proc.call(prog)
      end
    end

    def retag(text)
      chunks = text.split(/[ \n]/)
      return text if (token = chunks.first.split(/\|/)).size != 4 # looks pre-retagged
      tag_position = if token[2] =~ /\d+/ && token[3] =~ /\d+/ # looks like fulltagged
        1
      else
        2
      end
      
      result = ''
      chunks.each do |chunk|
        next unless chunk.empty?
        word, tag = chunk.split(/\|/)
        result << ' ' unless result.empty?
        result << "#{word}|#{tag[tag_position]}"
      end
      return result
    end

  end

end
