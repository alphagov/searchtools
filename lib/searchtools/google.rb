require 'open-uri'
require 'uri'
require 'nokogiri'
require 'htmlentities'
require 'rack/utils'

module Searchtools

class Google
  def self.decoder
    @decoder ||= HTMLEntities.new
  end

  def decode(text)
    self.class.decoder.decode(text)
  end

  attr_reader :results, :q, :query_text, :kind

  def initialize(client_id, kind, opts = {})
    @query_text = Rack::Utils.escape_html(opts[:q])
    @kind = kind
    @q = Rack::Utils.escape(opts[:q])
    if opts[:start]
      begin
        @start = opts[:start].to_i
      end
      @start = nil if @start <= 0
    end
    @client_id = client_id
    @opts = opts
  end

  def search_url
    # &start=10&num=10&output=xml&client=google-csbe&cx=00255077836266642015:u-scht7a-8i
    params = {
      'ie' => 'utf8',
      'hl' => 'en',
      'client' => 'google-csbe',
      'output' => 'xml_no_dtd',
      'num' => '20',
      'cx' => @client_id
    }
    params['start'] = @start if @start
    qs = params.collect { |param, value| "#{param}=#{value}" }.join('&')
    "http://www.google.com/search?q=#{@q}&#{qs}"
  end

  def run!
    @result_doc = Nokogiri::XML.parse(fetch)
  end

  def next_page_params
    google_q = @result_doc.xpath('/GSP/RES/NB/NU').text
    return nil if google_q.nil?
    query = Rack::Utils::parse_query(URI.parse(google_q).query)
    params = {:q => query['q'], :start => query['start']}
    params[:t] = 'all_gov' if kind == :all_gov
    params
  end
  
  def next_page_query
    Rack::Utils.build_query(next_page_params)
  end

  def result_classes(uri)
    split_host = uri.host.split('.')
    css_full_host = split_host.join('_')
    css_restricted_host = split_host.reverse[0..2].reverse.join('_')
    classes = [css_full_host, css_restricted_host]
    classes << css_full_host + '-' + uri.path.split('/')[1] unless uri.path == "/" || uri.path == ""
    classes
  end

  def results
    @results ||= @result_doc.xpath('/GSP/RES/R[not(SL_RESULTS)]').collect do |n| 
      url = n.xpath('./U').text
      uri = URI.parse(url)
      classes = result_classes(uri)
      {
        'title' => n.xpath('./T').text, 
        'excerpt' => decode(n.xpath('./S').text), 
        'url' => url,
        'host' => uri.host,
        'classes' => classes
      }
    end
  end

  def subscribed_links
    @subscribed_links ||= @result_doc.xpath('/GSP/RES/R/SL_RESULTS/SL_MAIN').collect do |n|
      url = n.xpath('./U').text
      uri = URI.parse(url)
      classes = result_classes(uri)
      {
        'title' => n.xpath('./T').text,
        'description' => decode(n.xpath('./BODY_LINE/BLOCK/T').collect { |t| t.text }.join(" ")),
        'url' => url,
        'host' => uri.host,
        'classes' => classes
      }
    end
  end

  protected

  def fetch
    URI.parse(search_url).open
  end
end

end
