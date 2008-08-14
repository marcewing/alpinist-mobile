# Methods added to this helper will be available to all templates in the application.
 
require 'hpricot'
require 'open-uri'

require 'net/http'
require 'uri'

module ApplicationHelper
  def get_orig_content (url)
    origurl = "http://www.alpinist.com/#{url}"
    Hpricot(open(origurl))
  end
end


def url_exists?(image_url)
  Timeout::timeout(5) do
    url = URI.parse(image_url)
    req = Net::HTTP::Head.new(url.path)
    res = Net::HTTP.start(url.host, url.port) do |h| 
      h.request(req)
    end
    return res.message.strip.downcase == "ok"
  end
rescue Exception
  false
end