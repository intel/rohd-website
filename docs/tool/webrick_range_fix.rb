# frozen_string_literal: true

require "webrick"

# Track removal once https://github.com/ruby/webrick/pull/173 is released
# and test_webrick_range_fix.rb passes with --without-workaround.
module WEBrickRangeRequestFix
  def do_GET(request, response)
    normalize_if_range(request) if request["range"] && request["if-range"]
    super
  end

  private

  def normalize_if_range(request)
    stat = File.stat(@local_path)
    etag = format("%x-%x-%x", stat.ino, stat.size, stat.mtime.to_i)
    validator = request["if-range"]

    matches = begin
      Time.httpdate(validator) >= stat.mtime
    rescue ArgumentError
      WEBrick::HTTPUtils.split_header_value(validator).include?(etag)
    end

    # WEBrick returns 304 for matching If-Range and 206 for stale validators.
    request.header.delete("if-range")
    request.header.delete("range") unless matches
  end
end

WEBrick::HTTPServlet::DefaultFileHandler.prepend(WEBrickRangeRequestFix)
