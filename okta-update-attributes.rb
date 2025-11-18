require 'csv'
require 'json'
require 'oktakit'
require 'optparse'

# Bulk update Okta user attributes from a CSV file
# https://github.com/nick-f/okta-update-attributes.rb
# MIT license: https://github.com/nick-f/okta-update-attributes.rb/blob/main/LICENSE

@options = {}
@attribute_keys = []
@profile_attribute_keys = []

@dry_run = true

def token
  # Read API token from 1Password
  # Update this for a way that is secure and acceptable to your organisation
  @token ||= `op read "op://Employee/Okta API token/credential"`
end

# ----------------------------------------------------#
# You probably don't need to edit anything below here #
# ----------------------------------------------------#

OptionParser.new do |opts|
  opts.banner = 'Usage: update_attributes.rb --csv CSV_FILENAME --group GROUP_ID --org OKTA_ORG [--dry_run false]'

  opts.on('--csv CSV_FILENAME', 'CSV filename with attributes to update') do |csv|
    @options[:csv_filename] = csv
  end

  opts.on('--dry-run [BOOLEAN]', 'Dry run mode (default: true)') do |value|
    @dry_run = value.nil? || value == 'true'
  end

  opts.on('--group GROUP_ID', 'Okta group ID') do |group_id|
    @options[:group_id] = group_id
  end

  opts.on('--org OKTA_ORG', 'Okta organization (e.g., dev-123456)') do |org|
    @options[:okta_org] = org
  end
end.parse!

unless @options[:group_id] && @options[:okta_org] && @options[:csv_filename]
  puts 'All of --group and --org and --csv are required.'
  exit 1
end

def client
  @client ||= Oktakit.new(token: token, organization: @options[:okta_org])
end

def parse_headers(csv)
  headers = csv.headers - %w[id email]

  @profile_attribute_keys = headers.select { |column| column.start_with?('profile.') }
  @attribute_keys = headers - @profile_attribute_keys
end

def update_user_profile(user, csv_user)
  attributes_to_update = { partial: true, profile: {} }

  @attribute_keys.each do |attribute|
    attributes_to_update[attribute.to_sym] = csv_user[attribute]
  end

  @profile_attribute_keys.each do |attribute|
    profile_attribute_key = attribute.gsub('profile.', '')

    attributes_to_update[:profile][profile_attribute_key.to_sym] = csv_user[attribute]
  end

  puts "Updating #{user[:profile][:email]}"
  attributes_to_update.each do |key, value|
    next if key == :partial

    puts "  Setting #{key} to #{value}"
  end

  attributes_to_update.delete 'profile' if attributes_to_update[:profile].empty?

  if @dry_run == false
    client.update_user(user[:id], attributes_to_update)
  else
    puts 'Dry run option enabled. Not updating user profile.'
  end
end

def update_users
  okta_users = client.list_group_members(@options[:group_id]).first
  csv_file = CSV.read(@options[:csv_filename], headers: true)
  parse_headers csv_file

  # Exit early if there is an error and display the error to help you work out what went wrong
  if okta_users.is_a?(Sawyer::Resource) && okta_users.dig(:errorCode)
    puts JSON.pretty_generate(okta_users.to_hash)

    exit 1
  end

  okta_users.each do |user|
    next if user[:status] == 'DEPROVISIONED'

    csv_user = csv_file.find { |row| row['email'] == user[:profile][:email] }

    update_user_profile(user, csv_user) if csv_user
  end
end

update_users
