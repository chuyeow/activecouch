require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "ActiveCouch::Base #marshal_dump method with just simple attributes" do
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

  it "should have to the marshal_dump method" do
    @h.should respond_to(:marshal_dump)
  end

  it "should produce valid JSON output when sent the marshal_dump method" do
    marshal_dump = @h.marshal_dump
    # Check for JSON regex, since attributes can appear in any order
    (marshal_dump =~ /"name":"Swissotel The Stamford"/).should_not == nil
    (marshal_dump =~ /"rooms":100/).should_not == nil
    (marshal_dump =~ /"star_rating":5.0/).should_not == nil    
  end
  
  it "should produce valid JSON output when an attribute has been changed and the marshal_dump method is sent" do
    @h.rooms = 200
    marshal_dump = @h.marshal_dump
    # Check for JSON regex, since attributes can appear in any order
    (marshal_dump =~ /"name":"Swissotel The Stamford"/).should_not == nil
    (marshal_dump =~ /"rooms":200/).should_not == nil
    (marshal_dump =~ /"star_rating":5.0/).should_not == nil    
  end
end

describe "ActiveCouch::Base #marshal_dump with associations" do
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

  it "should produce valid JSON when sent the marshal_dump method" do
    marshal_dump = @c.marshal_dump
    # Check for JSON regex, since attributes can appear in any order
    (marshal_dump =~ /"name":"Crazed McLovin"/).should_not == nil
    (marshal_dump =~ /"hospitals":\[.*?\]/).should_not == nil
    (marshal_dump =~ /\{.*?"name":"Crazy Hospital 1".*?\}/).should_not == nil
    (marshal_dump =~ /\{.*?"name":"Crazy Hospital 2".*?\}/).should_not == nil    
  end
end