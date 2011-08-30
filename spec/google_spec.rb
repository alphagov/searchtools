require 'spec_helper'
require 'uri'

def fixture_path(path)
  File.expand_path(File.join('fixtures', path), File.dirname(__FILE__))
end
module Searchtools
describe Google do
  describe "constructing a custom search URL" do
    let :search do
      Google.new('CSE_id', :alpha, :q => "hello mum")
    end

    let :uri do
      URI.parse(search.search_url)
    end

    let :query do
      Rack::Utils.parse_query uri.query
    end

    it "points to the normal Google search endpoint" do
      uri.host.should == "www.google.com"
      uri.path.should == "/search"
    end

    it "provides an HTML-escaped-but-not-URI-escaped version of the string" do
      search.query_text.should == "hello mum"
    end

    context "the components Google demand you have" do
      it("Has correctly URI escaped the query") { search.q.should == 'hello+mum' }
      it("Has the correct CSE id") { query['cx'].should == 'CSE_id' }
      it("sets encoding to UTF8") { query['ie'].should == 'utf8' }
      it("sets host language to EN") { query['hl'].should == 'en' }
      it("sets client to google-csbe") { query['client'].should == 'google-csbe' }
      it("sets output to xml_no_dtd") { query['output'].should == 'xml_no_dtd' }
      it("sets num to 20") { query['num'].should == '20' }
    end
    # g.search_url.should == "http://www.google.com/search?q=soccer&ie=utf8&hl=en&start=10&num=10&output=xml&client=google-csbe&cx=00255077836266642015:u-scht7a-8i"
    
    describe "processing link URL into classes" do
      context "when the URL has a path component" do
        before(:each) do
          @classes = search.result_classes(URI.parse("http://www.direct.gov.uk/en/stuff"))
        end

        it "has three items" do
          @classes.length.should == 3
        end
        it "for the whole host" do
          @classes[0].should == 'www_direct_gov_uk'
        end
        it "for x.gov.uk" do
          @classes[1].should == 'direct_gov_uk'
        end
        it "for the whole host + first path segment" do
          @classes[2].should == 'www_direct_gov_uk-en'
        end
      end

      context "when the URL has no path component" do
        before(:each) do
          @classes = search.result_classes(URI.parse("http://www.direct.gov.uk/"))
        end

        it "has three items" do
          @classes.length.should == 2
        end
        it "for the whole host" do
          @classes[0].should == 'www_direct_gov_uk'
        end
        it "for x.gov.uk" do
          @classes[1].should == 'direct_gov_uk'
        end
      end
    end
  end

  describe "pagination params" do
    def make_query(params)
      Rack::Utils.parse_query URI.parse(Google.new('CSE_id', :alpha, params).search_url).query
    end
    
    it "allows postitive integers" do
      q = make_query(:q => "query", :start => '10')
      q.should have_key('start')
      q['start'].should == '10'
    end

    it "only allows integers" do
      q = make_query(:q => "query", :start => 'hello')
      q.should_not have_key('start')
    end

    it "only allows positive integers" do
      q = make_query(:q => "query", :start => '-20')
      q.should_not have_key('start')
    end

    it "sneakily converts positive floating point numbers" do
      q = make_query(:q => "query", :start => '20.6')
      q.should have_key('start')
      q['start'].should == '20'
    end
  end

  describe "results" do
    let :search do
      Google.new('CSE_id', :alpha, :q => "hello+mum")
    end

    describe "processing URIs into CSS classes" do
      it "can cope with a URI with path" do
        search.result_classes(URI.parse("http://www.wowsa.thing.com/path/to/stuffs.html")).should == ["www_wowsa_thing_com", "wowsa_thing_com", "www_wowsa_thing_com-path"]
      end

      it "can cope with a URI with path of /" do
        search.result_classes(URI.parse("http://www.wowsa.thing.com/")).should == ["www_wowsa_thing_com", "wowsa_thing_com"]
      end

      it "can cope with a URI with no path ''" do
        search.result_classes(URI.parse("http://www.wowsa.thing.com")).should == ["www_wowsa_thing_com", "wowsa_thing_com"]
      end
    end

    it "can extract the search results" do
      search.expects(:fetch).returns(File.open(fixture_path('search_debt.xml')))

      search.run!
      search.results.length.should == 10
    end

    describe "a 'normal' result set" do
      before(:each) do
        search.stubs(:fetch).returns(File.open(fixture_path('search_debt.xml')))
        search.run!
      end

      it "provides link URL" do
        search.results.first['url'].should == 'http://www.direct.gov.uk/en/MoneyTaxAndBenefits/ManagingDebt/index.htm'
      end

      it "provides link host" do
        search.results.first['host'].should == 'www.direct.gov.uk'
      end

      it "provides title" do
        search.results.first['title'].should == 'Managing <b>debt</b> : Directgov - Money, tax and benefits'
      end

      it "provides excerpt" do
        search.results.first['excerpt'].should == 'Dealing with <b>debt</b> problems, creditors, arrears and bankruptcy, and find out <br>  where to get help or advice about repaying or recovering a <b>debt</b>.'
      end

      describe "processing extra CSS classes based on the URL" do
        describe "returns a 3-item list containing valid class names" do
          it "for the whole host" do
            search.results.first['classes'].should == ['www_direct_gov_uk', 'direct_gov_uk', 'www_direct_gov_uk-en']
          end
        end
      end

    end

    describe "a result set containing normal results and a subscribed link" do
      before(:each) do
        search.stubs(:fetch).returns(File.open(fixture_path('search_ucas.xml')))
        search.run!
      end

      context "normal results list" do
        it "omits the subscribed link" do
          search.results.length.should == 9
        end
      end

      context "subscribed links list" do
        it "contains one result" do
          search.subscribed_links.length.should == 1
        end

        it "provides link URL" do
          search.subscribed_links.first['url'].should == 'http://www.ucas.ac.uk/'
        end

        it "provides link Host" do
          search.subscribed_links.first['host'].should == 'www.ucas.ac.uk'
        end

        it "provides title" do
          search.subscribed_links.first['title'].should == 'UCAS'
        end

        it "provides the description" do
          search.subscribed_links.first['description'].should == 'At the heart of connecting people to higher education'
        end

      end
    end

    describe "a result set containing normal results, some of which are marked as tools " do
      before(:each) do
        search.stubs(:fetch).returns(File.open(fixture_path('search_tool.xml')))
        search.run!
      end

      context "normal results list" do
        it "size of results is unaffected" do
          search.results.length.should == 10
        end

        it "provides link URL" do
          search.results[7]['url'].should == 'http://www.direct.gov.uk/en/MoneyTaxAndBenefits/ManagingDebt/PlanYourWayOutOfDebt/DG_183575'
        end

        it "provides title" do
          search.results[7]['title'].should == '<b>Debt</b> management plans - ways out of <b>debt</b> : Directgov - Money, tax <b>...</b>'
        end

        it "provides the excerpt" do
          search.results[7]['excerpt'].should == "If you're struggling to meet repayments on money you owe, you could consider <br>  setting up a <b>debt</b> management plan. Check if it's the right option for you and <br>  <b>...</b>"
        end

      end
    end
  end

  describe "params needed for the next page of results" do
    it "should return correct params for an alpha-only search" do
      @search = Google.new('CSE_id', :alpha, :q => "hello+mum")
      @search.expects(:fetch).returns(File.open(fixture_path('search_debt.xml')))

      @search.run!
      @search.next_page_params.should == {:q => 'debt', :start => '10'}
    end

    it "should return correct params for a gov-wide search" do
      @search = Google.new('CSE_id', :all_gov, :q => "hello+mum")
      @search.expects(:fetch).returns(File.open(fixture_path('search_debt.xml')))

      @search.run!
      @search.next_page_params.should == {:q => 'debt', :start => '10', :t => 'all_gov'}
    end
  end
end
end
