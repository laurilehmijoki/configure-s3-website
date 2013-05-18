require 'rspec'

When /^I run the configure-s3-website command with parameters$/ do |table|
  from_table = []
  table.hashes.map do |entry|
    { entry[:option] => entry[:value] }
  end.each do |opt|
    from_table << opt.keys.first
    from_table << opt.values.first if opt.values.first
  end
  @console_output = capture_stdout {
    options, optparse = ConfigureS3Website::CLI.optparse_and_options
    optparse.parse! from_table
    ConfigureS3Website::Runner.run(options, stub_stdin)
  }
end

Given /^I answer 'yes' to 'do you want to use CloudFront'$/ do
  @first_stdin_answer = 'y'
end

Then /^the output should be$/ do |expected_console_output|
  @console_output.should eq(expected_console_output)
end

Then /^the output should include$/ do |expected_console_output|
  @console_output.should include(expected_console_output)
end

def stub_stdin
  stdin = stub('std_in')
  stdin.stub(:gets).and_return {
    first_stdin_answer
  }
  stdin
end

# The first prompt asks "do you want to create a CloudFront distro"
def first_stdin_answer
  @first_stdin_answer || 'n'
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
