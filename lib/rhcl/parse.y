class Rhcl::Parse
options no_result_var
rule
  objectlist : objectitem
               {
                 val[0]
               }
             | objectlist objectitem
               {
                 val[0].deep_merge(val[1])
               }

  object: LEFTBRACE objectlist RIGHTBRACE
          {
            val[1]
          }
        | LEFTBRACE RIGHTBRACE
          {
            {}
          }

  objectitem: IDENTIFIER EQUAL number
              {
                {val[0] => val[2]}
              }
            | IDENTIFIER EQUAL BOOL
              {
                {val[0] => val[2]}
              }
            | IDENTIFIER EQUAL STRING
              {
                {val[0] => val[2]}
              }
            | IDENTIFIER EQUAL object
              {
                {val[0] => val[2]}
              }
            | IDENTIFIER EQUAL list
              {
                {val[0] => val[2]}
              }
            | block
              {
                val[0]
              }

  block: blockId object
         {
           {val[0] => val[1]}
         }
       | blockId block
         {
           {val[0] => val[1]}
         }


  blockId: IDENTIFIER
           {
             val[0]
           }
         | STRING
           {
             val[0]
           }

  list: LEFTBRACKET listitems RIGHTBRACKET
        {
          val[1]
        }
      | LEFTBRACKET RIGHTBRACKET
        {
          []
        }

  listitems: listitem
             {
               [val[0]]
             }
           | listitems COMMA listitem
             {
               val[0] + [val[2]]
             }

  listitem: number
            {
              val[0]
            }
          | STRING
            {
              val[0]
            }

  number: INTEGER
          {
            val[0]
          }
        | FLOAT
          {
            val[0]
          }

---- header

require 'strscan'

---- inner

TRUE_VALUES  = %w(true  on  yes)
FALSE_VALUES = %w(false off no )
BOOLEAN_VALUES = TRUE_VALUES + FALSE_VALUES

def initialize(obj)
  src = obj.is_a?(IO) ? obj.read : obj.to_s
  @ss = StringScanner.new(src)
end

def scan
  tok = nil
  @backup = []

  until @ss.eos?
    if (tok = backup { @ss.scan /\s+/ })
      # nothing to do
    elsif (tok = backup { @ss.scan /#/ })
      backup { @ss.scan_until /\n/ }
    elsif (tok = backup { @ss.scan %r|/| })
      case (tok = backup { @ss.getch })
      when '/'
        backup { @ss.scan_until /(\n|\z)/ }
      when '*'
        nested = 1

        until nested.zero?
          case (tok = backup { @ss.scan_until %r{(/\*|\*/|\z)} })
          when %r|/\*\z|
            nested += 1
          when %r|\*/\z|
            nested -= 1
          else
            break
          end
        end
      else
        raise "comment expected, got #{tok.inspect}"
      end
    elsif (tok = backup { @ss.scan /-?\d+\.\d+/ })
      yield [:FLOAT, tok.to_f]
    elsif (tok = backup { @ss.scan /-?\d+/ })
      yield [:INTEGER, tok.to_i]
    elsif (tok = backup { @ss.scan /,/ })
      yield [:COMMA, tok]
    elsif (tok = backup { @ss.scan /\=/ })
      yield [:EQUAL, tok]
    elsif (tok = backup { @ss.scan /\[/ })
      yield [:LEFTBRACKET, tok]
    elsif (tok = backup { @ss.scan /\]/ })
      yield [:RIGHTBRACKET, tok]
    elsif (tok = backup { @ss.scan /\{/ })
      yield [:LEFTBRACE, tok]
    elsif (tok = backup { @ss.scan /\}/ })
      yield [:RIGHTBRACE, tok]
    elsif (tok = backup { @ss.scan /"/ })
      yield [:STRING, (backup { @ss.scan_until /("|\z)/ } || '').sub(/"\z/, '')]
    else
      identifier = (backup { @ss.scan_until /(\s|\z)/ } || '').sub(/\s\z/, '')
      token_type = :IDENTIFIER

      if BOOLEAN_VALUES.include?(identifier)
        identifier = TRUE_VALUES.include?(identifier)
        token_type = :BOOL
      end

      yield [token_type, identifier]
    end
  end

  yield [false, '$end']
end
private :scan

def backup
  tok = yield
  @backup << tok if tok
  return tok
end

def parse
  yyparse self, :scan
end

def on_error(error_token_id, error_value, value_stack)
  raise_error(error_value)
end

def raise_error(error_value)
  header = "parse error on value: #{error_value}\n"
  error_value = @backup.pop

  if error_value =~ /\n\z/
    error_value = '__' + error_value.chomp + "__\n"
  else
    error_value = '__' + error_value + '__'
  end

  prev = (@backup || [])
  prev = prev.empty? ? '' : prev.join + ' '
  errmsg = prev + error_value

  if @ss and @ss.rest?
    errmsg << ' ' + @ss.rest
  end

  lines = errmsg.lines
  err_num = prev.count("\n")
  from_num = err_num - 3
  from_num = 0 if from_num < 0
  to_num = err_num + 3
  digit_num = lines.count.to_s.length

  errmsg = lines.each_with_index.map {|line, i|
    mark = (i == err_num) ? '*' : ' '
    '%s %*d: %s' % [mark, digit_num, i + 1, line]
  }.slice(from_num..to_num).join

  raise Racc::ParseError, header + errmsg
end
private :raise_error

def self.parse(obj)
  self.new(obj).parse
end
