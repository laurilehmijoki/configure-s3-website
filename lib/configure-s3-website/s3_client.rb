require 'base64'
require 'openssl'
require 'digest/sha1'
require 'digest/md5'
require 'net/https'

module ConfigureS3Website
  class S3Client
    def self.configure_website(config_source)
      begin
        enable_website_configuration(config_source)
        make_bucket_readable_to_everyone(config_source)
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
            <Suffix>index.html</Suffix>
          </IndexDocument>
          <ErrorDocument>
            <Key>error.html</Key>
          </ErrorDocument>
        </WebsiteConfiguration>
      |
      call_s3_api(
        path = "/#{config_source.s3_bucket_name}/?website",
        method = Net::HTTP::Put,
        body = body,
        config_source = config_source
      )
      puts "Bucket #{config_source.s3_bucket_name} now functions as a website"
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
      call_s3_api(
        path = "/#{config_source.s3_bucket_name}/?policy",
        method = Net::HTTP::Put,
        body = policy_json,
        config_source = config_source
      )
      puts "Bucket #{config_source.s3_bucket_name} is now readable to the whole world"
    end

    def self.create_bucket(config_source)
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

      call_s3_api(
        path = "/#{config_source.s3_bucket_name}",
        method = Net::HTTP::Put,
        body = body,
        config_source = config_source
      )
      puts "Created bucket %s in the %s Region" %
        [
          config_source.s3_bucket_name,
          endpoint.region
        ]
    end

    def self.call_s3_api(path, method, body, config_source)
      endpoint = Endpoint.new(config_source.s3_endpoint || '')
      date = Time.now.strftime("%a, %d %b %Y %H:%M:%S %Z")
      digest = create_digest(path, method, config_source, date)
      url = "https://#{endpoint.hostname}#{path}"
      uri = URI.parse(url)
      req = method.new(uri.to_s)
      req.initialize_http_header({
        'Date' => date,
        'Content-Type' => '',
        'Content-Length' => body.length.to_s,
        'Authorization' => "AWS %s:%s" % [config_source.s3_access_key_id, digest]
      })
      req.body = body
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      res = http.request(req)
      if res.code.to_i.between? 200, 299
        res
      else
        raise ConfigureS3Website::ErrorParser.create_error res.body
      end
    end

    def self.create_digest(path, method, config_source, date)
      digest = OpenSSL::Digest::Digest.new('sha1')
      method_string = method.to_s.match(/Net::HTTP::(\w+)/)[1].upcase
      can_string = "#{method_string}\n\n\n#{date}\n#{path}"
      hmac = OpenSSL::HMAC.digest(digest, config_source.s3_secret_access_key, can_string)
      signature = Base64.encode64(hmac).strip
    end
  end
end

private

module ConfigureS3Website
  class Endpoint
    attr_reader :region, :location_constraint, :hostname

    def initialize(location_constraint)
      raise InvalidS3LocationConstraintError unless
        location_constraints.has_key?location_constraint
      @region = location_constraints.fetch(location_constraint)[:region]
      @hostname = location_constraints.fetch(location_constraint)[:endpoint]
      @location_constraint = location_constraint
    end

    # http://docs.amazonwebservices.com/general/latest/gr/rande.html#s3_region
    def location_constraints
      {
        ''               => { :region => 'US Standard',                   :endpoint => 's3.amazonaws.com' },
        'us-west-2'      => { :region => 'US West (Oregon)',              :endpoint => 's3-us-west-2.amazonaws.com' },
        'us-west-1'      => { :region => 'US West (Northern California)', :endpoint => 's3-us-west-1.amazonaws.com' },
        'EU'             => { :region => 'EU (Ireland)',                  :endpoint => 's3-eu-west-1.amazonaws.com' },
        'ap-southeast-1' => { :region => 'Asia Pacific (Singapore)',      :endpoint => 's3-ap-southeast-1.amazonaws.com' },
        'ap-southeast-2' => { :region => 'Asia Pacific (Sydney)',         :endpoint => 's3-ap-southeast-2.amazonaws.com' },
        'ap-northeast-1' => { :region => 'Asia Pacific (Tokyo)',          :endpoint => 's3-ap-northeast-1.amazonaws.com' },
        'sa-east-1'      => { :region => 'South America (Sao Paulo)',     :endpoint => 's3-sa-east-1.amazonaws.com' }
      }
    end
  end
end

module ConfigureS3Website
  class ErrorParser
    def self.create_error(amazon_error_xml)
      error_code = amazon_error_xml.delete('\n').match(/<Code>(.*?)<\/Code>/)[1]
      begin
        Object.const_get("#{error_code}Error").new
      rescue NameError
        GenericS3Error.new(amazon_error_xml)
      end
    end
  end
end

class InvalidS3LocationConstraintError < StandardError
end

class NoSuchBucketError < StandardError
end

class GenericS3Error < StandardError
  def initialize(error_message)
    super("AWS API call failed:\n#{error_message}")
  end
end
