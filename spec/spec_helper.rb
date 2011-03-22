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
  @response = mock("response_data")
  @response.stub!(:body_str).and_return(test_leads) 
  @response.stub!(:header_str).and_return("200 OK")
  Curl::Easy.stub!(:perform).and_return(@response)
end

def stub_leads_find_by_guid
  @response = mock("response_data")
  @response.stub!(:body_str).and_return(test_lead) 
  @response.stub!(:header_str).and_return("200 OK")
  Curl::Easy.stub!(:perform).and_return(@response)
end

def stub_leads_error
  @response = mock("response_data")
  @response.stub!(:body_str).and_return(test_error) 
  @response.stub!(:header_str).and_return("404")
  Curl::Easy.stub!(:perform).and_return(@response)
end

def stub_lead_update
  @response_mock = mock("data")
  @response_mock.stub!(:body_str).and_return("200 OK") 
  @response_mock.stub!(:header_str).and_return("200 OK")
  Curl::Easy.stub!(:http_put).and_return(@response_mock)
end

def stub_lead_update_error
  @response_mock = mock("data")
  @response_mock.stub!(:header_str).and_return("500")
  @response_mock.stub!(:body_str).and_return("Error: 500 internal server error.") 
  Curl::Easy.stub!(:http_put).and_return(@response_mock)
end

