module Rhcl
  def parse(obj)
    Rhcl::Parse.parse(obj)
  end
  module_function :parse
end

require 'rhcl/version'
require 'rhcl/parse.tab'
