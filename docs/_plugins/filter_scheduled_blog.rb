# frozen_string_literal: true

Jekyll::Hooks.register :site, :post_read do |site|
  blog = site.collections["blog"]
  blog.docs.reject! { |document| !site.publisher.publish?(document) } if blog
end
