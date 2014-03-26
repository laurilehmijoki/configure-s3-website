Feature: redirect domains

  @redirect-domains
  Scenario: The user wants to redirect from "http://www.mysite.com" to "http://mysite.com"
    Given I answer 'yes' to 'do you want to use CloudFront'
    When I run the configure-s3-website command with parameters
      | option        | value                                                     |
      | --config-file | features/support/sample_config_files/redirect_domains.yml |
    Then the output should be
      """
      Created bucket morninglightmountain.com in the US Standard Region
      Bucket morninglightmountain.com now functions as a website
      Bucket morninglightmountain.com is now readable to the whole world
      No redirects to configure for morninglightmountain.com bucket
      Created bucket www.morninglightmountain.com in the US Standard Region
      Bucket www.morninglightmountain.com now redirects to morninglightmountain.com
      Do you want to deliver your website via CloudFront, the CDN of Amazon? [y/N]
        The distribution E2P3503QUJ2Y33 at d1bogqjo2s79ms.cloudfront.net now delivers the origin morninglightmountain.com.s3-website-us-east-1.amazonaws.com
          Please allow up to 15 minutes for the distribution to initialise
          For more information on the distribution, see https://console.aws.amazon.com/cloudfront
        Added setting 'cloudfront_distribution_id: E2P3503QUJ2Y33' into features/support/sample_config_files/redirect_domains.yml

      """

  @redirect-domains-and-cloudfront-exists
  Scenario: The user re-applies a configuration that contains both redirect domains and a CloudFront distribution
    When I run the configure-s3-website command with parameters
      | option        | value                                                                           |
      | --config-file | features/support/sample_config_files/redirect_domains_and_cloudfront_exists.yml |
    Then the output should be
      """
      Bucket morninglightmountain.com now functions as a website
      Bucket morninglightmountain.com is now readable to the whole world
      No redirects to configure for morninglightmountain.com bucket
      Bucket www.morninglightmountain.com now redirects to morninglightmountain.com

      """
