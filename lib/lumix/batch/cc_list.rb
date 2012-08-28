require 'lumix/batch/abstract_list'

`mkdir cc`
CC.each do |n1|
  tn1 = tags(n1)
  CC.each do |n2|
    next if n1 == n2
    tn2 = tags(n2)
    find "cc/#{n1}_#{n2}", [Filter.new(nil, tn1), Filter.new(nil, tn2)]
  end
end


P.shutdown
