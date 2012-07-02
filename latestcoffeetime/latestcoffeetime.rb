#!/opt/local/bin/ruby

# A tool to report (and download, if desired) the latest recorded CoffeeTime
# episode from WMBR's archives.
# 
# Written by: Payton Swick <payton@foolord.com>
# 2012-06-29
#

#require 'nokogiri'
require 'open-uri'
require 'optparse'


class CoffeeTimeEpisode
  attr_accessor :archive_url
  attr_reader :episode_url

  # Return a CoffeeTimeEpisode of the latest episode.
  def self.latest
    CoffeeTimeEpisode.new.set_latest
  end

  def initialize
    @archive_url = 'http://wmbr.org/cgi-bin/arch'
    @episode_url = ''
  end

  # Download the file at episode URL.
  #
  # Ideally, this should check for filetype or it could download anything.
  def download
    raise "No episode URL specified." unless @episode_url
    @episode_url =~ /\/([^\/]+\.\w{3})$/
    to_here = $1
    writeOut = open(to_here, "wb") 
    writeOut.write(open(episode).read) 
    writeOut.close
  end

  # Set this episode to the latest. Returns itself.
  def set_latest
    @episode_url = self.latest_url
    self
  end

  # Return the URL of the latest episode.
  def latest_url
    #doc = Nokigiri::HTML(open(archive_url))
    #doc.traverse do |element|
    #  return element # FIXME
    #end

    # Note: this is bad because we're trying to parse HTML using a REGEXP. Ideally
    # use an HTML parser like nokogiri.
    doc = open(self.archive_url)
    if doc.read =~ /a href=\"(http:\/\/wmbr\.org\/m3u\/Coffeetime_.+?\.m3u)"/
      playlist_url = $1
      m3u = open(playlist_url)
      if m3u.read =~ /^(http:\/\/.+)/
        episode = $1
        return episode
      else
        raise "Cannot find episode URL in playlist file."
      end
    else
      raise "Cannot find episode on archive page (#{self.archive_url})."
    end
  end
end

if __FILE__ == $0
  options = {}
  optparse = OptionParser.new do |opts|
    opts.on("--get") do |o|
      options[:get] = o
    end
    opts.on("--archive_url") { |o| puts CoffeeTimeEpisode.new.archive_url; exit; }
  end.parse!

  if options[:get]
    puts "Downloading..."
    CoffeeTimeEpisode.latest.download
    puts "Done."
  else
    puts CoffeeTimeEpisode.latest.episode_url
  end
end
