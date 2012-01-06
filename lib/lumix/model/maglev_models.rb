require 'lumix/model/base_models'

class TaggedText

  def save
    Maglev.commit_transaction
  end

  def save_new
    self.table << self
  end

  class << self

    def each(&block)
      table.each &block
    end

    def [](key)
      case key
      when Hash
        # find by values

      when Integer
        # find by id
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