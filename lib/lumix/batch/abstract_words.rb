R = /^([^\|]*)\|\s*(.*)\s*\|([^\|]*)$/

class String
  def hit
    @hit ||= begin
      m = R.match(self)
      m.captures[1] if m
    rescue
      puts self
    end
  end

  def tokens
    @tokens ||= begin
      hit.split(/\s/) if hit
    end
  end

  def words
    @words ||= begin
      tokens.map{|s| s.split('|').first } if tokens
    end
  end

  def n1
    words ? words[0] : ''
  end

  def n2
    words ? words[1] : ''
  end
end

