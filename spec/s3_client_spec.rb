require 'rspec'
require 'configure-s3-website'

describe ConfigureS3Website::S3Client do
  context '#create_bucket with invalid s3_endpoint value' do
    let(:config_source) {
      mock = double('config_source')
      mock.stub(:s3_endpoint).and_return('invalid-location-constraint')
      mock
    }

    it 'throws an error' do
      expect {
        extractor = ConfigureS3Website::S3Client.
          send(:create_bucket, config_source)
      }.to raise_error(InvalidS3LocationConstraintError)
    end
  end

  context '#create_bucket with no s3_endpoint value' do
    let(:config_source) {
      ConfigureS3Website::FileConfigSource.new('spec/sample_files/_config_file.yml')
    }

    it 'calls the S3 api without request body' do
      ConfigureS3Website::S3Client.should_receive(:call_s3_api).
        with(anything(), anything(), '', anything())
      ConfigureS3Website::S3Client.send(:create_bucket,
                                        config_source)
    end
  end

  context '#create_bucket with s3_endpoint value' do
    let(:config_source) {
      ConfigureS3Website::FileConfigSource.new(
        'spec/sample_files/_config_file_oregon.yml'
      )
    }

    it 'calls the S3 api with location constraint XML' do
      ConfigureS3Website::S3Client.should_receive(:call_s3_api).
        with(anything(), anything(),
        %|
          <CreateBucketConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
            <LocationConstraint>us-west-2</LocationConstraint>
          </CreateBucketConfiguration >
         |, anything())
      ConfigureS3Website::S3Client.send(:create_bucket,
                                        config_source)
    end
  end

  context '#hash_to_api_xml' do
    it 'returns an empty string, if the hash is empty' do
      str = ConfigureS3Website::S3Client.send(:hash_to_api_xml,
                                        { })
      str.should eq('')
    end

    it 'capitalises hash keys but not values' do
      str = ConfigureS3Website::S3Client.send(:hash_to_api_xml,
                                        { 'key' => 'value' })
      str.should eq("\n<Key>value</Key>")
    end

    it 'can handle hash values as well' do
      str = ConfigureS3Website::S3Client.send(:hash_to_api_xml,
                                        { 'key' => { 'subkey' => 'subvalue' } })
      str.should eq("\n<Key>\n  <Subkey>subvalue</Subkey></Key>")
    end

    it 'indents' do
      str = ConfigureS3Website::S3Client.send(
        :hash_to_api_xml,
        { 'key' => { 'subkey' => 'subvalue' } },
        indent = 1
      )
      str.should eq("\n  <Key>\n    <Subkey>subvalue</Subkey></Key>")
    end
  end
end
