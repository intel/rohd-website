# frozen_string_literal: true

require "webrick"

module WEBrickChromeDevToolsProbe
  PATH = "/.well-known/appspecific/com.chrome.devtools.json"

  def service(request, response)
    super
  rescue WEBrick::HTTPStatus::NotFound => error
    raise unless %w[GET HEAD].include?(request.request_method) &&
                 request.path == PATH &&
                 error.message == "'#{PATH}' not found."

    response.set_error(error)
  end
end

WEBrick::HTTPServer.prepend(WEBrickChromeDevToolsProbe)
