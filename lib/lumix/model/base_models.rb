class TaggedText
  module InstanceMethods
    include Enumerable

    def create(attrs)
      new(attrs).save_new
    end

    private
    def accessor(*names)
      names.each do |name|
        define_method name do
          @attrs[name]
        end
        define_method "#{name}=" do |v|
          @attrs[name] = v
        end
      end
    end
  end
  extend InstanceMethods

  def initialize(attrs)
    @id = attrs.delete(:id)
    @attrs = attrs
  end
  attr_reader :id
  accessor :text, :tagged, :fulltagged, :filename, :tagged_filename, :digest

  def update(attrs)
    @attrs.merge(attrs)
    save
  end

end