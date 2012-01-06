$: << File.expand_path('../../lib', __FILE__)

require 'lumix/text_snippet'

describe Lumix::TextSnippet do
  before(:each) do
  end

  it "should handle umlauts properly" do
    ts = create_ts('eins zwei drei vierß öfünfä ßechs sieben acht neun zehn', /öfünfä/)
    ts.left(3).should == 'zwei drei vierß '
    ts.to_s.should == 'öfünfä'
    ts.right(3).should == ' ßechs sieben acht'
  end

  it "should handle partial words and umlauts properly" do
    ts = create_ts('eins zwei drei vierß öfünfä ßechs sieben acht neun zehn', /fünf/)
    ts.left(3).should == 'zwei drei vierß ö'
    ts.to_s.should == 'fünf'
    ts.right(3).should == 'ä ßechs sieben acht'
  end

  it "should have dynamic left context" do
    ts = create_ts('one two three four five six seven eight nine ten', /five/)
    ts.left(1).should == 'four '
    ts.left(2).should == 'three four '
    ts.left(10).should == 'one two three four '
  end

  it "should have dynamic right context" do
    ts = create_ts('one two three four five six seven eight nine ten', /five/)
    ts.right(1).should == ' six'
    ts.right(2).should == ' six seven'
    ts.right(10).should == ' six seven eight nine ten'
  end

  it "should work correctly with newlines" do
    ts = create_ts("one two\n three four five six seven eight\n nine ten", /five/)
    ts.left(1).should == 'four '
    ts.right(1).should == ' six'
  end

  it "should replace newlines and tabs with spaces" do
    ts = create_ts("one two three\n four five six\n\t seven eight nine ten", /five/)
    ts.left(2).should == 'three four '
    ts.right(2).should == ' six seven'
  end

end

def create_ts(text, re)
  @count ||= 0
  m = text.match(re)
  Lumix::TextSnippet.new "text#{@count += 1}", text, m.begin(0), m.end(0)
end
