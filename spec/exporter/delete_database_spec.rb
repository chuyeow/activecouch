require File.dirname(__FILE__) + '/../spec_helper.rb'

describe ActiveCouch::Exporter, "#delete_database with site and name" do
  before(:each) do
    @conn = mock(ActiveCouch::Connection)
    @response = mock(Object, :code => '202')
  end

  def mock_connection_and_response(options = {})
    ActiveCouch::Connection.should_receive(:new).with(options[:site]).and_return(@conn)
    @conn.should_receive(:delete).with("/#{options[:database_name]}").and_return(@response)
  end

  it "should create a new Connection to the given site and send a DELETE with the database name" do
    ActiveCouch::Connection.should_receive(:new).with('http://test.host:5984/').and_return(@conn)
    @conn.should_receive(:delete).with('/delete_me').and_return(@response)

    ActiveCouch::Exporter.delete_database('http://test.host:5984/', 'delete_me')
  end

  it "should return true if the response code is HTTP status 202" do 
    mock_connection_and_response(:site => 'http://test.host:5984/', :database_name => 'delete_me')
    @response.should_receive(:code).and_return('202')

    ActiveCouch::Exporter.delete_database('http://test.host:5984/', 'delete_me').should == true
  end

  it "should raise an ActiveCouch::ViewError if the response code is not HTTP status 202" do
    mock_connection_and_response(:site => 'http://test.host:5984/', :database_name => 'delete_me')
    @response.should_receive(:code).any_number_of_times.and_return('500')

    lambda {
      ActiveCouch::Exporter.delete_database('http://test.host:5984/', 'delete_me')
    }.should raise_error(ActiveCouch::ViewError)
  end

  it "should raise an ActiveCouch::ViewError with a 'Database does not exist' message if the response code is HTTP status 404" do
    mock_connection_and_response(:site => 'http://test.host:5984/', :database_name => 'delete_me')
    @response.should_receive(:code).any_number_of_times.and_return('404')

    lambda {
      ActiveCouch::Exporter.delete_database('http://test.host:5984/', 'delete_me')
    }.should raise_error(ActiveCouch::ViewError, "Database 'delete_me' does not exist")
  end
end