require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RHapi::Lead" do
  
  context "when searching for leads" do
    before do
     RHapi.configure do |config|
        config.api_key = test_config["api_key"]
        config.hub_spot_site = "http://mysite.hubspot.com"
      end
    end
    
    # Most of the actual connections are mocked to spped tests.
    it "should return all leads with no search params" do
      leads = RHapi::Lead.find
      leads.length.should >= 1
      name = leads.first.first_name
      name.should == "Adam"
      #leads.first["firstName"].should == "Adam"
    end
  end
end
