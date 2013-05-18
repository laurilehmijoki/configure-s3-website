module ConfigureS3Website
  class Runner
    def self.run(options, standard_input = STDIN)
      S3Client.configure_website options
      CloudFrontClient.create_distribution_if_user_agrees options, standard_input
    end
  end
end
