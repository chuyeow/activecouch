require File.dirname(__FILE__) + '/../spec_helper.rb'

describe ActiveCouch::Migrator, "#create_database with site and name" do
  before(:each) do
    @conn = mock(ActiveCouch::Connection)
  end

  def mock_connection_and_response(options = {})
    ActiveCouch::Connection.should_receive(:new).with(options[:site]).and_return(@conn)
    @conn.should_receive(:put).with("/#{options[:database_name]}", '{}').and_return(@response)
  end

  it "should create a new Connection to the given site and send a PUT with the database name" do
    @response = mock(Object, :code => '201')

    # Mock and place expectations on the the connection and response out explicitly instead of using
    # mock_connection_and_response so that it's clearer what we're testing in this spec.
    ActiveCouch::Connection.should_receive(:new).with('http://test.host:5984/').and_return(@conn)
    @conn.should_receive(:put).with('/test', '{}').and_return(@response)

    ActiveCouch::Migrator.create_database('http://test.host:5984/', 'test')
  end

  it "should return true if the response code is HTTP status 201" do 
    mock_connection_and_response(:site => 'http://test.host:5984/', :database_name => 'test')
    @response.should_receive(:code).and_return('201')

    ActiveCouch::Migrator.create_database('http://test.host:5984/', 'test').should == true
  end

  it "should raise an ActiveCouch::MigrationError if the response code is not HTTP status 201" do
    mock_connection_and_response(:site => 'http://test.host:5984/', :database_name => 'test')
    @response.should_receive(:code).any_number_of_times.and_return('500')

    lambda {
      ActiveCouch::Migrator.create_database('http://test.host:5984/', 'test')
    }.should raise_error(ActiveCouch::MigrationError)
  end

  it "should raise an ActiveCouch::MigrationError with a 'Database exists' message if the response code is HTTP status 409" do
    mock_connection_and_response(:site => 'http://test.host:5984/', :database_name => 'test')
    @response.should_receive(:code).any_number_of_times.and_return('409')

    lambda {
      ActiveCouch::Migrator.create_database('http://test.host:5984/', 'test')
    }.should raise_error(ActiveCouch::MigrationError, 'Database exists')
  end
end