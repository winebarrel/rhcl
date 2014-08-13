module Rhcl
  def parse(obj)
    Rhcl::Parse.parse(obj)
  end
  module_function :parse

  def dump(obj)
    Rhcl::Dump.dump(obj)
  end
  module_function :dump
end

require 'deep_merge'
require 'rhcl/dump'
require 'rhcl/parse.tab'
require 'rhcl/version'
