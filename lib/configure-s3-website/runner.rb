module ConfigureS3Website
  class Runner
    def self.run(options, standard_input = STDIN)
      S3Client.configure_website options
      maybe_create_or_update_cloudfront options, standard_input
      maybe_create_or_update_route53 options, standard_input
    end

    private

    def self.maybe_create_or_update_cloudfront(options, standard_input)
      unless user_already_has_cf_configured options
        CloudFrontClient.create_distribution_if_user_agrees options, standard_input
        return
      end
      if user_already_has_cf_configured(options) and user_has_custom_cf_dist_config(options)
        CloudFrontClient.apply_distribution_config options
        return
      end
    end

    def self.maybe_create_or_update_route53(options, standard_input)
      route53_enabled = options[:config_source].route53_enabled
      unless route53_enabled.nil? or not route53_enabled
        Route53Client.apply(options)
      end
    end

    def self.user_already_has_cf_configured(options)
      config_source = options[:config_source]
      config_source.cloudfront_distribution_id
    end

    def self.user_has_custom_cf_dist_config(options)
      config_source = options[:config_source]
      config_source.cloudfront_distribution_config
    end
  end
end
