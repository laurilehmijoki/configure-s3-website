require 'route53'

module ConfigureS3Website
  class Route53Client
    def initialize(options)
      @config_source = options[:config_source]

      # Set up the connection to route53 and store in @conn
      @conn = Route53::Connection.new(@config_source.s3_access_key_id, @config_source.s3_secret_access_key)
    end

    def apply

      # Set the domain for the site
      domain = get_domain_name @config_source.s3_bucket_name

      # Check to ensure that there is a hosted zone for the given domain
      zone = check_and_create_hosted_zone_if_user_agrees domain
      if not zone.nil?

        # Create a route for the main s3_bucket
        check_and_create_route(@config_source.s3_bucket_name, zone)

        # Create routes for redirect urls
        unless @config_source.redirect_domains.nil?
          check_and_create_redirect_routes(@config_source.redirect_domains)
        end
      end
    end

    private

    def self.check_and_create_redirect_routes(redirect_domains)
      redirect_domains.each do |url|
        # check to see if the domain of the redirect_urls matches the domain of the main bucket (s3_bucket_name)
        redirect_domain = get_domain_name url
        if redirect_domain != domain
          redirect_zone = check_and_create_hosted_zone_if_user_agrees redirect_domain
          unless redirect_zone.nil?
            # Just create the route here, there is no need to check if it exists because we just created the
            # new zone.
            create_route(url, redirect_zone)
          end
        else
          # Check to see if the route exists and create route to the specific redirect_url
          check_and_create_route(url, zone)
        end
      end
    end

    def self.check_and_create_route(url, zone)
      if route_exists?(url, zone)
        # Ask the user if he/she wants to delete & recreate the route
        puts "A route already exists for #{url}"
        puts 'Do you want to re-create the existing entry and point it to your s3 bucket/Cloud Front?[y/N]'
        case gets.chomp
          when /(y|Y)/
            create_route(url, zone) if remove_route(url, zone)
        end
      else
        create_route(url, zone)
      end
    end

    def self.remove_route(url, zone)
      records = zone.get_records
      records = records.select {|rec| rec.name.include? url}
      if records.length == 1
        domain_record = records[0]
        domain_record.delete
        true
      else
        puts "Unable to remove record for #{url}, please do it in the AWS Management console."
        false
      end
    end

    def self.create_route(url, zone)

      if not @config_source.cloudfront_distribution_id.nil? and url == @config_source.s3_bucket_name
        # Then this needs to point to Cloud front
        # From http://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html#change-rrsets-request-hosted-zone-id
        # and http://docs.aws.amazon.com/general/latest/gr/rande.html#cf_region
        hosted_zone_id = 'Z2FDTNDATAQYW2'
        redirect_url = 'cloudfront.amazonaws.com.'
      else
        # Get the location of the s3-bucket (need a URL for the domain redirect)
        redirect_url, hosted_zone_id = S3Client.get_endpoint(@config_source, @config_source.s3_bucket_name)
      end
      new_record = Route53::DNSRecord.new(url, 'A', '', [redirect_url], zone, hosted_zone_id)
      resp = new_record.create
      if resp.error?
        puts resp
      else
        puts "Route53 Entry created for: #{url} pointing to #{redirect_url}"
      end
    end

    def self.get_domain_name(bucket)
      bucket_name = bucket
      parts = bucket_name.split('.')
      domain = "#{parts.last(2).join('.')}."
    end

    def self.hosted_zone_exits?(domain)
      # Check to see if the user has already created a hosted zone

      zone = get_zone domain

      not zone.nil?
    end

    def self.get_zone(domain)
      # Get an array of the user's zones (usually one per domain)
      zones = @conn.get_zones

      # Try and find the zone for the domain of the current blog
      zone = zones.select { |zone| zone.name == domain}[0]
    end

    def self.check_and_create_hosted_zone_if_user_agrees(domain)
      zone_exists = ask_user_to_create_zone
      if zone_exists
        zone = get_zone domain
      else
        puts "Please create a hosted zone for #{domain} at: \n" +
             "https://console.aws.amazon.com/route53/home before \n" +
             "trying to auto-configure route53."
        zone = nil
      end
      return zone
    end

    def ask_user_to_create_zone(domain)
      if not hosted_zone_exits?(domain) # We need to have the user create the zone first.
        puts "A hosted zone for #{domain} does not exist, create one now?[y/N]?"
        case gets.chomp
          when /(y|Y)/
            # Create a new zone object
            zone = Route53::Zone.new(domain, nil, @conn)
            # Send the request to Amazon
            resp = zone.create_zone
            if resp.error? # The response failed, show the user the error
              puts resp
              zone_exists = false
            else
              while resp.pending?
              sleep 1 # Wait for the response to finish so that we can create routes on the zone
              end
              zone_exists = true
            end
          else # The user doesn't want to create a zone at this time
          zone_exists = false
        end
      else # the domain already exists
        zone_exists = true
      end
      zone_exists
    end

    def self.route_exists?(url, zone)
      # checks to see if the route already is in DNS (maybe it has been set to something other than s3)
      records = zone.get_records
      records.each do |rec|
        if rec.name.include? url
          return true
        end
      end
      # if it's not found, return false
      false
    end

  end
end
