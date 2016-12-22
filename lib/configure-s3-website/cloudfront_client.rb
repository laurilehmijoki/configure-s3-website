require "aws-sdk"
require 'deep_merge'

module ConfigureS3Website
  class CloudFrontClient
    def self.apply_distribution_config(options)
      config_source = options[:config_source]
      puts "Detected an existing CloudFront distribution (id #{config_source.cloudfront_distribution_id}) ..."

      live_config = cloudfront(config_source).get_distribution({
        id: options[:config_source].cloudfront_distribution_id
      })

      custom_distribution_config = config_source.cloudfront_distribution_config || {}
      if custom_distribution_config.empty?
        return
      end
      live_distribution_config = live_config.distribution.distribution_config.to_hash
      custom_distribution_config_with_caller_ref = live_distribution_config.deep_merge!(
        deep_symbolize(custom_distribution_config.merge({
          caller_reference: live_config.distribution.distribution_config.caller_reference,
          comment: 'Updated by the configure-s3-website gem'
        })),
        ConfigureS3Website::deep_merge_options
      )
      cloudfront(config_source).update_distribution({
        distribution_config: custom_distribution_config_with_caller_ref,
        id: options[:config_source].cloudfront_distribution_id,
        if_match: live_config.etag
      })

      print_report_on_custom_distribution_config custom_distribution_config_with_caller_ref
    end

    def self.create_distribution_if_user_agrees(options, standard_input)
      if options['autocreate-cloudfront-dist'] and options[:headless]
        puts 'Creating a CloudFront distribution for your S3 website ...'
        create_distribution options
      elsif options[:headless]
        # Do nothing
      else
        puts 'Do you want to deliver your website via CloudFront, Amazon’s CDN service? [y/N]'
        case standard_input.gets.chomp
        when /(y|Y)/ then create_distribution options
        end
      end
    end

    private

    def self.cloudfront(config_source)
      Aws::CloudFront::Client.new(
        region: 'us-east-1',
        access_key_id: config_source.s3_access_key_id,
        secret_access_key: config_source.s3_secret_access_key
      )
    end

    def self.create_distribution(options)
      config_source = options[:config_source]
      custom_distribution_config = config_source.cloudfront_distribution_config || {}
      distribution = cloudfront(config_source).create_distribution(
        deep_symbolize new_distribution_config(config_source, custom_distribution_config)
      ).distribution
      dist_id = distribution.id
      print_report_on_new_dist distribution, dist_id, options, config_source
      config_source.cloudfront_distribution_id = dist_id.to_s
      puts "  Added setting 'cloudfront_distribution_id: #{dist_id}' into #{config_source.description}"
      unless custom_distribution_config.empty?
        print_report_on_custom_distribution_config custom_distribution_config
      end
    end

    def self.print_report_on_custom_distribution_config(custom_distribution_config, left_padding = 4)
      puts '  Applied custom distribution settings:'
      puts custom_distribution_config.
        to_yaml.
        to_s.
        gsub("---\n", '').
        gsub(/^/, padding(left_padding))
    end

    def self.print_report_on_new_dist(distribution, dist_id, options, config_source)
      config_source = options[:config_source]
      puts "  The distribution #{dist_id} at #{distribution.domain_name} now delivers the origin #{distribution.distribution_config.origins.items[0].domain_name}"
      puts '    Please allow up to 15 minutes for the distribution to initialise'
      puts '    For more information on the distribution, see https://console.aws.amazon.com/cloudfront'
      if options[:verbose]
        puts '  Below is the response from the CloudFront API:'
        puts distribution
      end
    end

    def self.new_distribution_config(config_source, custom_cf_settings)
      {
        'distribution_config' => {
          'caller_reference' => 'configure-s3-website gem ' + Time.now.to_s,
          'default_root_object' => 'index.html',
          'origins' => {
            'quantity' => 1,
            'items' => [
              {
                'id' => (origin_id config_source),
                'domain_name' => "#{config_source.s3_bucket_name}.#{EndpointHelper.s3_website_hostname(config_source.s3_endpoint)}",
                'custom_origin_config' => {
                  'http_port' => 80,
                  'https_port' => 443,
                  'origin_protocol_policy' => 'http-only'
                }
              }
            ]
          },
          'logging' => {
            'enabled' => 'false',
            'include_cookies' => 'false',
            'bucket' => '',
            'prefix' => ''
          },
          'enabled' => 'true',
          'comment' => 'Created by the configure-s3-website gem',
          'aliases' => {
            'quantity' => '0'
          },
          'default_cache_behavior' => {
            'target_origin_id' => (origin_id config_source),
            'trusted_signers' => {
              'enabled' => 'false',
              'quantity' => '0'
            },
            'forwarded_values' => {
              'query_string' => 'true',
              'cookies' => {
                'forward' => 'all'
              }
            },
            'viewer_protocol_policy' => 'allow-all',
            'min_ttl' => '86400'
          },
          'cache_behaviors' => {
            'quantity' => '0'
          },
          'price_class' => 'PriceClass_All'
        }.deep_merge!(custom_cf_settings, ConfigureS3Website::deep_merge_options)
      }
    end

    def self.origin_id(config_source)
      "#{config_source.s3_bucket_name}-S3-origin"
    end

    def self.padding(amount)
      padding = ''
      amount.times { padding << " " }
      padding
    end

    def self.deep_symbolize(value)
      if value.is_a? Hash
        Hash[value.map { |k,v| [k.to_sym, deep_symbolize(v)] }]
      elsif value.is_a? Array
        value.map { |v| deep_symbolize(v) }
      else
        value
      end
    end
  end
  def self.deep_merge_options
    {
      :merge_hash_arrays => true
    }
  end
end
