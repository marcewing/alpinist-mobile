# A few stranesses here.
#
# First, iPhone definitely crashes on 10 element video indexes, so there is
# cruft to switch between 10 and 5 elements.
#
# Second, iPhone still seems to crash after loading 3 or so 5 element indexes,
# so, there is a switch to use non-video indexes with links to video pages.
#
# Third, when using 5 element indexes, it isn't possible to make the paginator
# without a lot of page pre-loading.  So I don't bother.
#
# When iPhone no longer crashes the better way is 10 element video indexes.

class TvController < ApplicationController
  include ApplicationHelper

  def index
    @USE_VIDEO_PAGES = true;
    @USE_SHORT_INDEX = false;
  
    @title = "Alpinist TV"
    if params[:id]
      @indexpage = params[:id].to_i
    else
      @indexpage = 1
    end
    
    if @USE_SHORT_INDEX
      alpinistIndexPage = ((@indexpage - 1) / 2) + 1
      whichRange = ((@indexpage % 2) == 1) ? 0..4 : 5..9 
    else
      alpinistIndexPage = @indexpage
      whichRange = 0..9
    end
    
    @origurl = "video/index.mhtml?p=#{alpinistIndexPage}"
    @origcontent = get_orig_content(@origurl)    
    @videos = Array.new
    
    (@origcontent/"div.eachitem")[whichRange].each do |i|
      name = (i/"h2/a").inner_html
      page = (i/"a").first["href"]
      thumbpath = (i/"img").first['src']
      thumbbase = thumbpath.gsub(/-thumb.jpg/, "")
      thumb = "http://www.alpinist.com/#{thumbpath}"
      
      desc = (i/"div.bodytext").inner_html
      desc.gsub!(/<p>/, "")
      desc.gsub!(/<\/p>/, "")
      
      mov = "http://www.alpinist.com/#{thumbbase}.mp4"
      origmov = mov

      # If using vid pages, save a transaction and skip this
      if ! @USE_VIDEO_PAGES
        unless url_exists? mov
          # fix url and point to iPhone-converted file
          origmov = "http://www.alpinist.com/#{thumbbase}.mov"
          ref.gsub!(/.*\//, "")
          # mov = "http://www.marcewing.com/media/#{thumbbase}.m4v"
          mov = "http://s3.amazonaws.com/marcewing/#{thumbbase}.m4v"
        end
      end
      
      @videos << { :thumb => thumb, # full url of thumbnail
                   :mov => mov,     # full url of movie file
                   :name => name,   # video title
                   :desc => desc,   # video description
                   :origpage => page,  # url of original video page on alpinist.com
                   :origmov => origmov # url of original movie on alpinist.com
                   }  
    end
    
    # generate paginator
    @paginator = @origcontent.search("//div[@id='paginator']").inner_html
    @nextpage = (@paginator =~ /Next Page/) ? "Next" : nil
    @prevpage = (@indexpage.to_i == 1) ? nil : "Prev"
    if @USE_SHORT_INDEX
      @paginator = "";
    else
      @paginator.sub!(/^.*\[ &nbsp;/m, "")
      @paginator.sub!(/&nbsp; \].+$/m, "")
      @paginator.gsub!(/video\/index\.mhtml\?p=/m, "tv/index/")
    end
  end

  def video
      origcontent = get_orig_content(params[:id])    

      @title = (origcontent/"title").inner_html
      
      content = origcontent.search("//div[@id='pagecontent'").inner_html
      
      ref = content[/(showQTMovie\(\s*\')(.+)(\',)/,2]

      if (ref =~ /mp4$/) or (ref =~ /m4v$/)
        @movie = "http://www.alpinist.com/#{ref}"
      else
        @movie = "http://s3.amazonaws.com/marcewing/" +
                  File::basename(ref).sub(/mov$/,'m4v')
      end
      @thumb = "http://www.alpinist.com/#{ref.sub(/....$/, '-thumb.jpg')}"
      
#      @movie = "http://s3.amazonaws.com/marcewing/sharp-end.m4v"
  end

end
