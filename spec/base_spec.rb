require File.dirname(__FILE__) + '/spec_helper.rb'

class Person < ActiveCouch::Base
  has :name, :which_is => :text
end

class NamedPerson < ActiveCouch::Base
  has :name, :which_is => :text, :with_default_value => "McLovin"
end

class AgedPerson < ActiveCouch::Base
  has :name
  has :age, :which_is => :number, :with_default_value => 10
end

class Contact < ActiveCouch::Base
  has_many :people
end

class Comment < ActiveCouch::Base
  has :body
end

class Blog < ActiveCouch::Base
  has :title
  has_many :comments
end

describe "A class which is a subclass of ActiveCouch::Base" do
  before(:each) do
    @p = Person.new
  end
  
  it "should have an instance variable called attributes which is a Hash with the key being :name" do
    Person.attributes.class.should == Hash
    Person.attributes.keys.should == [:name]
  end
  
  it "should have a method called name which returns the value of the variable name" do
    @p.should respond_to(:name)
    @p.name.should == ""
  end
  
  it "should have a method called name= which should let you set the instance variable name" do
    @p.should respond_to(:name=)
    @p.name = "McLovin"
    @p.name.should == "McLovin"
  end
end

describe "A class which is a subclass of ActiveCouch::Base with a default value specified" do
  before(:each) do
    @n = NamedPerson.new
  end
  
  it "should have an instance variable called attributes which is a Hash with the key being :name" do
    NamedPerson.attributes.class.should == Hash
    NamedPerson.attributes.keys.should == [:name]
  end
  
  it "should have a method called name which returns the value of the variable name" do
    @n.should respond_to(:name)
    @n.name.should == "McLovin"
  end
  
  it "should have a method called name= which should let you set the instance variable name" do
    @n.should respond_to(:name=)
    @n.name = "Seth"
    @n.name.should == "Seth"
  end
end

describe "A class which is a subclass of ActiveCouch::Base with a default numerical value specified" do
  before(:each) do
    @a = AgedPerson.new
  end

  it "should have an instance variable called attributes which is a Hash with the keys being :name, :age" do
    AgedPerson.attributes.class.should == Hash
    AgedPerson.attributes.keys.index(:name).should_not == nil
    AgedPerson.attributes.keys.index(:age).should_not == nil
  end

  it "should have methods called name and age which return the values of the variables name and age respectively" do
    @a.should respond_to(:name)
    @a.should respond_to(:age)

    @a.name.should == ""
    @a.age.should == 10
  end

  it "should have a method called name= which should let you set the instance variable name" do
    @a.should respond_to(:name=)
    @a.should respond_to(:age=)
    
    @a.age = 15
    @a.age.should == 15
  end
end

describe "A class which is a subclass of ActiveCouch::Base with a has_many association" do
  before(:each) do
    @c = Contact.new
    @p1 = Person.new
    @a1 = AgedPerson.new
  end
  
  it "should have an instance variable called associations which is a Hash with the key being :people" do
    Contact.associations.class.should == Hash
    Contact.associations.keys.should == [:people]
  end
  
  it "should have methods called people and add_person" do
    @c.should respond_to(:people)
    @c.should respond_to(:add_person)
  end
  
  it "should have a method called people which returns an empty array" do
    @c.people.should == []
  end
  
  it "should be able to add a Person object to the association" do
    @c.add_person(@p1)
    @c.people.should == [@p1]
  end
  
  it "should raise an error when trying to add an object which is not of the association's type" do
    lambda{ @c.add_person(@a1) }.should raise_error(ActiveCouch::InvalidCouchTypeError)
  end
end

describe "An object instantiated from class which is a subclass of ActiveCouch::Base" do
  before(:each) do
    @comment1 = Comment.new(:body => "I can haz redbull?")
    @comment2 = Comment.new(:body => 'k thx bai')
    @blog = Blog.new(:title => 'Lolcats Primer', :comments => [@comment1, @comment2])
    @blog1 = Blog.new(:title => 'Lolcats Primer The Sequel', :comments => [{:body => 'can'}, {:body => 'haz'}])
  end
  
  it "should be able to initialize with a hash which contains descendents of ActiveCouch::Base" do
    @comment1.body.should == "I can haz redbull?"
    @comment2.body.should == "k thx bai"
    
    @blog.title.should == 'Lolcats Primer'
    @blog.comments.should == [@comment1, @comment2]
  end
  
  it "should be able to initialize from a hash which contains only Strings" do
    @blog1.title.should == 'Lolcats Primer The Sequel'
    
    comment_bodies = @blog1.comments.collect{|c| c.body }
    comment_bodies.sort!
    
    comment_bodies.first.should == 'can'
    comment_bodies.last.should == 'haz'
  end
  
end


describe "A subclass of ActiveCouch::Base object which has called establish_connection" do
  before(:each) do
    class Cat < ActiveCouch::Base
      establish_connection :server => '192.168.0.150', :port => '7777'
    end
  end  

  after(:each) do
    # Remove class definition so we can start fresh in each spec.
    Object.send(:remove_const, :Cat)
  end
    
  it "should have the method connection" do
    Cat.methods.index('connection').should_not == nil
    Cat.connection.server.should == '192.168.0.150'
    Cat.connection.port.should == '7777'
  end
end

describe "An object instantiated from a subclass of ActiveCouch::Base which has called establish_connection" do
  before(:each) do
    class Cat < ActiveCouch::Base
      establish_connection :server => '192.168.0.150', :port => '7777'
    end
    @cat = Cat.new
  end
  
  after(:each) do
    # Remove class definition so we can start fresh in each spec.
    Object.send(:remove_const, :Cat)
  end
  
  
  it "should have the method connection in objects instantiated from the subclass" do
    @cat.methods.index('connection').should_not == nil
    @cat.connection.server.should == '192.168.0.150'
    @cat.connection.port.should == '7777'
  end
end
  


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

  it "should have a base_class of the parent" do
    Child.base_class.should == Parent
  end

  it "should have a database_name of the parent's" do
    Child.database_name.should == 'parents'
  end
end

describe "A Cheezburger subclass of ActiveCouch::Base defined in the Burgers module" do
  before(:all) do
    module Burgers
      class Cheezburger < ActiveCouch::Base
      end
    end
  end

  it "should have a base_class of Burgers::Cheezburger" do
    Burgers::Cheezburger.base_class.should == Burgers::Cheezburger
  end

  it "should have a database_name of cheezburgers" do
    Burgers::Cheezburger.database_name.should == 'cheezburgers'
  end
end

describe "A Cheezburger subclass of ActiveCouch::Base nested in a Lolcat subclass of ActiveCouch::Base" do
  before(:all) do
    class Lolcat < ActiveCouch::Base
      class Cheezburger < ActiveCouch::Base
      end
    end
  end

  it "should have a base_class of Lolcat::Cheezburger" do
    Lolcat.base_class.should == Lolcat
    Lolcat::Cheezburger.base_class.should == Lolcat::Cheezburger
  end

  it "should have a database_name of lolcat_cheezburger" do
    Lolcat::Cheezburger.database_name.should == 'lolcat_cheezburgers'
  end
end