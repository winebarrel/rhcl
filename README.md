# Rhcl

Pure Ruby [HCL](https://github.com/hashicorp/hcl) parser

[![Gem Version](https://badge.fury.io/rb/rhcl.png)](http://badge.fury.io/rb/rhcl)
[![Build Status](https://travis-ci.org/winebarrel/rhcl.svg?branch=master)](https://travis-ci.org/winebarrel/rhcl)

## Installation

Add this line to your application's Gemfile:

    gem 'rhcl'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rhcl

## Usage

### Parse

```ruby
Rhcl.parse(<<-EOS)
  variable "foo" {
      default = "bar"
      description = "bar"
  }

  variable "amis" {
      default = {
          east = "foo"
      }
  }
EOS
```

### Dump

```ruby
Rhcl.dump(
  {"variable"=>
  {"foo"=>{"default"=>"bar", "description"=>"bar"},
   "amis"=>{"default"=>{"east"=>"foo"}}}}
)
```

## Contributing

1. Fork it ( http://github.com/winebarrel/rhcl/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
