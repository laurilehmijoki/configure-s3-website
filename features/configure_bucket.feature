Feature: configure an S3 bucket to function as a website

  @bucket-does-not-exist
  Scenario: The bucket does not yet exist
    Given my config file is in "features/support/sample_config_files/s3_config_with_non-existing_bucket.yml"
    When I run the configure-s3-website command
    Then the output should be
      """
      Created bucket name-of-a-new-bucket
      Bucket name-of-a-new-bucket now functions as a website
      Bucket name-of-a-new-bucket is now readable to the whole world

      """

  @bucket-exists
  Scenario: The bucket already exists
    Given my config file is in "features/support/sample_config_files/s3_config_with_existing_bucket.yml"
    When I run the configure-s3-website command
    Then the output should be
      """
      Bucket name-of-an-existing-bucket now functions as a website
      Bucket name-of-an-existing-bucket is now readable to the whole world

      """
