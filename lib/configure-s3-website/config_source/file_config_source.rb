require 'yaml'
require 'erb'

module ConfigureS3Website
  class FileConfigSource < ConfigSource
    def initialize(yaml_file_path)
      @config = parse_config yaml_file_path
    end

    def s3_access_key_id
      @config['s3_id']
    end

    def s3_secret_access_key
      @config['s3_secret']
    end

    def s3_bucket_name
      @config['s3_bucket']
    end

    def s3_endpoint
      @config['s3_endpoint']
    end

    def routing_rules
      @config['routing_rules']
    end

    private

    def parse_config(yaml_file_path)
      config = YAML.load(ERB.new(File.read(yaml_file_path)).result)
      validate_config(config, yaml_file_path)
      config
    end

    def validate_config(config, yaml_file_path)
      required_keys = %w{s3_id s3_secret s3_bucket}
      missing_keys = required_keys.reject do |key| config.keys.include?key end
      unless missing_keys.empty?
        raise "File #{yaml_file_path} does not contain the required key(s) #{missing_keys.join(', ')}"
      end
    end
  end
end
