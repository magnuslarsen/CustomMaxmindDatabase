# Custom Maxmind Database
How to create a custom Maxmind Database, with private IP ranges

I use this in my Elastic-stack installation, your mileage may vary!

# Prerequisites
On Arch Linux based system:
```
# pacman -S libmaxminddb cpanminus
```

On Debian based systems:
```
# add-apt-repository ppa:maxmind/ppa
# apt update
# apt install libmaxminddb0 libmaxminddb-dev mmdb-bin cpanminus
```

For other Liunx based systems, see [the official repository](https://github.com/maxmind/libmaxminddb)

To install the perl modules, simply run this:
```
# cpanm MaxMind::DB::Common MaxMind::DB::Writer
```

# Create the database
Now that the prerequisites are installed, we can start to create the actual database:

Change the `my $file` value to where the database should be created

In the `%internal_networks` you simply just add a key-value pair, in the sample format provided in the script. This replicates the official Maxmind Database format for cities. Additional data can be added, but is not needed for Logstash. Just remember, when adding more data, the `%types` block has to be updated!

To add more languages, just add the [code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements) to the `%types` block, and to the `language` & `description` keys in the `MaxMind::DB::Writer::Tree->new` block

Once your changes are complete, just run the script:
```
$ ./create_database.pl
```

# Logstash configuration
In your Logstash pipeline configuration, add this to your filter block:
```
# Replace [src_ip] with the actual IP-address field of the document

if [src_ip] =~ /(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)|(^192\.168\.)/ {
  geoip {
    source   => "[src_ip]"
    target   => "[geoip]"
    database => "/usr/share/logstash/my-database-name.mmdb"
  }
}
else if [src_ip] =~ /^127\./ {
  # Don't do nothing for localhost
}
else {
  geoip {
    source => "[src_ip]"
    target => "[geoip]"
  }
}
```
This will make all private IP-ranges lookup in your custom database, while all public IP-ranges will use the default Maxmind database