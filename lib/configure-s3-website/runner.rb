module ConfigureS3Website
  class Runner
    def self.run(options, standard_input = STDIN)
      S3Client.configure_website options
      unless user_already_has_cf_configured options
        CloudFrontClient.create_distribution_if_user_agrees options, standard_input
      end
    end

    private

    def self.user_already_has_cf_configured(options)
      config_source = options[:config_source]
      config_source.cloudfront_distribution_id
    end
  end
end
