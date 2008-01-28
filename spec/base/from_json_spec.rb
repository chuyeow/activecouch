require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "ActiveCouch::Base #from_json method, with many attributes" do
  before(:all) do
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
  end
  
  after(:all) do
    Object.send(:remove_const, :Hotel)
    Object.send(:remove_const, :Hospital)
    Object.send(:remove_const, :CrazyPerson)
  end  
  
  it "should have the from_json method" do
    Hotel.should respond_to(:from_json)
    Hospital.should respond_to(:from_json)
    CrazyPerson.should respond_to(:from_json)
  end
  
  it "should instantiate an object when sent the from_json method with valid json as a parameter" do
    h = Hotel.from_json("{\"name\":\"Swissotel The Stamford\",\"rooms\":200,\"star_rating\":4.0}")
    h.class.should == Hotel
    # Check whether all attributes are set correctly
    h.name.should == "Swissotel The Stamford"
    h.rooms.should == 200
    h.star_rating.should == 4.0
  end
  
  it "should instantiate an object when sent the from_json method with valid JSON (containing associations) as a parameter" do
    crazy = CrazyPerson.from_json('{"name":"Crazed McLovin","hospitals":[{"name":"Crazy Hospital 1"},{"name":"Crazy Hospital 2"}]}')

    crazy.name == "Crazed McLovin"
    crazy.hospitals.size.should == 2
    
    hospitals = crazy.hospitals.collect{|h| h.name }
    hospitals.sort!
    
    hospitals.first.should == 'Crazy Hospital 1'
    hospitals.last.should == 'Crazy Hospital 2'
  end
end