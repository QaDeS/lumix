Line = Struct.new(:raw, :file, :pre, :hit, :post)
LineRE = /^([^\:]*)\:\s*([^\|]*)\|\s*(.*)\s*\|\s*([^\|]*)$/
def parse_line(line)
  return unless line_comps = LineRE.match(line)
  file, pre, hit, post = line_comps.captures
  Line.new line, parse_file(file), pre.strip, parse_hit(hit), post
end

Filename = Struct.new(:raw, :date, :reg, :no)
FileRE = /^(\d{4}\.\d{2}\.\d{2})\.(\S*)\.(\d+)$/
def parse_file(file)
  return unless file_comps = FileRE.match(file)
  date, reg, no = file_comps.captures
  Filename.new file, date, reg, no
end

Hit = Struct.new(:raw, :tokens)
def parse_hit(hit)
  tokens = hit.split(/\s+/).map{ |token| parse_token(token) }
  Hit.new hit, tokens
end

Token = Struct.new(:raw, :word, :tag)
def parse_token(token)
  Token.new token, *token.split('|')
end


