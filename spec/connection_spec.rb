require File.dirname(__FILE__) + '/spec_helper.rb'

def initialize_connection(spec = nil)
  begin
  connection = ActiveCouch::Connection.new(spec)
  rescue
  error = $!.to_s
  end
  return connection, error
end

describe ActiveCouch::Connection do
  before(:each) do
    @connection, @error = initialize_connection('http://192.168.0.150:7777')
  end
  
  it "should set the site for the connection object and there must be no error" do
    @connection.site.host.should == "192.168.0.150"
    @connection.site.port.should == 7777
    @error.should == nil
  end
end

describe "An ActiveCouch::Connection object instantiated with no site specified" do
  before(:each) do
    @connection, @error = initialize_connection()
  end
  
  it "should raise an error and return nil" do
    @connection.should == nil
    @error.should == "Missing site URI"
  end
end

describe "An ActiveCouch::Connection object instantiated with site (with no port) specified" do
  before(:each) do
    @connection, @error = initialize_connection('http://192.168.0.150')
  end
  
  it "should raise an error and return nil" do
    @connection.site.host.should == "192.168.0.150"
    @connection.site.port.should == 5984
    @error.should == nil
  end
end