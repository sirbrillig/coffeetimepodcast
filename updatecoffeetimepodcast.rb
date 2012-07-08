#!/usr/bin/ruby

require 'net/http'
require 'net/https'
require 'pathname'
require 'time'
require 'latestcoffeetime'
require 'coffeetimebloginfo'

class BlogPoster

  def post_podcast(title, media_url)
    raise "#{$0} requires GDATA_USER, GDATA_PASS, and GDATA_BLOG_ID to be set" unless ENV['GDATA_USER'] and ENV['GDATA_PASS'] and ENV['GDATA_BLOG_ID']

    googleEmail = ENV['GDATA_USER']
    googlepasswd = ENV['GDATA_PASS']
    blogId = ENV['GDATA_BLOG_ID'] # Go to blogspot dashboard and click on your blog's “Posts" link and you will see the blog ID in the URL

    authToken = log_in_to_blog(blogId, googleEmail, googlepasswd)
    raise "Post already exists with the title '#{title}'." if check_for_post(blogId, title)
    make_new_blog_post(blogId, authToken, title, media_url)
    puts "Made new post titled '#{title}'."
  end

  # Posting code modified from: http://ladydeals.com/posting-to-bloggerblogspot-with-ruby-programmatically/
  #
  # Returns the authorization token needed to make a post.
  def log_in_to_blog(blogId, googleEmail, googlepasswd)
    source = 'ladydeals.com-rubyPost-1.0' #unimportant, google recommend it in <companyName-applicationName-versionID> format

    http = Net::HTTP.new('www.google.com', 443)
    http.use_ssl = true
    urlPath = '/accounts/ClientLogin'

    # Setup HTTPS request post data to obtain authentication token.
    data = 'Email=' + googleEmail +'&Passwd=' + googlepasswd + '&source=' + source + '&service=blogger'# Setup HTTPS request header to obtain authentication token.
    headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

    # Submit HTTPS post request
    resp, data = http.post(urlPath, data, headers)

    # Output on the screen -> we should get either a 302 redirect (after a successful login) or an error page
    # Expect resp.code == 200 and resp.message == 'OK' for a successful.
    raise "Failed to log into Blogger.com.\nCode = #{resp.code}\n Message = #{resp.message}" if (!(resp.code.eql? '200'))
    #resp.each {|key, val| puts key + ' = ' + val}
    # The response data will contain three lines which hold SID, LSID, and Auth. We can disregard SID and LSID.

    # Parse for the authentication token.
    dataLines = data.split("\n")
    authPair = dataLines[2]
    authPairArray = authPair.split("=")
    authToken = authPairArray[1]
    return authToken
  end

  def check_for_post(blogId, title)
    http = Net::HTTP.new('www.blogger.com')
    path = '/feeds/' + blogId + '/posts/default'

    # Check for duplicates.
    resp = http.get(path)
    raise "Failed to log into Blogger.com.\nCode = #{resp.code}\n Message = #{resp.message}" if (resp.code !~ /^20\d/)
    return true if resp.body =~ />#{title}</
    false
  end

  def make_new_blog_post(blogId, authToken, title, media_url)
    # Setup HTTP request post head to make a blog post.
    headers = { 'Authorization' => 'GoogleLogin auth=' + authToken, 'Content-Type' => 'application/atom+xml' }

    # Setup HTTP request data to make a blog post.
    blog_title = "#{title}"
    blog_media_url = "#{media_url}"
    data = <<dataEnd
<entry xmlns='http://www.w3.org/2005/Atom'>
<title type='text'>#{blog_title}</title>
<content type='xhtml'>
<div xmlns="http://www.w3.org/1999/xhtml">CoffeeTime #{blog_title}: <a href="#{blog_media_url}">#{blog_media_url}</a></div>
</content>
</entry>
dataEnd

    http = Net::HTTP.new('www.blogger.com')
    path = '/feeds/' + blogId + '/posts/default'
    resp, data = http.post(path, data, headers)

    # Expect resp.code == 200 and resp.message == 'OK' for a successful.
    puts "Sent a blog entry with the title '#{blog_title}' to Blogger.com."
    raise "Post failed.\nCode = #{resp.code}\n Message = #{resp.message}\npath=#{path}\nheaders=#{headers}\ndata=#{data}" if (resp.code !~ /^20\d/)
  end
end


latest_ep = CoffeeTimeEpisode.latest
BlogPoster.new.post_podcast(latest_ep.title, latest_ep.episode_url)
