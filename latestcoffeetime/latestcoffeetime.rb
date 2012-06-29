#/usr/bin/ruby

# A tool to report (and download, if desired) the latest recorded CoffeeTime
# episode from WMBR's archives.
# 
# Written by: Payton Swick <payton@foolord.com>
# 2012-06-29
#

#require 'nokogiri'
require 'open-uri'
require 'optparse'

archive_url = 'http://wmbr.org/cgi-bin/arch'

options = {}
optparse = OptionParser.new do |opts|
  opts.on("--get") do |o|
    options[:get] = o
  end
end.parse!

def download_file(episode)
  episode =~ /\/([^\/]+\.\w{3})$/
  to_here = $1
  writeOut = open(to_here, "wb") 
  writeOut.write(open(episode).read) 
  writeOut.close
end

#doc = Nokigiri::HTML(open(archive_url))
#doc.traverse do |element|
#  puts element
#end

# Note: this is bad because we're trying to parse HTML using a REGEXP. Ideally
# use an HTML parser like nokogiri.
doc = open(archive_url)
if doc.read =~ /a href=\"(http:\/\/wmbr\.org\/m3u\/Coffeetime_.+?\.m3u)"/
  playlist_url = $1
  m3u = open(playlist_url)
  if m3u.read =~ /^(http:\/\/.+)/
    episode = $1
    puts episode unless options[:get]
    if options[:get]
      download_file(episode)
    end
  end
end
