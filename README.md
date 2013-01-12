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

### Specifying a non-standard S3 endpoint

By default, `configure-s3-website` creates the S3 website into the US Standard
region.

If you want to create the website into another region, add into the
configuration file a row like this:

    s3_endpoint: EU

The valid *s3_endpoint* values consist of the [S3 location constraint
values](http://docs.amazonwebservices.com/general/latest/gr/rande.html#s3_region).

## How does `configure-s3-website` work?

It calls the [PUT Bucket
website](http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTwebsite.html)
API with the following XML:

```xml
<WebsiteConfiguration xmlns='http://s3.amazonaws.com/doc/2006-03-01/'>
  <IndexDocument>
    <Suffix>index.html</Suffix>
  </IndexDocument>
  <ErrorDocument>
    <Key>error.html</Key>
  </ErrorDocument>
</WebsiteConfiguration>
```

Then **it makes all the objects on the bucket visible to the whole world** by
calling the [PUT Bucket
policy](http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTBucketPUTpolicy.html)
API with the following JSON:

```json
{
  "Version":"2008-10-17",
  "Statement":[{
    "Sid":"PublicReadForGetBucketObjects",
    "Effect":"Allow",
    "Principal": { "AWS": "*" },
    "Action":["s3:GetObject"],
    "Resource":["arn:aws:s3:::your-bucket-name/*"]
  }]
}
```

## License

See the file LICENSE.
