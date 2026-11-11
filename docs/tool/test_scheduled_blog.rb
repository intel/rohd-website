# frozen_string_literal: true

require "fileutils"
require "jekyll"
require "tmpdir"

failures = []
Dir.mktmpdir("jekyll-scheduled-blog-test") do |directory|
  source = File.join(directory, "source")
  FileUtils.mkdir_p(File.join(source, "_blog"))
  {
    "2025-01-01-past.md" => "Past",
    "2025-01-02-today.md" => "Today",
    "2025-01-03-future.md" => "Future"
  }.each do |filename, title|
    File.write(File.join(source, "_blog", filename), <<~MARKDOWN)
      ---
      title: #{title}
      permalink: /#{title.downcase}.html
      ---
      #{title} content
    MARKDOWN
  end
  File.write(File.join(source, "_blog", "2025-01-01-delayed.md"), <<~MARKDOWN)
    ---
    title: Delayed
    date: 2025-01-03
    permalink: /delayed.html
    ---
    Delayed content
  MARKDOWN
  File.write(File.join(source, "index.html"), <<~LIQUID)
    ---
    ---
    {% for entry in site.blog %}{{ entry.title }};{% endfor %}
  LIQUID

  [false, true].each do |future|
    destination = File.join(directory, future ? "preview" : "production")
    config = Jekyll.configuration(
      "source" => source,
      "destination" => destination,
      "plugins_dir" => File.expand_path("../_plugins", __dir__),
      "collections" => { "blog" => { "output" => true } },
      "timezone" => "UTC",
      "time" => "2025-01-02 12:00:00 +0000",
      "future" => future,
      "quiet" => true
    )
    Jekyll::Site.new(config).process
    index = File.read(File.join(destination, "index.html"))
    { "Past" => true, "Today" => true, "Future" => future, "Delayed" => future }.each do |title, expected|
      listed = index.include?("#{title};")
      page_exists = File.file?(File.join(destination, "#{title.downcase}.html"))
      failures << "#{title} listing with future=#{future}: expected #{expected}, got #{listed}" unless listed == expected
      failures << "#{title} page with future=#{future}: expected #{expected}, got #{page_exists}" unless page_exists == expected
    end
  end
end

abort failures.join("\n") unless failures.empty?
puts "Scheduled blog publication and future preview checks passed."
