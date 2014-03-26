require 'vcr'

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = 'features/cassettes'
end

VCR.cucumber_tags do |t|
  t.tag '@bucket-does-not-exist'
  t.tag '@bucket-does-not-exist-in-tokyo'
  t.tag '@bucket-exists'
  t.tag '@redirects'
  t.tag '@create-cf-dist'
  t.tag '@apply-configs-on-cf-dist'
  t.tag '@redirect-domains'
  t.tag '@redirect-domains-and-cloudfront-exists'
  t.tag '@setup-redirect-domains-with-route_53'
end
