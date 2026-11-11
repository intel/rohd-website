# frozen_string_literal: true

require "net/http"
require "stringio"
require "tmpdir"
require_relative "webrick_chrome_devtools_probe"

failures = []
check = lambda do |label, expected, actual|
  failures << "#{label}: expected #{expected.inspect}, got #{actual.inspect}" unless expected == actual
end

Dir.mktmpdir("webrick-chrome-probe-test") do |directory|
  log = StringIO.new
  server = WEBrick::HTTPServer.new(
    BindAddress: "127.0.0.1",
    Port: 0,
    DocumentRoot: directory,
    AccessLog: [],
    Logger: WEBrick::Log.new(log, WEBrick::Log::WARN)
  )
  thread = Thread.new { server.start }

  begin
    http = Net::HTTP.new("127.0.0.1", server.listeners.first.addr[1], nil)
    http.open_timeout = 5
    http.read_timeout = 5
    http.start do |connection|
      path = WEBrickChromeDevToolsProbe::PATH
      check.call("probe status", "404", connection.get(path).code)
      check.call("probe HEAD status", "404", connection.head(path).code)
      check.call("probe log", "", log.string)

      check.call("other missing path status", "404", connection.get("/missing").code)
      failures << "Other missing paths must still be logged" unless log.string.include?("'/missing' not found.")

      server.mount_proc(path) { |_request, response| response.body = '{"workspace":{}}' }
      configured = connection.get(path)
      check.call("configured path status", "200", configured.code)
      check.call("configured path body", '{"workspace":{}}', configured.body)
    end
  ensure
    server.shutdown
    thread.value
  end
end

abort failures.join("\n") unless failures.empty?
puts "Chrome DevTools probe and unrelated requests behaved as expected."
