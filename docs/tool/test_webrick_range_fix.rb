# frozen_string_literal: true

require "net/http"
require "tmpdir"
require "webrick"

unless ARGV.empty? || ARGV == ["--without-workaround"]
  abort "Usage: ruby tool/test_webrick_range_fix.rb [--without-workaround]"
end
require_relative "webrick_range_fix" if ARGV.empty?

failures = []
check = lambda do |label, expected, actual|
  failures << "#{label}: expected #{expected.inspect}, got #{actual.inspect}" unless expected == actual
end

Dir.mktmpdir("webrick-range-test") do |directory|
  # Byte serving does not depend on the video's encoding.
  content = (0..255).to_a.pack("C*") * 8
  File.binwrite(File.join(directory, "video.mp4"), content)
  server = WEBrick::HTTPServer.new(
    BindAddress: "127.0.0.1",
    Port: 0,
    DocumentRoot: directory,
    AccessLog: [],
    Logger: WEBrick::Log.new($stderr, WEBrick::Log::WARN)
  )
  thread = Thread.new { server.start }

  begin
    http = Net::HTTP.new("127.0.0.1", server.listeners.first.addr[1], nil)
    http.open_timeout = 5
    http.read_timeout = 5
    http.start do |connection|
      full = connection.get("/video.mp4")
      check.call("initial status", "200", full.code)
      check.call("initial body", content, full.body)
      raise "Server did not provide an ETag" if full["etag"].nil? || full["etag"].empty?

      matching = connection.get("/video.mp4", "Range" => "bytes=0-1023", "If-Range" => full["etag"])
      check.call("matching If-Range status", "206", matching.code)
      check.call("matching Content-Range", "bytes 0-1023/#{content.bytesize}", matching["content-range"])
      check.call("matching Content-Length", "1024", matching["content-length"])
      check.call("matching Content-Type", "video/mp4", matching["content-type"])
      check.call("matching body", content.byteslice(0, 1024), matching.body)

      stale = connection.get("/video.mp4", "Range" => "bytes=0-1023", "If-Range" => "#{full["etag"]}-stale")
      check.call("stale If-Range status", "200", stale.code)
      check.call("stale Content-Range", nil, stale["content-range"])
      check.call("stale Content-Length", content.bytesize.to_s, stale["content-length"])
      check.call("stale Content-Type", "video/mp4", stale["content-type"])
      check.call("stale body", content, stale.body)
    end
  ensure
    server.shutdown
    thread.value
  end
end

abort failures.join("\n") unless failures.empty?
puts "WEBrick #{WEBrick::VERSION}: matching and stale If-Range regression checks passed."
