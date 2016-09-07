module ConfigureS3Website
  class EndpointHelper
    def self.s3_website_hostname(region)
      if old_regions.include?(region)
        "s3-website-#{region}.amazonaws.com"
      else
        "s3-website.#{region}.amazonaws.com"
      end
    end

    private

    def self.old_regions
      [
        'us-east-1',
        'us-west-1',
        'us-west-2',
        'ap-southeast-1',
        'ap-southeast-2',
        'ap-northeast-1',
        'eu-west-1',
        'sa-east-1'
      ]
    end
  end
end
