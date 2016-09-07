require 'rspec'
require 'configure-s3-website'

Aws.config[:stub_responses] = true

describe ConfigureS3Website::S3Client do
  context 'bucket name' do
    let(:config_source) {
      ConfigureS3Website::FileConfigSource.new('spec/sample_files/_custom_index_and_error_docs.yml')
    }

    it 'calls the S3 API with the correct bucket name' do
      allow_any_instance_of(Aws::S3::Client).to receive(:put_bucket_website).with(
        hash_including(
          :bucket => "my-bucket"
        )
      )
      ConfigureS3Website::S3Client.configure_website({config_source: config_source})
    end
  end

  describe 'the EU region alias' do
    let(:config_source) {
      ConfigureS3Website::FileConfigSource.new('spec/sample_files/_config_file_EU.yml')
    }

    it 'translates into eu-west-1' do
        allow_any_instance_of(Aws::S3::Client).to receive(:create_bucket).with(
          hash_including(
            create_bucket_configuration: {
              location_constraint: 'eu-west-1'
            }
          )
        )
        ConfigureS3Website::S3Client.send(:create_bucket, config_source)
    end
  end

  context 'custom index and error documents' do
    let(:config_source) {
      ConfigureS3Website::FileConfigSource.new('spec/sample_files/_custom_index_and_error_docs.yml')
    }

    it 'calls the S3 API with the custom index and error documents' do
      allow_any_instance_of(Aws::S3::Client).to receive(:put_bucket_website).with(
        hash_including(
          :website_configuration=> {
            :index_document => {
              :suffix => "default.html"
            },
            :error_document => {
              :key => "404.html"
            },
            :routing_rules => nil
          }
        )
      )
      ConfigureS3Website::S3Client.configure_website({config_source: config_source})
    end
  end

  context 'create bucket' do
    [
      { :region => 'us-east-1' },
      { :region => 'us-west-1' },
      { :region => 'us-west-2' },
      { :region => 'ap-south-1' },
      { :region => 'ap-northeast-2' },
      { :region => 'ap-southeast-1' },
      { :region => 'ap-southeast-2' },
      { :region => 'ap-northeast-1' },
      { :region => 'eu-central-1' },
      { :region => 'eu-west-1' },
      { :region => 'sa-east-1' },
    ].each { |conf|
      it 'calls the S3 CreateBucket API with the correct location constraint' do
        allow_any_instance_of(Aws::S3::Client).to receive(:create_bucket).with(
          hash_including(
            create_bucket_configuration: 
              if conf[:region] == 'us-east-1'
                nil
              else
                {
                  location_constraint: conf[:region]
                }
              end
          )
        )
        config_source = double('config_source')
        allow(config_source).to receive(:s3_access_key_id).and_return('test')
        allow(config_source).to receive(:s3_secret_access_key).and_return('test')
        allow(config_source).to receive(:s3_bucket_name).and_return('test-bucket')
        allow(config_source).to receive(:s3_endpoint).and_return(conf[:region])
        ConfigureS3Website::S3Client.send(:create_bucket, config_source)
      end
    }
  end

  context 'bucket policy' do
    let(:config_source) {
      ConfigureS3Website::FileConfigSource.new('spec/sample_files/_custom_index_and_error_docs.yml')
    }

    it 'sets the bucket readable to the whole world' do
      allow_any_instance_of(Aws::S3::Client).to receive(:put_bucket_policy).with(
        hash_including(
          :policy => "{\n          \"Version\":\"2008-10-17\",\n          \"Statement\":[{\n            \"Sid\":\"PublicReadForGetBucketObjects\",\n            \"Effect\":\"Allow\",\n            \"Principal\": { \"AWS\": \"*\" },\n            \"Action\":[\"s3:GetObject\"],\n            \"Resource\":[\"arn:aws:s3:::my-bucket/*\"]\n          }]\n        }"
        )
      )
      ConfigureS3Website::S3Client.configure_website({config_source: config_source})
    end
  end

  context 'redirect rules' do
    let(:config_source) {
      ConfigureS3Website::FileConfigSource.new('spec/sample_files/_custom_index_and_error_docs_with_routing_rules.yml')
    }

    it 'calls the S3 API with the redirect rules settings' do
      allow_any_instance_of(Aws::S3::Client).to receive(:put_bucket_website).with(
        hash_including(
          :website_configuration => {
            :index_document => {
              :suffix => "default.html"
            },
            :error_document => {
              :key => "missing.html"
            },
            :routing_rules => [
              {
                :condition => {
                  :key_prefix_equals => "blog/some_path"
                },
                :redirect => {
                  :host_name => "blog.example.com",
                  :replace_key_prefix_with => "some_new_path/",
                  :http_redirect_code => "301"
                }
              }
            ]
          }
        )
      )
      ConfigureS3Website::S3Client.configure_website({config_source: config_source})
    end
  end
end
