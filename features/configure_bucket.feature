Feature: configure an S3 bucket to function as a website

  @bucket-does-not-exist
  Scenario: The bucket does not yet exist
    Given my config file is in "features/support/sample_config_files/s3_config_with_non-existing_bucket.yml"
    When I run the configure-s3-website command
    Then the output should be
      """
      Created bucket name-of-a-new-bucket in the US Standard Region
      Bucket name-of-a-new-bucket now functions as a website
      Bucket name-of-a-new-bucket is now readable to the whole world
      No redirects to configure for name-of-a-new-bucket bucket

      """

  @bucket-does-not-exist
  Scenario: The configuration does not contain the 's3_endpoint' setting
    Given my config file is in "features/support/sample_config_files/s3_config_with_non-existing_bucket.yml"
    When I run the configure-s3-website command
    Then the output should include
      """
      Created bucket name-of-a-new-bucket in the US Standard Region
      """

  @bucket-does-not-exist-in-tokyo
  Scenario: Create bucket into the Tokyo region
    Given my config file is in "features/support/sample_config_files/endpoint_tokyo.yml"
    When I run the configure-s3-website command
    Then the output should include
      """
      Created bucket name-of-a-new-bucket in the Asia Pacific (Tokyo) Region
      """

  @bucket-exists
  Scenario: The bucket already exists
    Given my config file is in "features/support/sample_config_files/s3_config_with_existing_bucket.yml"
    When I run the configure-s3-website command
    Then the output should be
      """
      Bucket name-of-an-existing-bucket now functions as a website
      Bucket name-of-an-existing-bucket is now readable to the whole world
      No redirects to configure for name-of-an-existing-bucket bucket

      """

  @redirects
  Scenario: The user wants to configure redirects for the S3 website
    Given my config file is in "features/support/sample_config_files/redirects.yml"
    When I run the configure-s3-website command
    Then the output should be
      """
      Created bucket website-with-redirects in the US Standard Region
      Bucket website-with-redirects now functions as a website
      Bucket website-with-redirects is now readable to the whole world
      1 redirects configured for website-with-redirects bucket

      """
