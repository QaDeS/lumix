$: << File.expand_path('../../lib', __FILE__)
# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'lumix/filter'

puts RUBY_PLATFORM

Add = '|12|3'
TXT = ("They|PPER3 have|AUXP business|NN uses|VERB3 derp|ADNE too|ADVE " +
  "Apr|NN 4th|CD 2007|M have|DMKD .|PERIOD").split(' ').map{|e| e + Add }.join(' ') + ' '

def search(filter)
  f = Lumix::Filter.new('\|\d+\|\d+', filter)
  f.scan(TXT).map do |e|
    # strip out the additional components
    e.split(' ').map{ |c| c.strip[0..-Add.size-1] }.join(' ')
  end
end

describe Lumix::Filter do

  it "should find tags" do
    search('NN').should == %w[business|NN Apr|NN]
  end

  it "should find words" do
    search('"have"').should == %w[have|AUXP have|DMKD]
  end

  it "should find word and tag combinations" do
    search('"have" NN "uses"').should == ['have|AUXP business|NN uses|VERB3']
  end

  it "should find wildcard tags" do
    search('AU*').should == %w[have|AUXP]
  end

  it "should find exclusions" do
    search('A(!UXP DNE)').should == %w[too|ADVE]
  end

  it "should find word|tag pairs" do
    search('"have"|D*').should == %w[have|DMKD]
  end

  it "should find unlimited repetitions" do
    search('(AD*)+').should == ['derp|ADNE too|ADVE']
  end

  it "should find limited repetitions" do
    search('(AD*){3}').should == []
    search('(AD*){2}').should == ['derp|ADNE too|ADVE']
  end
end
