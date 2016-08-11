require "aws4"

module ConfigureS3Website
  class HttpHelper
    def self.call_s3_api(path, method, body, config_source)
      endpoint = Endpoint.by_config_source(config_source)
      date = Time.now.utc.strftime("%a, %d %b %Y %H:%M:%S %Z")
      self.call_api(
        path,
        method,
        body,
        config_source,
        endpoint.hostname,
        date
      )
    end

    def self.call_cloudfront_api(path, method, body, config_source, headers = {})
      date = Time.now.utc.strftime("%a, %d %b %Y %H:%M:%S %Z")
      self.call_api(
        path,
        method,
        body,
        config_source,
        'cloudfront.amazonaws.com',
        date,
        headers
      )
    end

    private

    def self.call_api(path, method, body, config_source, hostname, date, additional_headers = {})

      # create a signer
      signer = AWS4::Signer.new(
        access_key: config_source.s3_access_key_id,
        secret_key: config_source.s3_secret_access_key,
        region: config_source.s3_endpoint || "us-east-1"
      )

      # build request
      uri = URI("https://#{hostname}/")
      headers_map = {
        "x-amz-content-sha256" => Digest::SHA256.hexdigest(body),
        "x-amz-date" => Time.now.utc.strftime("%Y%m%dT%H%M%SZ"),
        "host" => hostname
      }.merge(additional_headers)

      # sign headers
      headers = signer.sign(method.name.sub("Net::HTTP::", ""), uri, headers_map, body)

puts path
puts additional_headers
puts headers

      url = "https://#{hostname}#{path}"
      uri = URI.parse(url)
      req = method.new(uri.to_s)
      req.initialize_http_header(headers)
      req.body = body
      http = Net::HTTP.new(uri.host, uri.port)
      # http.set_debug_output $stderr
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      res = http.request(req)
      if res.code.to_i.between? 200, 299
        res
      else
        raise ConfigureS3Website::ErrorParser.create_error res.body
      end
    end
  end
end

private

module ConfigureS3Website
  class ErrorParser
    def self.create_error(amazon_error_xml)
      error_code = amazon_error_xml.delete('\n').match(/<Code>(.*?)<\/Code>/)[1]
      begin
        Object.const_get("#{error_code}Error").new
      rescue NameError
        GenericError.new(amazon_error_xml)
      end
    end
  end
end

class GenericError < StandardError
  def initialize(error_message)
    super("AWS API call failed:\n#{error_message}")
  end
end
