require 'lumix/base'

require 'sweet'
require 'lumix/result_view'
#Sweet.set_debug


Texts = {:search => "Searching...", :read => "Importing files", :link => "Linking texts"}
Indicator = %w'} ) ] | [ ( {'

CONF = 'config.yaml'
ConfigStruct = Struct.new(:database_uri)
CConfig = YAML.load_file(CONF) rescue ConfigStruct.new('jdbc:postgresql://localhost:5432/concordancer?user=concordancer&password=concordancer')
def save!
  File.open(CONF, 'w') do |f|
    f.write(CConfig.to_yaml)
  end
end

Sweet.app :title => 'Ruby Concordancer', :width => 800, :height => 700, :layout => :grid.conf(:numColumns => 3) do
  def conc
    @conc ||= Concordancer.new(CConfig.database_uri, :progress_proc => @progress_proc)#, :recreate => true)
  end

  @progress_proc = proc do |p|
    task = Texts[p.task] || p.task
    perform do
      if p.done == p.work
        @p_status.text = 'Done!'
        @p_indicator.text = ''
        @p_bar.fraction = 0
      else
        @p_status.text = task
        @p_indicator.text = Indicator[p.done % Indicator.size]
        @p_bar.fraction = p.done.to_f / p.work
      end
    end
  end

  save! unless File.exists?(CONF)

  menubar do
    submenu '&File' do
      submenu '&Import...' do
        item('E&nglish texts') { import_chooser('en') }
        item('&Romanian texts') { import_chooser('ro') }
      end
      item('&Export findings...') { export_findings }
      separator
      item('&Relink texts') { relink }
      item('&Clear the database') { reconnect :recreate => true }
      separator
      item('E&xit') { exit }
    end
    #    submenu 'C&orpora' do
    #      @m_cat = submenu '&Category' do
    #        item('Cre&ate...') { create_category }
    #        item('&Import...') { import_chooser }
    #        separator
    #        item('&Edit...') { edit_category }
    #        item('&Delete') { delete_category }
    #      end
    #      @m_text = submenu '&Text' do
    #        item('&Reimport...') { reimport_chooser }
    #        item('&Delete') { delete_text }
    #      end
    #    end
    #    @m_stats = submenu '&Statistics' do
    #      item('&Editor') { script_editor }
    #      separator
    #      item('&Load Script...') { load_script }
    #    end
    #    submenu "&Help" do
    #      separator
    #      item('&About') { about }
    #    end
  end

  tree :grid_data => {:align => [:fill, :fill], :span => [1, 2], :grab => [true, true]}

  @filter = edit_line 'NSN NSN', :grid_data => {:align => [:fill, :center], :grab => true}, :max_size => 40 do
    perform_search
  end
  button 'Search' do
    perform_search
  end
  
  @results = table :columns => %w[Text Left Hit Right], :sort => true, :grid_data => {:align => [:fill, :fill], :span => 2, :grab => [true, true]}, :scroll => true

  @counter = label :grid_data => {:span => 2, :align => :fill}

  @p_status = label(:grid_data => {:align => [:fill, :bottom], :grab => true})
  @p_bar = progress(:width => 50, :grid_data => {:align => [:right, :bottom]})
  @p_indicator = label('  ',  :grid_data => {:align => [:right, :bottom]})
  

  def perform_search
    filter = @filter.text
    @results.data.clear
    Thread.new do
      unless filter.empty?
        puts "finding #{filter}"
        found = conc.find(filter) do |text, tagged|
          @results.add_hit(text.name, text.left, text.to_s, text.right)
        end
      end
      perform do
        @counter.text = "#{found} matches"
        @p_status.text = "Found #{found || 'no'} matches for #{filter}"
      end
    end
  end
  
  def import_chooser(lang)
    conc.tp.lang = lang
    Thread.new(conc) do |conc|
      conc.read('raw')
    end
  end

  def export_findings
    filename = to_filename(@filter.text) + '.findings'
    @p_status.text = "Exporting to #{filename}"
    File.open(filename, 'w') do |f|
      @results.items.each do |item|
        unless item.getChecked
          left, hit, right = (0..2).map{ |i| item.text(i) }
          f.puts "#{left}\t#{hit}\t#{right}"
        end
      end
    end
    @p_status.text = "Done! Exported to file #{filename}"
  end

  def relink
    Thread.new(conc) do |conc|
      conc.link!
    end
  end

  def to_filename(filter)
    filter.gsub(/\s+/, "_").gsub(/[\*\.\?\"]/, '')
  end

  def reconnect(opts = {})
    @conc = Concordancer.new(CConfig.database_uri, opts.mergs(:progress_proc => @progress_proc))
  end
end