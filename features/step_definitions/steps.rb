require 'rspec'

Given /^my config file is in "(.*?)"$/ do |config_file_path|
  @config_file_path = config_file_path
end

When /^I run the configure-s3-website command$/ do
  @console_output = capture_stdout {
    config_source = ConfigureS3Website::FileConfigSource.new(@config_file_path)
    ConfigureS3Website::S3Client.configure_website(config_source)
  }
end

Then /^the output should be$/ do |expected_console_output|
  @console_output.should eq(expected_console_output)
end

Then /^the output should include$/ do |expected_console_output|
  @console_output.should include(expected_console_output)
end

module Kernel
  require 'stringio'

  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    out.string
  ensure
    $stdout = STDOUT
  end
end
