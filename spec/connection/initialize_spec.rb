require File.dirname(__FILE__) + '/../spec_helper.rb'

describe ActiveCouch::Connection do
  it "should set the site for the connection object and there must be no error" do
    @connection = ActiveCouch::Connection.new('http://192.168.0.150:7777')

    @connection.site.host.should == "192.168.0.150"
    @connection.site.port.should == 7777
    @error.should == nil
  end
end

describe "An ActiveCouch::Connection object instantiated with no site specified" do
  it "should raise an ArgumentError and return nil" do
    lambda {
      @connection = ActiveCouch::Connection.new(nil)
    }.should raise_error(ArgumentError, 'Missing site URI')
  end
end

describe "An ActiveCouch::Connection object instantiated with site (with no port) specified" do
  it "should use the default CouchDB port of 5984" do
    @connection = ActiveCouch::Connection.new('http://192.168.0.150')

    @connection.site.host.should == "192.168.0.150"
    @connection.site.port.should == 5984
  end
end