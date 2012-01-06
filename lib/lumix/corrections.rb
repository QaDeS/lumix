require 'lumix/charset'

CORRECTIONS = <<-TXT
: | COLON
ocupa | V3
asigurata | VPSF
mine | PPSA
batut | VPSM
insa | C
impotriva | S
americana | ASN
caruia | R
da | V3
duce| V3
primeasca | V3
daca | C
bulgara | ASN
ramina | V3
albaneza | ASN
pina | S
paraseasca | V3
publica | ASN
inceapa | V3
ecologic | ASN
internationala | ASN
ecologista | ASN
cada | V3
linga | S
adevaratele | APRY
citiva | PI
americana | ASN
Miclici| NP
fara | S
cit | PI
sugereaza | V3
incasa | V3
circa | R
ghiceste | V3
TXT

def corrections
  @corrections ||= CORRECTIONS.split(/\n/).map do |line|
    word, tag = line.split(/\|/).map(&:strip)
    puts "Tagging #{word} as #{tag}"
    [/\b#{word}\|\S+/, "#{word}\|#{tag}"]
  end
end

def correct(t)
  corrections.inject(t) do |result, (re, sub)|
    result.gsub(re, sub)
  end
end

def correct_all
  fs = Dir.glob('*tagged*')
  fs.each do |fn|
    t = correct(File.read(fn))
    File.open(fn, 'w') { |f| f.print t }
  end
end