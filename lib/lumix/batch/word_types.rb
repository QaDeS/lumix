TNP = 'NP'
TS = 'S'
TNgen =   %w!NPOY NSOY NSON!
TNdiv =   %w!NN NPRY NSN NSRN NSRY NSY NPN NPRN!
TCommon = %w!NN NPRY NSN NSRN NSRY NSY NPN!
TA = %w!al a ai ale!
TLui = 'lui'

NP = tags(TNP)
S = tags(TS)
Ngen = tags(TNgen)
Ndiv = tags(TNdiv)
Common = tags(Common)
A = words(TA)
Lui = words(TLui)

def n_without(*excludes)
  tags(/^N.*$/, excludes)
end

def acronyms(max_length = 8, min_length = 2)
  # get all upper case words
  up_words = raw_words(/^[A-Z][a-zA-Z]{#{min_length-2},#{max_length-2}}[A-Z]/)

  # get those words ignoring case
  normal_words =  DB[:words].where(:upper.sql_function(:word) => up_words).map{|e| e[:word]}.
  # ignoring the found acronyms
    reject{|w| up_words.member? w}.map(&:upcase)

  # words that exist in normal form
  acro_words = up_words.reject{|w| normal_words.member? w.upcase}
  words acro_words
end

def grepit
  @ignores ||= File.readlines("/home/mklaus/Dropbox/me/grepit").map(&:strip).reject(&:empty?)
  @grepit ||= words(nil, Regexp.new("^" + Regexp.union(ignores).source + "$", 'i'))
end
