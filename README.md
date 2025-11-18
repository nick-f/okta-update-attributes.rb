# Okta Update Attributes

Ever needed to backfill a bunch of data in Okta but never had an easy way to do it? Now you do.

## Installation

There are two pre-requisites:

1. a recent-ish version of Ruby  
    - This script was written and tested using Ruby 3.4.7, but will likely just work with newer and
      slightly older versions of Ruby.
2. the [Oktakit gem][] should be installed

### Generating an API token

Update the `token` method near the top of the script to retrieve the Okta API token in a way that meets your security posture.

See Okta's documentation for instructions on how to [create an API token][].

[Oktakit gem]: https://github.com/shopify/oktakit
[create an API token]: https://developer.okta.com/docs/guides/create-an-api-token/main/

## Usage

Pass in the options relevant to your environment.

```shell
ruby okta-update-attributes.rb --group GROUP_ID --org OKTA_TENANT --csv update.csv
```

By default the script runs in dry run mode, meaning no changes will be made but the output of what will change is shown.
To make the changes add the `--dry-run false` option to the command.

```diff
- ruby okta-update-attributes.rb --group GROUP_ID --org OKTA_TENANT --csv update.csv
+ ruby okta-update-attributes.rb --group GROUP_ID --org OKTA_TENANT --csv update.csv --dry-run false
```

### Group ID

This should be the Okta ID for the group that is used as the scope of the users to change.

If there are users included in the CSV file that are not in this group, they will not be updated.

#### Finding the group ID in the UI

- Open the Okta admin page for your org
- Navigate to the group either via the global search or from Directory -> Groups
- Copy the final portion of the URL

#### Finding the group ID using the API

The ID field returned by the Okta API is the value you want.

### CSV format

There is only one required column in the CSV format: `email`. This should be the email address that identifies the Okta user record.

Updating user fields is as simple as specifying the attribute name to update.

```csv
email,firstName
nick-f@example.com,Nick
```

When updating profile fields prefix the field name with `profile.`.

```csv
email,profile.department
nick-f@example.com,Engineering
```
