require 'ffi-icu'
require 'iconv'
require 'htmlentities'

class String

  NoMatchFound = Class.new(Exception)

  def to_utf(default = 'utf-8')
    @icu ||= ICU::CharDet::Detector.new
    result = icu_return(default) || find_icu
    raise NoMatchFound unless result

    @entities ||= HTMLEntities.new
    @entities.decode(result)
  end

  def find_icu
    matches = @icu.detect_all(self)
    matches.each do |match|
      if d = icu_return(match.name)
        return d
      end
    end
    return nil
  end

  def icu_return(cs)
    begin
      return Iconv.conv('UTF-8', cs, self)
    rescue
    end
  end

end