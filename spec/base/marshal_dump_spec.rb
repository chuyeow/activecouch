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
    @h.stub!(:to_json).and_return("Deflated JSON")
    @h.marshal_dump.should == 'Deflated JSON'
  end
  
  it "should produce valid JSON output when an attribute has been changed and the marshal_dump method is sent" do
    @h.rooms = 200
    @h.stub!(:to_json).and_return("Deflated JSON, Part deux")
    @h.marshal_dump.should == 'Deflated JSON, Part deux'
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
    # Stub the deflate method, which will basically give us the gzip'd JSON 
    @c.stub!(:to_json).and_return("Deflated JSON, Part three")
    @c.marshal_dump.should == 'Deflated JSON, Part three'
  end
end