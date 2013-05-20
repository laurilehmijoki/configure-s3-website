module ConfigureS3Website
  class CLI
    def self.optparse_and_options
      options = {}
      optparse = OptionParser.new do |opts|
        opts.banner = banner
        opts.on('-f', '--config-file FILE',
                'Pick credentials and the S3 bucket name from a config file') do
                |yaml_file_path|
          options[:config_source] =
            ConfigureS3Website::FileConfigSource.new yaml_file_path
        end
        opts.on('-v', '--verbose', 'Print more stuff') do
          options[:verbose] = true
        end
        opts.on('--help', 'Display this screen') do
          puts opts
          exit
        end
      end
      [options, optparse]
    end

    private

    def self.banner
      %|Usage: #{File.basename(__FILE__)} arguments

Configure your S3 bucket to function as a web site

Arguments:
      |
    end
  end
end
