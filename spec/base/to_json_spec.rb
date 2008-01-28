require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "ActiveCouch::Base #to_json method with just simple attributes" do
  before(:each) do
    class Hotel < ActiveCouch::Base
      has :name, :which_is => :text, :with_default_value => "Swissotel The Stamford"
      has :star_rating, :which_is => :decimal, :with_default_value => 5.0
      has :rooms, :which_is => :number, :with_default_value => 100
    end
    
    @h = Hotel.new
  end

  after(:each) do
    Object.send(:remove_const, :Hotel)
  end  

  it "should have to the to_json method" do
    @h.should respond_to(:to_json)
  end

  it "should produce valid JSON output when sent the to_json method" do
    json_output = @h.to_json
    # Check for JSON regex, since attributes can appear in any order
    (json_output =~ /"name":"Swissotel The Stamford"/).should_not == nil
    (json_output =~ /"rooms":100/).should_not == nil
    (json_output =~ /"star_rating":5.0/).should_not == nil    
  end
  
  it "should produce valid JSON output when an attribute has been changed and the to_json method is sent" do
    @h.rooms = 200
    json_output = @h.to_json
    # Check for JSON regex, since attributes can appear in any order
    (json_output =~ /"name":"Swissotel The Stamford"/).should_not == nil
    (json_output =~ /"rooms":200/).should_not == nil
    (json_output =~ /"star_rating":5.0/).should_not == nil    
  end
end

describe "ActiveCouch::Base #to_json with associations" do
  before(:each) do
    class Hospital < ActiveCouch::Base
      has :name
    end

    class CrazyPerson < ActiveCouch::Base
      has :name, :which_is => :text, :with_default_value => "Crazed McLovin"
      has_many :hospitals
    end

    @c = CrazyPerson.new

    @h1 = Hospital.new(:name => "Crazy Hospital 1")
    @h2 = Hospital.new(:name => "Crazy Hospital 2")

    @c.add_hospital(@h1)
    @c.add_hospital(@h2)
  end

  after(:each) do
    Object.send(:remove_const, :Hospital)
    Object.send(:remove_const, :CrazyPerson)
  end  

  it "should produce valid JSON when sent the to_json method" do
    json_output = @c.to_json
    # Check for JSON regex, since attributes can appear in any order
    (json_output =~ /"name":"Crazed McLovin"/).should_not == nil
    (json_output =~ /"hospitals":\[.*?\]/).should_not == nil
    (json_output =~ /\{.*?"name":"Crazy Hospital 1".*?\}/).should_not == nil
    (json_output =~ /\{.*?"name":"Crazy Hospital 2".*?\}/).should_not == nil    
  end
end