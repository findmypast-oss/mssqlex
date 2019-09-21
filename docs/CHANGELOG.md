# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## 2.0.0-beta.0 - 2019-09-21

### Changed

* Update to Ecto 3 / DBConnection 2
* A large number of other changes to accommodate this update (notably type handling)

## 1.1.0 - 2018-05-23

### Added

* Allow configuring the encryption parameters

## 1.0.0 - 2018-01-31

### Changed

* Changed the default version of the ODBC Driver to 17. This is to reflect what version is installed when running `apt-get install msodbcsql` on Debian Jessie. It may cause breaking changes for some users who rely on the default being 13.

## 0.8.0 - 2017-07-21

### Added

* Ability to set a named instance in the connection options, using `:instance_name`.

## 0.7.0 - 2017-07-05

### Added

* Ability to set a custom port, using option `:port`, will default to 1433.

## < 0.7.0

TODO
