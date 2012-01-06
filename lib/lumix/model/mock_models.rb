require 'lumix/model/base_models'

class TaggedText

  def save
    # data aware ;)
  end

  def save_new
    self.class.table << self
  end

  class << self

    def table
      @@table ||= []
    end

    def each(&block)
      table.each &block
    end

    def [](key)
      case key
      when Hash
        # find by values

      when Integer
        table[key]
      when String
        # find by filename
      end
    end

    def exists?(attrs)
    end

    def ids
    end

    def count
    end

  end

end