class NewswireController < ApplicationController
  include ApplicationHelper
  
  def index
    @title = "Alpinist NewsWire"
    if params[:id]
      @indexpage = params[:id]
    else
      @indexpage = 1
    end
    
    @origurl = "newswire/index.mhtml?p=#{@indexpage}"
    @origcontent = get_orig_content(@origurl)    
    @articles = Array.new
    
    (@origcontent/"div.eachitem").each do |i|
      x = (i/"a").first
      @articles << { :ref => x.attributes['href'].sub(/^\/doc\//, ""),
                     :title => x.inner_html }
    end
    
    # generate paginator
    @paginator = @origcontent.search("//div[@id='paginator']").inner_html
    @nextpage = (@paginator =~ /Next Page/) ? "Next" : nil
    @prevpage = (@indexpage.to_i == 1) ? nil : "Prev"
    @paginator.sub!(/^.*\[ &nbsp;/m, "")
    @paginator.sub!(/&nbsp; \].+$/m, "")
    @paginator.gsub!(/\.mhtml\?p=/m, "/")
  end
  
  def article
    @title = "Alpinist NewsWire Article"
    @origurl = "doc/#{params[:id]}"

    content = get_orig_content(@origurl).search("//div[@id='pagecontent']")
    
    @articletitle = (content/"h1").inner_html
    @articleauthor = (content/"p.byline").inner_html
    @articledate = (content/"p.posted").inner_html.sub(/^Posted on: /, "")
    
    # remove comment stuff
    body = (content.search("//div[@id='bodytext']"))
    body.search("//div[@id='commentzone']").remove

    # fix images
    (body/"div.illo").each do |imagediv|
        image = imagediv.at("img")['src']
        caption = (imagediv/"p").inner_html
        newhtml = "<div class=\"article_image\"><img scalefit=\"1\" width=\"100%\" src=\"http://www.alpinist.com/#{image}\" />#{caption}</div>"
        imagediv.swap(newhtml)
    end
    
    @articlebody = body.inner_html
    
    # strip ads
    ad = "<div style=\"border-top: 1px solid #b2b1b1; text-align: left; width: 300px; color: #b2b1b1; float: left; margin: 15px 15px 15px 0px; clear: both;\">advertisement<br /><script src=\"/js/ad/med_rect.mjs?sp=newswire\"></script></div>"
    @articlebody.sub!(ad, "")

    # bottom cruft
    endcruft = /<div style=\"clear: both\"><\/div>.+/m
    @articlebody.sub!(endcruft, "")
    
  end
  
end
