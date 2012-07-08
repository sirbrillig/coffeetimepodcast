#!/usr/bin/ruby

# A tool to report (and download, if desired) the latest recorded CoffeeTime
# episode from WMBR's archives.
# 
# Written by: Payton Swick <payton@foolord.com>
# 2012-06-29
#

require 'open-uri'
require 'optparse'
require 'rubygems'


class CoffeeTimeEpisode
  attr_accessor :archive_url, :title
  attr_accessor :disable_parsing, :verbose
  attr_reader :episode_url

  # Return a CoffeeTimeEpisode of the latest episode.
  def self.latest(options={})
    CoffeeTimeEpisode.new(options).set_latest
  end

  def initialize(options={})
    @archive_url = 'http://wmbr.org/cgi-bin/arch'
    @episode_url = ''
    @verbose = options[:verbose]
    @disable_parsing = options[:disable_parsing]
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

  # Return the first file URL from within a playlist (m3u).
  def url_from_playlist(playlist_url)
    m3u = open(playlist_url)
    if m3u.read =~ /^(http:\/\/.+)/
      return $1
    else
      raise "Cannot find episode URL in playlist file."
    end
  end

  def add_year_to_string(str)
    return str if str =~ /\b\d{4}\b/
    str + " #{Time.now.year}"
  end

  # Return the URL of the latest episode using only core Ruby. You should use
  # latest_url instead.
  #
  # Note: this is bad because we're trying to parse HTML using a REGEXP. Ideally
  # use an HTML parser like nokogiri.
  def latest_url_old
    puts "old style parsing..." if self.verbose
    doc = open(self.archive_url)
    if doc.read =~ /a href=\"(http:\/\/wmbr\.org\/m3u\/Coffeetime_.+?\.m3u)".+?>([^<]+)</
      playlist_url = $1
      title = $2
      url = url_from_playlist(playlist_url)
      @title = add_year_to_string(title)
      puts "Title = #{@title}" if self.verbose
      return url
    else
      raise "Cannot find episode on archive page (#{self.archive_url})."
    end
  end

  # Return the URL of the latest episode. 
  #
  # If this fails to load nokogiri, it will default to basic Ruby.
  def latest_url
    return latest_url_old if self.disable_parsing
    begin
      require 'nokogiri'
    rescue LoadError
      puts "nokogiri is not installed. falling back to old style." if self.verbose
      return latest_url_old
    end
    puts "nokogiri is parsing..." if self.verbose
    doc = Nokogiri::HTML(open(archive_url))
    nodes = doc.xpath("//a[\@href]").select { |node| node['href'] =~ /CoffeeTime/i }
    raise "Cannot find episode on archive page (#{self.archive_url})." if nodes.empty?
    @title = add_year_to_string(nodes.first.children.first.to_s)
    puts "Title = #{@title}" if self.verbose
    url_from_playlist(nodes.first['href'])
  end

end



if __FILE__ == $0
  options = {}
  optparse = OptionParser.new do |opts|
    opts.on("--get") { options[:get] = true }
    opts.on("--archive_url") { |o| puts CoffeeTimeEpisode.new.archive_url; exit; }
    opts.on("--old_parse") { options[:disable_parsing] = true }
    opts.on("--verbose") { options[:verbose] = true }
  end.parse!

  if options[:get]
    puts "Downloading..."
    CoffeeTimeEpisode.latest(options).download
    puts "Done."
  else
    ep = CoffeeTimeEpisode.latest(options)
    puts ep.episode_url
  end
end
