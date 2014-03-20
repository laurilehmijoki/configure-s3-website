require 'base64'
require 'openssl'
require 'digest/sha1'
require 'digest/md5'
require 'net/https'

module ConfigureS3Website
  class S3Client
    def self.configure_website(options)
      config_source = options[:config_source]
      begin
        enable_website_configuration(config_source)
        make_bucket_readable_to_everyone(config_source)
        configure_bucket_redirects(config_source)
        configure_sub_domain_redirects(config_source)
      rescue NoSuchBucketError
        create_bucket(config_source)
        retry
      end
    end

    private

    def self.enable_website_configuration(config_source)
      body = %|
        <WebsiteConfiguration xmlns='http://s3.amazonaws.com/doc/2006-03-01/'>
          <IndexDocument>
            <Suffix>#{config_source.index_document || "index.html"}</Suffix>
          </IndexDocument>
          <ErrorDocument>
            <Key>#{config_source.error_document || "error.html"}</Key>
          </ErrorDocument>
        </WebsiteConfiguration>
      |
      HttpHelper.call_s3_api(
        path = "/#{config_source.s3_bucket_name}/?website",
        method = Net::HTTP::Put,
        body = body,
        config_source = config_source
      )
      puts "Bucket #{config_source.s3_bucket_name} now functions as a website"
    end

    def self.configure_sub_domain_redirects(config_source)
      # Create buckets for each sub domain
      unless config_source.redirect_domains.nil?
        config_source.redirect_domains.each do |domain|
          begin
            enable_website_domain_redirects(config_source, domain)
          rescue NoSuchBucketError
            create_bucket(config_source, domain)
            retry
          end
        end
      end
    end

    def self.enable_website_domain_redirects(config_source, bucket)
      body = %|
        <WebsiteConfiguration xmlns='http://s3.amazonaws.com/doc/2006-03-01/'>
          <RedirectAllRequestsTo>
            <HostName>#{config_source.s3_bucket_name}</HostName>
          </RedirectAllRequestsTo>
        </WebsiteConfiguration>
      |
      HttpHelper.call_s3_api(
        path = "/#{bucket}/?website",
        method = Net::HTTP::Put,
        body = body,
        config_source = config_source
      )
      puts "Bucket #{bucket} now redirects to #{config_source.s3_bucket_name}"
    end

    def self.get_endpoint(config_source, bucket)
      # Need a reliable way to get the end point of existing buckets so that I
      # can do proper redirects in Route53Client

      # NOTES: I was going to send a request and get back the endpoint for the bucket,
      # but that can't be done with SOAP.  May want to look at moving to a REST API.
      #
      # That is why I ended up just reading the endpoint from the config file as done
      # in the create function below.  In the future, we should query to find the endpoint
      # for a specific bucket.
      endpoint = Endpoint.new(config_source.s3_endpoint || '')

      # return the website endpoint of the location & the hosted_zone_id
      website_endpoint = endpoint.location_constraints[endpoint.location_constraint][:website_endpoint]
      hosted_zone_id = endpoint.location_constraints[endpoint.location_constraint][:hosted_zone_id]
      return website_endpoint, hosted_zone_id
    end

    def self.make_bucket_readable_to_everyone(config_source)
      policy_json = %|{
        "Version":"2008-10-17",
        "Statement":[{
          "Sid":"PublicReadForGetBucketObjects",
          "Effect":"Allow",
          "Principal": { "AWS": "*" },
          "Action":["s3:GetObject"],
          "Resource":["arn:aws:s3:::#{config_source.s3_bucket_name}/*"]
        }]
      }|
      HttpHelper.call_s3_api(
        path = "/#{config_source.s3_bucket_name}/?policy",
        method = Net::HTTP::Put,
        body = policy_json,
        config_source = config_source
      )
      puts "Bucket #{config_source.s3_bucket_name} is now readable to the whole world"
    end

    def self.configure_bucket_redirects(config_source)
      routing_rules = config_source.routing_rules
      if routing_rules.is_a?(Array) && routing_rules.any?
        body = %|
          <WebsiteConfiguration xmlns='http://s3.amazonaws.com/doc/2006-03-01/'>
            <IndexDocument>
              <Suffix>#{config_source.index_document || "index.html"}</Suffix>
            </IndexDocument>
            <ErrorDocument>
              <Key>#{config_source.error_document || "error.html"}</Key>
            </ErrorDocument>
            <RoutingRules>
        |
        routing_rules.each do |routing_rule|
          body << %|
              <RoutingRule>
          |
          body << XmlHelper.hash_to_api_xml(routing_rule, 7)
          body << %|
              </RoutingRule>
          |
        end
        body << %|
            </RoutingRules>
          </WebsiteConfiguration>
        |

        HttpHelper.call_s3_api(
          path = "/#{config_source.s3_bucket_name}/?website",
          method = Net::HTTP::Put,
          body = body,
          config_source = config_source
        )
        puts "#{routing_rules.size} redirects configured for #{config_source.s3_bucket_name} bucket"
      else
        puts "No redirects to configure for #{config_source.s3_bucket_name} bucket"
      end
    end

    def self.create_bucket(config_source, alt_bucket_name=nil)
      bucket_name = config_source.s3_bucket_name
      unless alt_bucket_name.nil?
        bucket_name = alt_bucket_name
      end
      endpoint = Endpoint.new(config_source.s3_endpoint || '')
      body = if endpoint.region == 'US Standard'
               '' # The standard endpoint does not need a location constraint
             else
        %|
          <CreateBucketConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
            <LocationConstraint>#{endpoint.location_constraint}</LocationConstraint>
          </CreateBucketConfiguration >
         |
             end

      HttpHelper.call_s3_api(
        path = "/#{bucket_name}",
        method = Net::HTTP::Put,
        body = body,
        config_source = config_source
      )
      puts "Created bucket %s in the %s Region" %
        [
          bucket_name,
          endpoint.region
        ]
    end
  end
end

private

module ConfigureS3Website
  class Endpoint
    attr_reader :region, :location_constraint, :hostname, :website_hostname

    def initialize(location_constraint)
      raise InvalidS3LocationConstraintError unless location_constraints.has_key? location_constraint
      @region = location_constraints.fetch(location_constraint)[:region]
      @hostname = location_constraints.fetch(location_constraint)[:endpoint]
      @website_hostname = location_constraints.fetch(location_constraint)[:website_endpoint]
      @location_constraint = location_constraint
    end

    # http://docs.amazonwebservices.com/general/latest/gr/rande.html#s3_region
    # Added hosted zone info too (needed for route53 redirects)
    def location_constraints
      {
        ''                => {:region => 'US Standard',                   :endpoint => 's3.amazonaws.com',                :website_endpoint => 's3-website-us-east-1.amazonaws.com',      :hosted_zone_id => 'Z3AQBSTGFYJSTF'},
        'us-west-2'       => {:region => 'US West (Oregon)',              :endpoint => 's3-us-west-2.amazonaws.com',      :website_endpoint => 's3-website-us-west-2.amazonaws.com',      :hosted_zone_id => 'Z3BJ6K6RIION7M'},
        'us-west-1'       => {:region => 'US West (Northern California)', :endpoint => 's3-us-west-1.amazonaws.com',      :website_endpoint => 's3-website-us-west-1.amazonaws.com',      :hosted_zone_id => 'Z2F56UZL2M1ACD'},
        'EU'              => {:region => 'EU (Ireland)',                  :endpoint => 's3-eu-west-1.amazonaws.com',      :website_endpoint => 's3-website-eu-west-1.amazonaws.com',      :hosted_zone_id => 'Z1BKCTXD74EZP#'},
        'ap-southeast-1'  => {:region => 'Asia Pacific (Singapore)',      :endpoint => 's3-ap-southeast-1.amazonaws.com', :website_endpoint => 's3-website-ap-southeast-1.amazonaws.com', :hosted_zone_id => 'Z3O0J2DXBE1FTB'},
        'ap-southeast-2'  => {:region => 'Asia Pacific (Sydney)',         :endpoint => 's3-ap-southeast-2.amazonaws.com', :website_endpoint => 's3-website-ap-southeast-2.amazonaws.com', :hosted_zone_id => 'Z1WCIGYICN2BYD'},
        'ap-northeast-1'  => {:region => 'Asia Pacific (Tokyo)',          :endpoint => 's3-ap-northeast-1.amazonaws.com', :website_endpoint => 's3-website-ap-northeast-1.amazonaws.com', :hosted_zone_id => 'Z2M4EHUR26P7ZW'},
        'sa-east-1'       => {:region => 'South America (Sao Paulo)',     :endpoint => 's3-sa-east-1.amazonaws.com',      :website_endpoint => 's3-website-sa-east-1.amazonaws.com',      :hosted_zone_id => 'Z7KQH4QJS55SO'}
      }
    end

    def self.by_config_source(config_source)
      endpoint = Endpoint.new(config_source.s3_endpoint || '')
    end
  end
end

class InvalidS3LocationConstraintError < StandardError
end

class NoSuchBucketError < StandardError
end
