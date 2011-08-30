# -*- encoding: utf-8 -*-
require 'spec_helper'


module Searchtools
describe Fetcher do

  # slow test
  it "should fetch URLS for us" do
    text = Fetcher.new().get("http://www.google.com")
    text.should include("Google Search") 
  end

  xit "should return nil on error" do
    text = Fetcher.new().get("http://nothere.nothere.nothere")
    text.should be_nil
  end
end

describe Sitemap do

  describe "when created with a domain name" do

    it "should try to fetch the sitemap.xml from the correct location" do
      domain = "http://example.com"
      fetcher = mock()
			fetcher.expects(:get).with("http://example.com/sitemap.xml")
      Sitemap.new(fetcher,domain)
    end
    
    it "should fetch a directory-level sitemap when given a path" do
      domain = "http://example.com"
      path = "/test-centres/sitemap.xml"
      fetcher = mock()
			fetcher.expects(:get).with("http://example.com/test-centres/sitemap.xml")
      Sitemap.new(fetcher,domain, path)
    end

    it "should have a list of urls, parsed from the sitemap file" do
      fetcher = mock()
			fetcher.stubs(:get).returns(<<-EOF)
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
   <url>
      <loc>http://www.example.com/</loc>
      <lastmod>2005-01-01</lastmod>
      <changefreq>monthly</changefreq>
      <priority>0.8</priority>
   </url>
   <url>
      <loc>http://www.example.com/catalog?item=12</loc>
      <changefreq>weekly</changefreq>
   </url>
   <url>
      <loc>http://www.example.com/catalog?item=73</loc>
      <lastmod>2004-12-23</lastmod>
      <changefreq>weekly</changefreq>
   </url>
</urlset>
      EOF
      sitemap = Sitemap.new(fetcher,"http://example.com")
      sitemap.count.should == 3
      url_locs = sitemap.map {|u| u[:loc] }
      url_locs.should include '/'
      url_locs.should include '/catalog?item=12'
      url_locs.should include '/catalog?item=73'
    end

    it "urls from nested sitemaps should be inlined" do
      fetcher = mock()
			fetcher.stubs(:get).with("http://example.com/sitemap.xml").returns(<<-EOF)
<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
   <sitemap>
      <loc>http://www.example.com/departments/sitemap.xml</loc>
      <lastmod>2004-10-01T18:23:17+00:00</lastmod>
   </sitemap>
   <sitemap>
      <loc>http://www.example.com/ministers/sitemap.xml</loc>
      <lastmod>2005-01-01</lastmod>
   </sitemap>
</sitemapindex>
      EOF
      fetcher.stubs(:get).with("http://example.com/departments/sitemap.xml").returns(<<-EOF)
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
   <url>
      <loc>http://www.example.com/catalog?item=4</loc>
      <changefreq>weekly</changefreq>
   </url>
   <url>
      <loc>http://www.example.com/catalog?item=73</loc>
      <lastmod>2004-12-23</lastmod>
      <changefreq>weekly</changefreq>
   </url>
</urlset>
      EOF
      fetcher.stubs(:get).with("http://example.com/ministers/sitemap.xml").returns(<<-EOF)
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    <url>
      <loc>http://www.example.com/catalog?item=73</loc>
      <lastmod>2004-12-23</lastmod>
      <changefreq>weekly</changefreq>
   </url>
</urlset>
      EOF
      sitemap = Sitemap.new(fetcher,"http://example.com")
      sitemap.count.should == 3
    end

    it "should return gov: namespace specific attributes" do
      fetcher = mock()
			fetcher.stubs(:get).returns(<<-EOF)
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:gov="http://gov.uk/sitemaps">
   <url>
      <loc>http://www.example.com/</loc>
      <lastmod>2005-01-01</lastmod>
      <changefreq>monthly</changefreq>
      <priority>0.8</priority>
      <gov:title>Just a wonderful test</gov:title>
      <gov:autocomplete>Yes</gov:autocomplete>
   </url>
</urlset>
    EOF
      sitemap = Sitemap.new(fetcher,"http://example.com")
      f = sitemap.first
      f[:loc].should == "/"
      f[:title].should == "Just a wonderful test"
      f[:autocomplete].should == "Yes"
    end

    describe "checksum" do
    
      before(:each) do
        base_xml = <<-EOF
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:gov="http://gov.uk/sitemaps">
   <url>
      <loc>http://www.example.com/</loc>
      <lastmod>2005-01-01</lastmod>
      <changefreq>monthly</changefreq>
      <priority>0.8</priority>
      <gov:title>Just a wonderful test</gov:title>
      <gov:autocomplete>Yes</gov:autocomplete>
   </url>
</urlset>
        EOF
        @fetcher = mock()
        @fetcher.stubs(:get).with('http://www.example.com/sitemap.xml').returns(base_xml)
        changed_date = base_xml.gsub('<lastmod>2005','<lastmod>2010')
        @fetcher.stubs(:get).with('http://www.example.com/date.xml').returns(changed_date)
        changed_loc = base_xml.gsub('<loc>http://www.example.com','<loc>http://www.ex.com/bbhbh')
        @fetcher.stubs(:get).with('http://www.example.com/loc.xml').returns(changed_loc)
        changed_title = base_xml.gsub('<gov:title>Just a wonderful test','<gov:title>BLAAH')
        @fetcher.stubs(:get).with('http://www.example.com/title.xml').returns(changed_title)
        changed_autocomplete = base_xml.gsub('<gov:autocomplete>Yes','<gov:autocomplete>BLAAH')
        @fetcher.stubs(:get).with('http://www.example.com/autocomplete.xml').returns(changed_autocomplete)
      end

      it "should be the same if gov:title, gov:autocomplete and loc are the same" do
        sitemap = Sitemap.new(@fetcher,"http://www.example.com")
        sitemap2 = Sitemap.new(@fetcher,"http://www.example.com","/date.xml")
        sitemap.checksum.should == sitemap2.checksum
      end

      it "should be different if locations change" do
        sitemap = Sitemap.new(@fetcher,"http://www.example.com")
        sitemap2 = Sitemap.new(@fetcher,"http://www.example.com","/loc.xml")
        sitemap.checksum.should_not == sitemap2.checksum
      end

      it "should be different if title changes" do
        sitemap = Sitemap.new(@fetcher,"http://www.example.com")
        sitemap2 = Sitemap.new(@fetcher,"http://www.example.com","/title.xml")
        sitemap.checksum.should_not == sitemap2.checksum
      end

      it "should be different if autocomplete changes" do
        sitemap = Sitemap.new(@fetcher,"http://www.example.com")
        sitemap2 = Sitemap.new(@fetcher,"http://www.example.com","/autocomplete.xml")
        sitemap.checksum.should_not == sitemap2.checksum
      end

    end

  end
 
end
end
