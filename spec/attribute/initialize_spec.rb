require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "An ActiveCouch::Attribute object initialized with no options" do
  before(:each) do
    @att = ActiveCouch::Attribute.new(:name)
  end
  
  it "should set the type to String and value to an empty String" do
    @att.klass.should == String
    @att.value.should == ""
    @att.name.should == "name"
  end
end

describe "An ActiveCouch::Attribute object initialized with a type :text but no default value" do
  before(:each) do
    @att = ActiveCouch::Attribute.new(:name, :which_is => :text)
  end
  
  it "should set the type to String and value to an empty String" do
    @att.klass.should == String
    @att.value.should == ""
    @att.name.should == "name"
  end
end

describe "An ActiveCouch::Attribute object initialized with a type :decimal but no default value" do
  before(:each) do
    @att = ActiveCouch::Attribute.new(:amount, :which_is => :decimal)
  end
  
  it "should set the type to Float and value to 0.0" do
    @att.klass.should == Float
    @att.value.should == 0.0
    @att.name.should == "amount"
  end
end

describe "An ActiveCouch::Attribute object initialized with a type :number but no default value" do
  before(:each) do
    @att = ActiveCouch::Attribute.new(:age, :which_is => :number)
  end
  
  it "should set the type to Integer and value to 0" do
    @att.klass.should == Integer
    @att.value.should == 0
    @att.name.should == "age"
  end
end

describe "An ActiveCouch::Attribute object initialized with type :text and with a default value" do
  before(:each) do
    @att = ActiveCouch::Attribute.new(:name, :which_is => :text, :with_default_value => "Hotel")
  end
  
  it "should set the type to String and value to Hotel" do
    @att.klass.should == String
    @att.value.should == "Hotel"
    @att.name.should == "name"
  end
end

describe "An ActiveCouch::Attribute object initialized with type :decimal and with a default value" do
  before(:each) do
    @att = ActiveCouch::Attribute.new(:star_rating, :which_is => :decimal, :with_default_value => 4.5)
  end
  
  it "should set the type to Float and value to 4.5" do
    @att.klass.should == Float
    @att.value.should == 4.5
    @att.name.should == "star_rating"
  end
end

describe "An ActiveCouch::Attribute object initialized with type :number and with a default value" do
  before(:each) do
    @att = ActiveCouch::Attribute.new(:marks, :which_is => :number, :with_default_value => 100)
  end
  
  it "should set the klass to Integer and value to 100" do
    @att.klass.should == Integer
    @att.value.should == 100
    @att.name.should == "marks"
  end
end

describe "An ActiveCouch::Attribute object initialized with a certain type and with a value which is not of that type" do
  
  it "should raise an InvalidCouchTypeError with type String and value which is not string" do
    lambda { ActiveCouch::Attribute.new(:x, :which_is => :text, :with_default_value => 100) }.should raise_error(ActiveCouch::InvalidCouchTypeError)
  end

  it "should raise an InvalidCouchTypeError with type Number and value which is not Number" do
    lambda { ActiveCouch::Attribute.new(:x, :which_is => :number, :with_default_value => "abc") }.should raise_error(ActiveCouch::InvalidCouchTypeError)
  end

  it "should raise an InvalidCouchTypeError with type Number and value which is not Number" do
    lambda { ActiveCouch::Attribute.new(:x, :which_is => :number, :with_default_value => 3.0) }.should raise_error(ActiveCouch::InvalidCouchTypeError)
  end

  it "should raise an InvalidCouchTypeError with type Decimal and value which is not Decimal" do
    lambda { ActiveCouch::Attribute.new(:x, :which_is => :number, :with_default_value => []) }.should raise_error(ActiveCouch::InvalidCouchTypeError)
  end
  
  it "should raise an InvalidCouchTypeError for an unsupported type" do
    lambda { ActiveCouch::Attribute.new(:x, :which_is => :array) }.should raise_error(ActiveCouch::InvalidCouchTypeError)
  end
  
end

describe "An ActiveCouch::Attribute object initialized with a certain type must be able to assign values" do
  before(:each) do
    @a = ActiveCouch::Attribute.new(:a, :which_is => :text)
    @b = ActiveCouch::Attribute.new(:b, :which_is => :number)
    @c = ActiveCouch::Attribute.new(:c, :which_is => :decimal)
  end
  
  it "should set the value correctly if it is of the right type" do
    @a.value = "McLovin"
    @a.value.should == "McLovin"
    @a.name.should == "a"
    
    @b.value = 100
    @b.value.should == 100
    @b.name.should == "b"
    
    @c.value = 5.4
    @c.value.should == 5.4
    @c.name.should == "c"
    
  end
  
  it "should raise an exception if the type is not String" do
    lambda { @a.value = 100 }.should raise_error(ActiveCouch::InvalidCouchTypeError)
    lambda { @b.value = "a" }.should raise_error(ActiveCouch::InvalidCouchTypeError)
    lambda { @c.value = [] }.should raise_error(ActiveCouch::InvalidCouchTypeError)    
  end
end