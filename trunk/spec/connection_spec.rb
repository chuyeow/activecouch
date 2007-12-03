require File.dirname(__FILE__) + '/spec_helper.rb'

def initialize_connection(spec = nil)
  begin
  @connection = ActiveCouch::Connection.new(spec)
  rescue
  @error = $!.to_s
  end
  return @connection, @error
end


describe ActiveCouch::Connection do
  before(:each) do
    @connection, @error = initialize_connection(:server => '192.168.0.150', :port => '7777')
  end
  
  it "should set the server and port for the connection object and there must be no error" do
    @connection.server.should == "192.168.0.150"
    @connection.port.should == "7777"
    @error.should == nil
  end
end

describe "An ActiveCouch::Connection object instantiated with no options specified" do
  before(:each) do
    @connection, @error = initialize_connection()
  end
  
  it "should raise an error and return nil" do
    @connection.should == nil
    @error.should == "Configuration hash must contain keys for server and port"
  end
end

describe "An ActiveCouch::Connection object instantiated with only the server option specified" do
  before(:each) do
    @connection, @error = initialize_connection(:server => '192.168.0.150')
  end
  
  it "should raise an error and return nil" do
    @connection.should == nil
    @error.should == "Configuration hash must contain keys for server and port"
  end
end

describe "An ActiveCouch::Connection object instantiated with only the port option specified" do
  before(:each) do
    @connection, @error = initialize_connection(:port => '7777')
  end

  it "should raise an error and return nil" do
    @connection.should == nil
    @error.should == "Configuration hash must contain keys for server and port"
  end
end