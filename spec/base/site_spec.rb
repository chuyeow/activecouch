require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "A subclass of ActiveCouch::Base object which has called establish_connection" do
  before(:all) do
    class Cat < ActiveCouch::Base
      site 'http://192.168.0.150:7777'
    end
  end  

  after(:all) do
    # Remove class definition so we can start fresh in each spec.
    Object.send(:remove_const, :Cat)
  end
    
  it "should have the method connection" do
    Cat.methods.index('connection').should_not == nil
    Cat.connection.site.host.should == '192.168.0.150'
    Cat.connection.site.port.should == 7777
  end
end

describe "An object instantiated from a subclass of ActiveCouch::Base which has called establish_connection" do
  before(:all) do
    class Cat < ActiveCouch::Base
      site 'http://192.168.0.150'
    end
    @cat = Cat.new
  end
  
  after(:all) do
    # Remove class definition so we can start fresh in each spec.
    Object.send(:remove_const, :Cat)
  end
  
  
  it "should have the method connection in objects instantiated from the subclass" do
    @cat.methods.index('connection').should_not == nil
    @cat.connection.site.host.should == '192.168.0.150'
    @cat.connection.site.port.should == 5984
  end
end


describe "If the site is set in ActiveCouch::Base, all instances and all subclasses of ActiveCouch::Base should inherit it" do
  before(:all) do
    ActiveCouch::Base.send('site', 'http://localhost.site:5984')
    class P < ActiveCouch::Base; end
    @p = P.new
  end
  
  after(:all) do
    Object.send(:remove_const, :P)
  end
  
  it "should be reflected in @p and P" do
    P.instance_variable_get('@connection').should_not == nil
    @p.methods.index('connection').should_not == nil
    @p.connection.site.host.should == 'localhost.site'
    @p.connection.site.port.should == 5984
  end
end
  