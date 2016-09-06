require 'rspec'
require 'configure-s3-website'

describe ConfigureS3Website::Endpoint do
  it 'should return the same value for EU and eu-west-1' do
    eu = ConfigureS3Website::Endpoint.new('EU')
    eu_west_1 = ConfigureS3Website::Endpoint.new('eu-west-1')
    expect(eu.region).to eq(eu_west_1.region)
    expect(eu.hostname).to eq(eu_west_1.hostname)
    expect(eu.website_hostname).to eq(eu_west_1.website_hostname)
  end
end
