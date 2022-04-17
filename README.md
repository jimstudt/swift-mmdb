# swift-mmdb

A native swift library for reading MMDB files, which include GeoLite2 files 
for mapping IP addresses to countries.

## Why?

My personal blog keeps getting run over by spam comments which exclusively 
come from two countries. I want to prevent anonymous comments from just those
countries.

Debian has a `geoip-database` package which includes data from 
[MaxMind's GeoLite2 database)](https://dev.maxmind.com/geoip/geolite2-free-geolocation-data)
so that seems a good start. Sadly they only Swifgt library I found was a wrapper of the
C library, and since I develop under macos and deploy on Debian, I didn't want to wrestle
with the nusiance that is to build.

Since MaxMind publishes [MaxMind DB File Format Specification](https://maxmind.github.io/MaxMind-DB/), 
how hard could it be to just read that directly…




