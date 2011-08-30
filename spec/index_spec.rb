# -*- encoding: utf-8 -*-
require 'spec_helper'

module Searchtools
  describe Index do
    before(:each) do
      @index = Index.new
      data = [ {
        :title=> "Attorney General’s Office", 
        :loc=> "/departments/attorney-generals-office/"
      },
      {
        :title=> "Cabinet Office", 
        :loc=> "/departments/cabinet-office/"
      },
      {
        :title=> "Department for Business, Innovation and Skills", 
        :loc=> "/departments/business-innovation-and-skills/"
      },
      {
        :title=> "Department for Communities and Local Government", 
        :loc=> "/departments/communities-and-local-government/"
      },
      {
        :title=> "Department for Culture, Media and Sport", 
        :loc=> "/departments/culture-media-and-sport/"
      },
      {
        :title=> "Department for Education", 
        :loc=> "/departments/education/"
      },
      {
        :title=> "Department for Energy and Climate Change", 
        :loc=> "/departments/energy-and-climate-change/"
      },
      {
        :title=> "Department for Environment, Food and Rural Affairs", 
        :loc=> "/departments/environment-food-and-rural-affairs/"
      },
      {
        :title=> "UK Bank Holidays", 
        :loc=> "/calendars/uk-bank-holidays/",
        :tags => "holidays, banking"
      },
      {
        :title=> "Book a Driving Test", 
        :loc=> "/test-centres/",
        :tags => "driving"
      },
      {
        :title=> "Report a stolen passport", 
        :loc=> "/report-lost-passport/",
        :tags => "passports"
      },
      {
        :title=> "Guide to forks", 
        :loc => "/guides/redundancy/",
        :tags => "employment, redundancy"
      }
      ]
     

      data.each do |sr|
        @index.index_phrase(sr[:title],sr)
      end

    end

    it "should do some searching" do
      results = @index.search("Department")
			results.should include( {
        :title=> "Department for Environment, Food and Rural Affairs", 
        :loc=> "/departments/environment-food-and-rural-affairs/"
      })
			results.should_not include( {
				:title=> "UK Bank Holidays", 
        :loc=> "/calendars/uk-bank-holidays/",
        :tags => "holidays, banking"
			})
    end

		it "should respect stop words" do
			results = @index.search("For")
		  titles = results.map {|r| r[:title]}
			titles.should include("Guide to forks")
			titles.should_not include("Department for Energy and Climate Change")
		end

  end

end
