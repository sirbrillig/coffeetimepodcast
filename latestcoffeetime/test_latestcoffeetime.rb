#!/usr/bin/ruby

require 'latestcoffeetime'
require 'test/unit'

class TestLatestCoffeetime < Test::Unit::TestCase

  def test_archive_url
    episode = CoffeeTimeEpisode.new
    assert(episode.archive_url =~ /http:\/\/wmbr\.org\//, "The archive URL should start with WMBR.org")
  end
end
