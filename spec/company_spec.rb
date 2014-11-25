require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Company" do
  before do
    RHapi.configure do |config|
      config.api_key = test_config["api_key"]
      config.hub_spot_site = "http://mysite.hubspot.com"
    end
  end
  describe "creating a company" do
    before do
      @name = 'The Nice Co'
      @company = RHapi::Company.create({name: @name, description: 'Yes'})
    end
    it "should have a companyId" do
      @company.company_id.should be_a(Fixnum)
    end
    it "should have a name" do
      @company.name.should == @name
    end
    describe "getting a company" do
      before do
        @company = RHapi::Company.find_by_company_id(@company.company_id)
      end
      it "should have a companyId" do
        @company.company_id.should be_a(Fixnum)
      end
      it "should have a name" do
        @company.name.should == @name
      end
      describe "updating the company" do
        before do
          @new_name = 'The New Co Name'
          @company.name = @new_name
          @company.save
        end
        it "should have new name" do
          RHapi::Company.find_by_company_id(@company.company_id).name.should == @new_name
        end
      end
      describe "and deleting it again" do
        before do
          @company.delete
        end
        it "should throw 404" do
          lambda {RHapi::Company.find_by_company_id(@company.company_id)}.should raise_error(RHapi::ConnectionError)
        end
      end
    end
  end
end
