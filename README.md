# Debian preseed iso builder
This script downloads Debians's iso and makes it auto-install

## Getting Started
Just run `./build.sh`
![](https://github.com/delfer/debian-preseed-iso/blob/master/install.gif)

## Prerequisites
* *xorriso* installed \
  `sudo apt install xorriso`
* preseed.cfg
  1. Look at example http://www.debian.org/releases/stretch/example-preseed.txt
  2. Read manual https://www.debian.org/releases/stable/i386/apb.html
  3. Install manually and then export preseed answers: \
     `sudo apt-get install debconf-utils` \
     `debconf-get-selections --installer >> preseed.cfg`

## About attached preseed.cfg
* Configured for Russian language
* Install base system with ssh-server
* Use entire disk as LVM for root partition
* Don't create swap partition
* Use static IP configuration
