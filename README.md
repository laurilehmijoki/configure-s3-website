# Configure-s3-website

[![Build Status](https://secure.travis-ci.org/laurilehmijoki/configure-s3-website.png)](http://travis-ci.org/laurilehmijoki/configure-s3-website)
[![Gem Version](https://fury-badge.herokuapp.com/rb/configure-s3-website.png)](http://badge.fury.io/rb/configure-s3-website)

Configure an AWS S3 bucket to function as a website. Easily from the
command-line interface.

The bucket may or may not exist. If the bucket does not exist,
`configure-s3-website` will create it.

## Install

    gem install configure-s3-website

## Usage

Create a file that contains the S3 credentials and the name of the bucket:

```yaml
s3_id: your-aws-access-key
s3_secret: your-aws-secret-key
s3_bucket: name-of-your-bucket
```

Save the file (as *config.yml*, for example). Now you are ready to go. Run the
following command:

    configure-s3-website --config-file config.yml

Congratulations! You now have an S3 bucket that can act as a website server for
you.

### Deliver your website via CloudFront

`configure-s3-website` can create a CloudFront distribution for you. It will ask
you whether you want to deliver your website via the CDN. If you answer yes,
`configure-s3-website` will create a CloudFront distribution that has the
configured S3 bucket as its origin. In addition, it will add the entry
`cloudfront_distribution_id: [id-of-the-new-distribution]` into your
configuration file.

CloudFront can be configured in various ways. However, the distribution created
by `configure-s3-website` uses sensible defaults for an S3-based website and
thus saves you the burden of figuring out how to configure CloudFront. For
example, it assumes that your default root object is *index.html*.

You can see all the settings this gem applies on the new distribution by running
the command in verbose mode:

    configure-s3-website --config-file config.yml --verbose

If you want to, you can tune the distribution settings on the management console
at <https://console.aws.amazon.com/cloudfront>.

### Specifying a non-standard S3 endpoint

By default, `configure-s3-website` creates the S3 website into the US Standard
region.

If you want to create the website into another region, add into the
configuration file a row like this:

    s3_endpoint: EU

The valid *s3_endpoint* values consist of the [S3 location constraint
values](http://docs.amazonwebservices.com/general/latest/gr/rande.html#s3_region).

### Configuring redirects

You can configure redirects on your S3 website by adding `routing_rules` into
the config file.

Here is an example:

````yaml
routing_rules:
  - condition:
      key_prefix_equals: blog/some_path
    redirect:
      host_name: blog.example.com
      replace_key_prefix_with: some_new_path/
      http_redirect_code: 301
````

You can use any routing rule property that the [REST
API](http://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html)
supports. All you have to do is to replace the uppercase letter in AWS XML with
an underscore and an undercase version of the same letter. For example,
`KeyPrefixEquals` becomes `key_prefix_equals` in the config file.

Apply the rules by invoking `configure-s3-website --config [your-config-file]`
on the command-line interface. You can verify the results by looking at your
bucket on the [S3 console](https://console.aws.amazon.com/s3/home).

## How does `configure-s3-website` work?

`configure-s3-website` uses the AWS REST API of S3 for creating and modifying
the bucket. In brief, it does the following things:

1. Create a bucket for you (if it does not yet exist)
2. Add the website configuration on the bucket via the [website REST
   API](http://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html)
3. Make the bucket **readable to the whole world**
4. Apply the redirect (a.k.a routing) rules on the bucket website

## Development

* This project uses [Semantic Versioning](http://semver.org)

## Credit

Created by Lauri Lehmijoki.

Big thanks to the following contributors (in alphabetical order):

* SlawD
* Steve Schwartz

## License

See the file LICENSE.
