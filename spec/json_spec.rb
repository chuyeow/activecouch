require File.dirname(__FILE__) + '/spec_helper.rb'

class Hotel < ActiveCouch::Base
  has :name, :which_is => :text, :with_default_value => "Swissotel The Stamford"
  has :star_rating, :which_is => :decimal, :with_default_value => 5.0
  has :rooms, :which_is => :number, :with_default_value => 100
end

class Hospital < ActiveCouch::Base
  has :name
end

class CrazyPerson < ActiveCouch::Base
  has :name, :which_is => :text, :with_default_value => "Crazed McLovin"
  has_many :hospitals
end

describe "An object instantiated from a subclass of ActiveCouch::Base with many attributes" do
  before(:each) do
    @h = Hotel.new
  end

  it "should have to the to_json method" do
    @h.methods.index('to_json').should_not == nil
  end

  it "should produce valid JSON output when sent the to_json method" do
    @h.to_json.should == "{\"name\":\"Swissotel The Stamford\",\"rooms\":100,\"star_rating\":5.0}"
  end
  
  it "should produce valid JSON output when an attribute has been changed and the to_json method is sent" do
    @h.rooms = 200
    @h.to_json.should == "{\"name\":\"Swissotel The Stamford\",\"rooms\":200,\"star_rating\":5.0}"
  end
end

describe "An object instantiated from a subclass of ActiveCouch::Base with a has_many association" do
  before(:each) do
    @c = CrazyPerson.new
    @h1 = Hospital.new
    @h1.name = "Crazy Hospital 1"
    
    @h2 = Hospital.new
    @h2.name = "Crazy Hospital 2"
    
    @c.add_hospital(@h1)
    @c.add_hospital(@h2)
  end
  
  it "should produce valid JSON when sent the to_json method" do
    @c.to_json.should == "{\"name\":\"Crazed McLovin\",\"hospitals\":[\"{\\\"name\\\":\\\"Crazy Hospital 1\\\"}\",\"{\\\"name\\\":\\\"Crazy Hospital 2\\\"}\"]}"
  end
end