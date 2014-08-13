module Rhcl
  def parse(obj)
    Rhcl::Parse.parse(obj)
  end
  module_function :parse
end

require 'deep_merge'
require 'rhcl/version'
require 'rhcl/parse.tab'
