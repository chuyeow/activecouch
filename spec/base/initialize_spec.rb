require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "ActiveCouch::Base #new method with a hash containing one key-value pair" do
  before(:each) do
    class Person < ActiveCouch::Base
      has :name
    end
  end

  it "should be able to initialize attributes correctly from a hash" do
    p = Person.new(:name => 'McLovin')
    p.name.should == 'McLovin'
  end
end

describe "ActiveCouch::Base #new method with a hash containing more than one key-value pair" do
  before(:each) do
    class Person < ActiveCouch::Base
      has :name
      has :age, :which_is => :number, :with_default_value => 25
    end
  end
  
  it "should be able to initialize attributes correctly from the hash" do
    p = Person.new(:name => 'McLovin', :age => 12)
    p.name.should == 'McLovin'
    p.age.should == 12
  end
end

describe "ActiveCouch::Base #new method with a hash containing a CouchDB reserved attribute" do
  before(:each) do
    class Person < ActiveCouch::Base
      has :name
    end
  end
  
  it "should be able to initialize attributes correclty from the has, including CouchDB reserved attributes" do
    p = Person.new(:name => 'McLovin', :id => '123')
    p.name.should == 'McLovin'
    p.id.should == '123'
  end
end