$: << File.expand_path('../../lib', __FILE__)
# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'lumix/lookup_search'
require 'lumix/model/sequel_models'
require 'lumix/concordancer'

puts RUBY_PLATFORM

TEXT = "They have business uses derp too Apr 4th 2007 have ."
TAGGED = "They|PPER3 have|AUXP business|NN uses|VERB3 derp|ADNE too|ADVE " +
  "Apr|NN 4th|CD 2007|M have|DMKD .|PERIOD"
module Helper
  def lookup
    return @lookup if @lookup
    @conc = Lumix::Concordancer.new('jdbc:postgresql://localhost:5433/concordancer_test?user=concordancer&password=concordancer', proc{})
    @lookup = Lumix::LookupSearch.new(@conc.db, nil)
    @text = TaggedText.create(:filename => "text", :text => TEXT, :tagged => TAGGED)
    @lookup.link_text(@text)
    @lookup
  end

  def search(filter)
    f = lookup.create_filter(filter)
    results = []
    lookup.find(f) do |text, tagged|
      results << tagged.to_s
    end
    results
  end
end
RSpec.configure do |config|
  config.include Helper
end
describe Lumix::LookupFilter do

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

  it "should find word|tag pairs" do
    search('"have"|D*').should == %w[have|DMKD]
  end

  def disabled
    it "should find exclusions" do
      search('A(!UXP DNE)').should == %w[too|ADVE]
    end

    it "should find unlimited repetitions" do
      search('(AD*)+').should == ['derp|ADNE too|ADVE']
    end

    it "should find limited repetitions" do
      search('(AD*){3}').should == []
      search('(AD*){2}').should == ['derp|ADNE too|ADVE']
    end
  end
end
