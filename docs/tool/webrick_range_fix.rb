# frozen_string_literal: true

require "webrick"

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

    # WEBrick incorrectly returns 304 for a matching If-Range validator.
    request.header.delete("if-range")
    request.header.delete("range") unless matches
  end
end

WEBrick::HTTPServlet::DefaultFileHandler.prepend(WEBrickRangeRequestFix)
