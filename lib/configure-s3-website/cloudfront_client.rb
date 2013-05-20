require "rexml/document"
require "rexml/xpath"

module ConfigureS3Website
  class CloudFrontClient
    def self.create_distribution_if_user_agrees(options, standard_input)
      puts 'Do you want to deliver your website via CloudFront, the CDN of Amazon? [y/N]'
      case standard_input.gets.chomp
      when /(y|Y)/ then do_create_distribution options
      end
    end

    private

    def self.do_create_distribution(options)
      config_source = options[:config_source]
      response = HttpHelper.call_cloudfront_api(
        path = '/2012-07-01/distribution',
        method = Net::HTTP::Post,
        body = (distribution_config_xml config_source),
        config_source = config_source
      )
      response_xml = REXML::Document.new(response.body)
      dist_id = REXML::XPath.first(response_xml, '/Distribution/Id').get_text
      print_report_on_new_dist response_xml, dist_id, options
      config_source.cloudfront_distribution_id = dist_id.to_s
      puts "  Added setting 'cloudfront_distribution_id: #{dist_id}' into #{config_source.description}"
    end

    def self.print_report_on_new_dist(response_xml, dist_id, options)
      config_source = options[:config_source]
      domain_name = REXML::XPath.first(response_xml, '/Distribution/DomainName').get_text
      puts "  The distribution #{dist_id} at #{domain_name} now delivers the bucket #{config_source.s3_bucket_name}"
      puts '    Please allow up to 15 minutes for the distribution to initialise'
      puts '    For more information on the distribution, see https://console.aws.amazon.com/cloudfront'
      if options[:verbose]
        puts '  Below is the response from the CloudFront API:'
        print_verbose(response_xml, left_padding = 4)
      end
    end

    def self.print_verbose(response_xml, left_padding)
      lines = []
      response_xml.write(lines, 2)
      padding = ""
      left_padding.times { padding << " " }
      puts lines.join().
        gsub(/^/, "" + padding).
        gsub(/\s$/, "")
    end

    def self.distribution_config_xml(config_source, custom_cf_settings = {})
      %|
      <DistributionConfig xmlns="http://cloudfront.amazonaws.com/doc/2012-07-01/">
        <Origins>
          <Quantity>1</Quantity>
          <Items>
            <Origin>
              <Id>#{origin_id config_source}</Id>
              <DomainName>
                #{config_source.s3_bucket_name}.#{Endpoint.by_config_source(config_source).hostname}
              </DomainName>
              <S3OriginConfig>
                <OriginAccessIdentity></OriginAccessIdentity>
              </S3OriginConfig>
            </Origin>
          </Items>
        </Origins>
        #{
          XmlHelper.hash_to_api_xml(
            default_cloudfront_settings(config_source).merge custom_cf_settings
          )
        }
      </DistributionConfig>
      |
    end

    def self.default_cloudfront_settings(config_source)
      {
        'caller_reference' => 'configure-s3-website gem ' + Time.now.to_s,
        'default_root_object' => 'index.html',
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
          'min_TTL' => (60 * 60 * 24)
        },
        'cache_behaviors' => {
          'quantity' => '0'
        },
        'price_class' => 'PriceClass_All'
      }
    end

    def self.origin_id(config_source)
      "#{config_source.s3_bucket_name}-S3-origin"
    end
  end
end
