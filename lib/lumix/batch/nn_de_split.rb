require 'lumix/batch/abstract_list'

words = %w!tip gen fel soi model marca!.map{|w| [w, w + 'ul']}

`mkdir -p split`

#
# find the words
#
N = tags(/^N.*/)
words.each do |ws|
  find "#{ws[0]}_N", Filter.new(words(ws), nil), Filter.new(nil, N)
end
P.shutdown

def file(name)
  "split/#{name}"
end

words.each do |ws|
  # select the files
  files = ws.map do |w|
    Dir.glob("#{w}_*")
  end.flatten

  File.open(file(ws[0]), 'w') do |no_de|
    File.open(file('de_' + ws[0]), 'w') do |de|
      files.each do |fname|
        File.open(fname) do |f|
          f.each_line do |line|
            if line.split('|')[0] =~ /\sde\s*$/
              de.puts line
            else
              no_de.puts line
            end
          end
        end
      end
    end
  end
end

