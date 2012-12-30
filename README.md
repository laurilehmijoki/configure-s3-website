# Configure-s3-website

Configure an AWS S3 bucket to function as a website. Easily from the
command-line interface.

The Ruby gem `configure-s3-website` can configure an S3 bucket to function as a
website. The bucket may or may not exist. If the bucket does not exist,
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

See file LICENSE.
