class Rhcl::Dump
  class << self
    def dump(obj)
      unless obj.kind_of?(Hash)
        raise TypeError, "wrong argument type #{obj.class} (expected Hash)"
      end

      dump0(obj).sub(/\A\s*\{/, '').sub(/\}\s*\z/, '').strip.gsub(/^\s+$/m, '')
    end

    private
    def dump0(obj, depth = 0)
      prefix = '  ' * depth
      prefix0 = '  ' * (depth.zero? ? 0 : depth - 1)

      case obj
      when Array
        '[' +
        obj.map {|i| dump0(i, depth + 1) }.join(', ') +
        "]\n"
      when Hash
        "#{prefix}{\n#{prefix}" +
        obj.map {|k, v|
          k = k.to_s.strip
          k = k.inspect unless k =~ /\A\w+\z/
          k + (v.kind_of?(Hash) ? ' ' : " = ") + dump0(v, depth + 1).strip
        }.join("\n#{prefix}") +
        "\n#{prefix0}}\n"
      when Numeric, TrueClass, FalseClass
        obj.inspect
      else
        obj.to_s.inspect
      end
    end
  end
end
