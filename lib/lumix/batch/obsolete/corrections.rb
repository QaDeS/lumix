raise "Obsolete, use correct.rb"

require 'lumix/charset'

CORRECTIONS = <<-TXT
catre | S
fetite | NPRN
in | S
si | C
circa | R
fata de| S
maxima | ASON
inainte| R
in materie de | R
tin | V3
beneficiaza | V3
: | COLON
ocupa | VN
asigurata | VPSF
mine | PPSA
batut | VPSM
insa | C
impotriva | S
americana | ASN
caruia | R
da | VN
duce| VN
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
incasa | VN
circa | R
ghiceste | V3
tarile |NPRY
araba | ASN
citeva | PI
schimbindu | VG
dupa | S
uleiurilor_vegetale | NPOY
botosaneana | ASN
oricarui | PI
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

def correct_all(path)
  fs = Dir.glob(File.join(path, '*tagged*'))
  fs.each do |fn|
    t = correct(File.read(fn))
    File.open(fn, 'w') { |f| f.print t }
  end
end

if $0 == __FILE__
  correct_all ARGV[0]
end