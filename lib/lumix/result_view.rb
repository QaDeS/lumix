class Java::OrgEclipseSwtWidgets::Table

  attr_accessor :data, :tooltips
  
  def sweeten(app, opts={}, &block)
    @data = []
    @tooltips = []
    super
    @redraw_thread = Thread.new do
      while !isDisposed
        if @dirty
          @dirty = false
          perform do
            setItemCount data.size
            clearAll if clear_all
          end
        end
        sleep 1 # TODO find a better alternative
      end
    end

    # TODO implement tooltips

    addListener swt::SetData do |e|
      item = e.item
      index = indexOf(item)
      item.setText(Array(data[index]).to_java(:string))
    end

    addListener swt::Resize do |e|
      default_weight = 1.0 / columns.size
      current_width = @old_width
      w = width
      columns[0..-2].each do |c|
        weight = c.width == 0 ? default_weight : c.width.to_f / current_width
        c.width = w * weight
      end
      columns[columns.size - 1].pack
      @old_width = w
    end
  end

  def columns=(*titles)
    if titles
      titles.each do |title|
        col = widgets::TableColumn.new(self, swt::CENTER)
        col.setText title
      end

      setHeaderVisible true
      setLinesVisible true
    end
  end

  def sort=(sort)
    sort = Hash.new(true) if [true, :all].member?(sort)
    if sort
      columns.each_with_index do |col, index|
        if sort[col.text]
          col.addListener swt::Selection do
            if data
              @data = data.sort_by {|e| e[index] }
              update :clear
            end
          end
        end
      end
    end
  end
end

Sweet::WIDGET_DEFAULTS[:table] = {
  :style => [:border, :virtual, :check]
}
Sweet::WIDGET_HACKS[Java::OrgEclipseSwtWidgets::Table] = {
  :block_handler => :set_data,
  :custom_code => proc {
    def update(clear_all = false)
      return if isDisposed
      setItemCount data.size
      clearAll if clear_all
    end

    def add_hit(*args)
      opts = args.last === Hash ? args.pop : {}
      d = opts[:data] || args
      t = opts[:tooltips] || d
      data << d
      tooltips << t
      @dirty = true
    end
  }
}
