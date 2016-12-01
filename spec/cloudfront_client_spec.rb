require 'rspec'
require 'configure-s3-website'

describe ConfigureS3Website::CloudFrontClient do
  RSpec::Matchers.define :lambda_matcher do |lmbda, expected_value|
    match { |create_distribution_args|
      lmbda.call(create_distribution_args) == expected_value
    }
  end

  def config_source_mock(cloudfront_distribution_config, region)
    mock = double('config_source')
    allow(mock).to receive(:s3_bucket_name).and_return('test-bucket')
    allow(mock).to receive(:s3_endpoint).and_return(region)
    allow(mock).to receive(:s3_access_key_id).and_return('foo')
    allow(mock).to receive(:s3_secret_access_key).and_return('bar')
    allow(mock).to receive(:cloudfront_distribution_id).and_return('AEEEE')
    allow(mock).to receive(:cloudfront_distribution_id=).with(anything).and_return(nil)
    allow(mock).to receive(:description)
    allow(mock).to receive(:cloudfront_distribution_config).and_return(cloudfront_distribution_config)
    mock
  end

  let(:aws_cloudfront_client) {
    cloudfront_client = double('cloudfront_client')
    create_distribution_response = double('create_dist_response')
    allow(create_distribution_response).to receive_message_chain(:distribution, :id) { 'bar' }
    allow(create_distribution_response).to receive_message_chain(:distribution, :domain_name) { 'foo' }
    allow(create_distribution_response).to receive_message_chain(:distribution, :distribution_config, :origins, :items) {
      [double( :domain_name => 'foo' )]
    }
    allow(cloudfront_client).to receive(:create_distribution).and_return(create_distribution_response)
    get_distribution_response = double('get_distribution_response')
    allow(get_distribution_response).to receive(:etag).and_return('tag')
    allow(get_distribution_response).to receive_message_chain(:distribution, :distribution_config).and_return({
      :default_cache_behavior => {
        :viewer_protocol_policy => 'allow_all',
        :min_ttl => 5000
      }
    })
    allow(get_distribution_response).to receive_message_chain(:distribution, :distribution_config, :caller_reference) { 'ref' }
    allow(cloudfront_client).to receive(:get_distribution).with(:id => 'AEEEE').and_return(get_distribution_response)
    cloudfront_client
  }
  before {
    allow(ConfigureS3Website::CloudFrontClient).to receive(:cloudfront).and_return(aws_cloudfront_client)
  }
  describe 'letting the user to override the default values' do
    cloudfront_distribution_config = {
      'default_cache_behavior' => {
        'min_ttl' => 900
      }
    }

    context "update distribution" do
      it "let's the user to override the default ttl" do
        expect(aws_cloudfront_client).to receive(:update_distribution).with(
          lambda_matcher(lambda { |update_distribution_args|
            update_distribution_args[:distribution_config][:default_cache_behavior][:min_ttl]
          }, 900)
        )
        ConfigureS3Website::CloudFrontClient.send(
          :apply_distribution_config,
          {:config_source => config_source_mock(cloudfront_distribution_config, region = 'something') }
        )
      end

      it 'retains the default values that are not overriden' do
        expect(aws_cloudfront_client).to receive(:update_distribution).with(
          lambda_matcher(lambda { |update_distribution_args|
            update_distribution_args[:distribution_config][:default_cache_behavior][:viewer_protocol_policy]
          }, 'allow_all')
        )
        ConfigureS3Website::CloudFrontClient.send(
          :apply_distribution_config,
          {:config_source => config_source_mock(cloudfront_distribution_config, region = 'something') }
        )
      end
    end

    context "create distribution" do
      it "let's the user to override the default ttl" do
        expect(aws_cloudfront_client).to receive(:create_distribution).with(
          lambda_matcher(lambda { |create_distribution_args|
            create_distribution_args[:distribution_config][:default_cache_behavior][:min_ttl]
          }, 900)
        )
        ConfigureS3Website::CloudFrontClient.send(
          :create_distribution,
          {:config_source => config_source_mock(cloudfront_distribution_config, region = 'something') }
        )
      end

      it 'retains the default values that are not overriden' do
        expect(aws_cloudfront_client).to receive(:create_distribution).with(
          lambda_matcher(lambda { |create_distribution_args|
            create_distribution_args[:distribution_config][:default_cache_behavior][:viewer_protocol_policy]
          }, 'allow-all')
        )
        ConfigureS3Website::CloudFrontClient.send(
          :create_distribution,
          {:config_source => config_source_mock(cloudfront_distribution_config, region = 'something') }
        )
      end
    end
  end

  [
    { :region => 'us-east-1', :website_endpoint => 's3-website-us-east-1.amazonaws.com' },
    { :region => 'us-west-1', :website_endpoint => 's3-website-us-west-1.amazonaws.com' },
    { :region => 'us-west-2', :website_endpoint => 's3-website-us-west-2.amazonaws.com' },
    { :region => 'ap-south-1', :website_endpoint => 's3-website.ap-south-1.amazonaws.com' },
    { :region => 'ap-northeast-2', :website_endpoint => 's3-website.ap-northeast-2.amazonaws.com' },
    { :region => 'ap-southeast-1', :website_endpoint => 's3-website-ap-southeast-1.amazonaws.com' },
    { :region => 'ap-southeast-2', :website_endpoint => 's3-website-ap-southeast-2.amazonaws.com' },
    { :region => 'ap-northeast-1', :website_endpoint => 's3-website-ap-northeast-1.amazonaws.com' },
    { :region => 'eu-central-1', :website_endpoint => 's3-website.eu-central-1.amazonaws.com' },
    { :region => 'eu-west-1', :website_endpoint => 's3-website-eu-west-1.amazonaws.com' },
    { :region => 'sa-east-1', :website_endpoint => 's3-website-sa-east-1.amazonaws.com' },
  ].each { |conf|
    region = conf[:region]
    website_endpoint = conf[:website_endpoint]

    describe "create distribution in #{region}" do
      it "honors the endpoint of the S3 website (#{region})" do
        expect(aws_cloudfront_client).to receive(:create_distribution).with(
          lambda_matcher(lambda { |create_distribution_args|
            create_distribution_args[:distribution_config][:origins][:items][0][:domain_name]
          }, "test-bucket.#{website_endpoint}")
        )
        ConfigureS3Website::CloudFrontClient.send(
          :create_distribution,
          {:config_source => config_source_mock({}, region = region) }
        )
      end
    end
  }
end
