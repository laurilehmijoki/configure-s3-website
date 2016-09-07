require 'base64'
require 'openssl'
require 'digest/sha1'
require 'digest/md5'
require 'net/https'
require 'aws-sdk'

module ConfigureS3Website
  class S3Client
    def self.configure_website(options)
      config_source = options[:config_source]
      begin
        enable_website_configuration(config_source)
        make_bucket_readable_to_everyone(config_source)
      rescue Aws::S3::Errors::NoSuchBucket
        create_bucket(config_source)
        retry
      end
    end

    private

    def self.s3(config_source)
      s3 = Aws::S3::Client.new(
        region: config_source.s3_endpoint,
        access_key_id: config_source.s3_access_key_id,
        secret_access_key: config_source.s3_secret_access_key
      )
    end

    def self.enable_website_configuration(config_source)
      routing_rules =
        if config_source.routing_rules && config_source.routing_rules.is_a?(Array)
          config_source.routing_rules.map { |rule|
            Hash[
              rule.map { |rule_key, rule_value|
                [
                  rule_key.to_sym,
                  Hash[ # Assume that each rule value is a Hash
                    rule_value.map { |redirect_rule_key, redirect_rule_value|
                      [
                        redirect_rule_key.to_sym,
                        redirect_rule_key == "http_redirect_code" ?
                          redirect_rule_value.to_s
                          #redirect_rule_value.to_s  # Permit numeric redirect values in the YAML config file. (The S3 API does not allow numeric redirect values, hence this block of code.)
                          :
                          redirect_rule_value
                      ]
                    }
                  ]
                ]
              }
            ]
          }
        else
          nil
        end
      s3(config_source).put_bucket_website({
        bucket: config_source.s3_bucket_name,
        website_configuration: {
          index_document: {
            suffix: config_source.index_document || "index.html"
          },
          error_document: {
            key: config_source.error_document || "error.html"
          },
          routing_rules: routing_rules
        }
      })
      puts "Bucket #{config_source.s3_bucket_name} now functions as a website"
      if routing_rules && routing_rules.any?
        puts "#{routing_rules.size} redirects configured for #{config_source.s3_bucket_name} bucket"
      else
        puts "No redirects to configure for #{config_source.s3_bucket_name} bucket"
      end
    end

    def self.make_bucket_readable_to_everyone(config_source)
      s3(config_source).put_bucket_policy({
        bucket: config_source.s3_bucket_name,
        policy: %|{
          "Version":"2008-10-17",
          "Statement":[{
            "Sid":"PublicReadForGetBucketObjects",
            "Effect":"Allow",
            "Principal": { "AWS": "*" },
            "Action":["s3:GetObject"],
            "Resource":["arn:aws:s3:::#{config_source.s3_bucket_name}/*"]
          }]
        }|
      })
      puts "Bucket #{config_source.s3_bucket_name} is now readable to the whole world"
    end

    def self.create_bucket(config_source)
      s3(config_source).create_bucket({
        bucket: config_source.s3_bucket_name,
        create_bucket_configuration: 
        if config_source.s3_endpoint && config_source.s3_endpoint != 'us-east-1'
          {
            location_constraint: config_source.s3_endpoint
          }
        else
          nil
        end
      })
      puts "Created bucket %s in the %s Region" %
        [
          config_source.s3_bucket_name,
          config_source.s3_endpoint
        ]
    end
  end
end

