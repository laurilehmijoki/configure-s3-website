require 'rspec'
require 'configure-s3-website'

describe ConfigureS3Website::FileConfigSource do
  it 'can parse files that contain eRuby code' do
    extractor = ConfigureS3Website::FileConfigSource.new('spec/sample_files/_config_file_with_eruby.yml')
    extractor.s3_access_key_id.should eq('hello world')
    extractor.s3_secret_access_key.should eq('secret world')
    extractor.s3_bucket_name.should eq('my-bucket')
  end
end
