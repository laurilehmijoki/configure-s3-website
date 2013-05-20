require 'rspec'
require 'configure-s3-website'

describe ConfigureS3Website::FileConfigSource do
  let(:yaml_file_path) {
    'spec/sample_files/_config_file_with_eruby.yml'
  }

  let(:config_source) {
    ConfigureS3Website::FileConfigSource.new(yaml_file_path)
  }

  it 'can parse files that contain eRuby code' do
    config_source.s3_access_key_id.should eq('hello world')
    config_source.s3_secret_access_key.should eq('secret world')
    config_source.s3_bucket_name.should eq('my-bucket')
  end

  it 'returns the yaml file path as description' do
    config_source.description.should eq(yaml_file_path)
  end
end
