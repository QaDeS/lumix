require 'lumix/model/base_models'

class TaggedText

  def save
    self.class.table.where(:id => @id).update(@attrs)
  end

  def save_new
      @id = self.class.table.insert(@attrs)
  end

  class << self
    attr_accessor :db
    def each(&block)
      p = Pool.new(4)
      table.select(:id).each do |id|
        p.schedule{block.call self[id[:id]]}
      end
      p.shutdown
    end
    
    def table
      db[:texts]
    end

    def [](key)
      data = case key
      when Hash
        table[key]
      when Integer
        table[:id => key]
      when String
        table[:filename => key]
      end
      new data if data
    end

    def exists?(attrs)
      !table.where(attrs).empty?
    end

    def ids
      table.select(:id).map{|v| v[:id]}
    end

    def count
      table.count
    end

  end

end