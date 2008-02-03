require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "ActiveCouch::Base #new method with a hash containing one key-value pair" do
  before(:all) do
    class Person < ActiveCouch::Base
      has :name
    end
  end

  after(:all) do
    Object.send(:remove_const, :Person)
  end  

  it "should be able to initialize attributes correctly from a hash" do
    p = Person.new(:name => 'McLovin')
    p.name.should == 'McLovin'
  end
end

describe "ActiveCouch::Base #new method with a hash containing more than one key-value pair" do
  before(:all) do
    class Person < ActiveCouch::Base
      has :name
      has :age, :which_is => :number, :with_default_value => 25
    end
  end
  
  after(:all) do
    Object.send(:remove_const, :Person)
  end  
  
  it "should be able to initialize attributes correctly from the hash" do
    p = Person.new(:name => 'McLovin', :age => 12)
    p.name.should == 'McLovin'
    p.age.should == 12
  end
end

describe "ActiveCouch::Base #new method with a hash containing a CouchDB reserved attribute" do
  before(:all) do
    class Person < ActiveCouch::Base
      has :name
    end
  end
  
  after(:all) do
    Object.send(:remove_const, :Person)
  end  
  
  it "should be able to initialize attributes correctly, including CouchDB reserved attributes" do
    p = Person.new(:name => 'McLovin', :id => '123')
    p.name.should == 'McLovin'
    p.id.should == '123'
  end
end

describe "ActiveCouch::Base #new method with a block (and self being passed to the block)" do
  before(:all) do
    class Dog < ActiveCouch::Base
      has :name
      has :age, :which_is => :number
      has :collar
    end
  end
  
  after(:all) do
    Object.send(:remove_const, :Dog)
  end
  
  it "should be able to initialize all the attributes correctly" do
    dog = Dog.new do |d|
      d.name = "Buster"
      d.age = 2
      d.collar = "Stray"
    end
    
    dog.name.should == "Buster"
    dog.age.should == 2
    dog.collar.should == "Stray"
  end
  
  it "should be able to initialize all attributes (including CouchDB reserved attributes)" do
    dog = Dog.new do |d|
      d.name = "Spike"
      d.id = 'underdog_1'
    end
    
    dog.name.should == "Spike"
    dog.id.should == 'underdog_1'
  end
end