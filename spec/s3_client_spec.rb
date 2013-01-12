require 'rspec'
require 'configure-s3-website'

describe ConfigureS3Website::S3Client do
  context '#create_bucket' do
    let(:config_source) {
      mock = double('config_source')
      mock.stub(:s3_endpoint).and_return('invalid-location-constraint')
      mock
    }
    it 'throws an error if the config contains an invalid S3 location constraint' do
      expect {
        extractor = ConfigureS3Website::S3Client.
          send(:create_bucket, config_source)
      }.to raise_error(InvalidS3LocationConstraintError)
    end
  end
end
