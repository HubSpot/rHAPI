$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'r_hapi'
require 'yaml'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  
end

def test_config
  YAML::load( File.open( 'spec/config.yml' ) )
end

def test_leads
  IO.read( 'spec/fixtures/leads.json' )
end

def test_lead
  IO.read( 'spec/fixtures/lead.json' )
end

def test_error
  IO.read( 'spec/fixtures/error.html' )
end

def stub_leads_search
  @data = mock("data")
  @data.stub!(:body_str).and_return(test_leads) 
  Curl::Easy.stub!(:perform).and_return(@data)
end

def stub_leads_find_by_guid
  @data = mock("data")
  @data.stub!(:body_str).and_return(test_lead) 
  Curl::Easy.stub!(:perform).and_return(@data)
end

def stub_leads_error
  @data = mock("data")
  @data.stub!(:body_str).and_return(test_error) 
  Curl::Easy.stub!(:perform).and_return(@data)
end

def stub_lead_update
  @response_mock = mock("data")
  @response_mock.stub!(:body_str).and_return("200 OK") 
  Curl::Easy.stub!(:http_put).and_return(@response_mock)
end

def stub_lead_update_error
  @response_mock = mock("data")
  @response_mock.stub!(:body_str).and_return("Error: 500 internal server error.") 
  Curl::Easy.stub!(:http_put).and_return(@response_mock)
end

