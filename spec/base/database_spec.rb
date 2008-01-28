require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "A direct subclass of ActiveCouch::Base" do

  before(:each) do
    class Foo < ActiveCouch::Base
    end
  end

  after(:each) do
    # Remove class definition so we can start fresh in each spec.
    Object.send(:remove_const, :Foo)
  end

  it "should have a base_class of itself" do
    Foo.base_class.should == Foo
  end

  it "should infer the database name from the class name" do
    Foo.database_name.should == 'foos'
  end

  it "should use the database name set with the set_database_name macro" do
    Foo.set_database_name('legacy_foo')

    Foo.database_name.should == 'legacy_foo'
  end

  it "should have an database_name= alias for set_database_name" do
    Foo.database_name = 'fubar'

    Foo.database_name.should == 'fubar'
  end

  it "should set an attribute from a value with define_attr_method" do
    Foo.define_attr_method(:database_name, 'defined_foo')

    Foo.database_name.should == 'defined_foo'
  end

  it "should set an attribute from a block with define_attr_method" do
    Foo.send(:define_attr_method, :database_name) { 'legacy_' + original_database_name }

    Foo.database_name.should == 'legacy_foos'
  end
end

describe "A subclass of ActiveCouch::Base that's a subclass of an ActiveCouch::Base subclass" do

  before(:all) do
    class Parent < ActiveCouch::Base
    end

    class Child < Parent
    end
  end

  after(:all) do
    Object.send(:remove_const, :Parent)
    Object.send(:remove_const, :Child)
  end

  it "should have a base_class of the parent" do
    Child.base_class.should == Parent
  end

  it "should have a database_name of the parent's" do
    Child.database_name.should == 'parents'
  end
end