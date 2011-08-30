require 'nokogiri'
require 'digest/md5'
require 'uri'

module Searchtools

  class Fetcher
    def initialize(options = {})
      @options = options
    end

    def get(url)
      begin
        return open(url,@options).read()
      rescue OpenURI::HTTPError
        $stderr.puts "Error occured reading #{url}"
        return nil
      end
    end
  end

  class Sitemap

    include Enumerable

    def initialize(fetcher,domain,path = "/sitemap.xml",app=nil)
      @domain = domain
      @app = app
      @fetcher = fetcher
      @urls, @children = parse(@fetcher.get(domain+path))
    end

    def parse(sitemap_xml)
      if sitemap_xml
        sitemap = Nokogiri::XML(sitemap_xml)
        urls = parse_site_map(sitemap)
        children = parse_sitemap_index(sitemap)
        return [urls,children]
      else
        return [[],[]]
      end
    end

    def parse_site_map(sitemap)
      sitemap.xpath('//xmlns:url').map do |url|
        {
          :loc          => URI.parse(url.xpath("xmlns:loc").inner_text).request_uri(),
          :title        => url.xpath("gov:title",        "gov"  => "http://gov.uk/sitemaps").inner_text,
          :autocomplete => url.xpath("gov:autocomplete", "gov"  => "http://gov.uk/sitemaps").inner_text,
          :tags         => url.xpath("gov:tags",         "gov"  => "http://gov.uk/sitemaps").inner_text
        }
      end
    end

    def parse_sitemap_index(sitemap)
      sitemap.xpath('//xmlns:sitemap').map do |sitemap|
        loc = sitemap.xpath("xmlns:loc").inner_text
        app = sitemap.xpath("gov:app","gov"=>"http://gov.uk/sitemaps").inner_text
        uri = URI.parse(loc)
        Sitemap.new(@fetcher,@domain,uri.request_uri(),app)
      end
    end

    def each_with_app
      @urls.each do |url|
        yield [url,@app]
      end
      @children.each do |child|
        child.each_with_app do |url,app|
          yield [url,app]
        end
      end
    end

    def each
      each_with_app do |url,app|
        yield url
      end
    end

    def checksum
      Digest::MD5.hexdigest(self.map{|u| [u[:loc],u[:title],u[:autocomplete]].join("|") }.sort.join("\n"))
    end

  end
end
