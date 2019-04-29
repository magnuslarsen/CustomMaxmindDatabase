#!/usr/bin/env perl

use strict;
use warnings;
use MaxMind::DB::Writer::Tree;
use Net::Works::Network;

my $file = '/usr/share/logstash/my-database-name.mmdb';

my %types = (
  accuracy_radius    => 'uint32',
  city               => 'map',
  code               => 'utf8_string',
  continent          => 'map',
  country            => 'map',
  dk                 => 'utf8_string',
  en                 => 'utf8_string',
  geoname_id         => 'uint32',
  iso_code           => 'utf8_string',
  latitude           => 'double',
  location           => 'map',
  longitude          => 'double',
  names              => 'map',
  postal             => 'map',
  time_zone          => 'utf8_string',
);

my $tree = MaxMind::DB::Writer::Tree->new(
  ip_version               => 4,
  record_size              => 24,
  database_type            => 'GeoIP2-City',
  languages                => ['en', 'dk'],
  description              => { en => 'My geoIP database', dk => 'Min geoIP database' },
  map_key_type_callback    => sub { $types{ $_[0] } },
  remove_reserved_networks => 0,
);


# The IP-ranges in this list should be sorted by 1) CIDR notation, 2) IP-address! Lowest first:
# 10.0.0.0/8     => {...}
# 172.16.0.0/16  => {...}
# 172.17.0.0/16  => {...}
# 172.16.0.24/32 => {...}
#
# geoname_id can be found here: http://www.geonames.org/2618424/kobenhavn.html (notice 2618424 in the url)
# longitude and latitude can be found here: https://www.latlong.net/
my %internal_networks = (
  # Can be printed as pretty print
  '192.168.10.0/24' => {
    city => {
      geoname_id => 2618424,
      names      => {
        en => 'Copenhagen',
        dk => 'København',
      },
    },
    country => {
      geoname_id => 2623032,
      iso_code   => 'DK',
      names      => {
        en => 'Denmark',
        dk => 'Danmark',
      },
    },
    location => {
      accuracy_radius => 50,
      latitude        => 55.677191,
      longitude       => 12.568164,
      time_zone       => 'Europe/Copenhagen',
    },
    continent => {
      code       => 'EU',
      geoname_id => 6255148,
      names      => {
        en => 'Europe',
        dk => 'Europa',
      },
    },
    postal => {
      code => '2100'
    }
  },

  # Or as one line
  '192.168.11.0/24' => { city => { geoname_id => 2618424, names      => { en => 'Copenhagen', dk => 'København', }, }, country => { geoname_id => 2623032, iso_code   => 'DK', names      => { en => 'Denmark', dk => 'Danmark', }, }, location => { accuracy_radius => 50, latitude        => 55.677191, longitude       => 12.568164, time_zone       => 'Europe/Copenhagen', }, continent => { code       => 'EU', geoname_id => 6255148, names      => { en => 'Europe', dk => 'Europa', }, },  postal => { code => '2100' } },
);

for my $address (keys %internal_networks) {
  my $network = Net::Works::Network->new_from_string(string => $address);

  $tree->insert_network($network, $internal_networks{$address});
}

open my $fh, '>:raw', $file;
$tree->write_tree($fh);
close $fh;