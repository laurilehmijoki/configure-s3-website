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
