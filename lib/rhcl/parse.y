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

def initialize(obj)
  src = obj.is_a?(IO) ? obj.read : obj.to_s
  @ss = StringScanner.new(src)
end

def scan
  tok = nil
  @prev_tokens = []

  until @ss.eos?
    if (tok = @ss.scan /\s+/)
      # nothing to do
    elsif (tok = @ss.scan(/#/))
      @prev_tokens << tok
      @prev_tokens << @ss.scan_until(/\n/)
      tok = ''
    elsif (tok = @ss.scan(%r|/|))
      @prev_tokens << tok

      case (tok = @ss.getch)
      when '/'
        @prev_tokens << tok
        @prev_tokens << @ss.scan_until(/(\n|\z)/)
      when '*'
        @prev_tokens << tok
        nested = 1

        until nested.zero?
          case (tok = @ss.scan_until(%r{(/\*|\*/|\z)}))
          when %r|/\*\z|
            @prev_tokens << tok
            nested += 1
          when %r|\*/\z|
            @prev_tokens << tok
            nested -= 1
          else
            @prev_tokens << tok
            break
          end
        end
      else
        raise "comment expected, got '#{tok}'"
      end

      tok = ''
    elsif (tok = @ss.scan(/-?\d+\.\d+/))
      yield [:FLOAT, tok.to_f]
    elsif (tok = @ss.scan(/-?\d+/))
      yield [:INTEGER, tok.to_i]
    elsif (tok = @ss.scan(/,/))
      yield [:COMMA, tok]
    elsif (tok = @ss.scan(/\=/))
      yield [:EQUAL, tok]
    elsif (tok = @ss.scan(/\[/))
      yield [:LEFTBRACKET, tok]
    elsif (tok = @ss.scan(/\]/))
      yield [:RIGHTBRACKET, tok]
    elsif (tok = @ss.scan(/\{/))
      yield [:LEFTBRACE, tok]
    elsif (tok = @ss.scan(/\}/))
      yield [:RIGHTBRACE, tok]
    elsif (tok = @ss.scan(/"/))
      yield [:STRING, (@ss.scan_until(/("|\z)/) || '').sub(/"\z/, '')]
    else
      tok = (@ss.scan_until(/(\s|\z)/) || '').sub(/\s\z/, '')
      token_type = :IDENTIFIER

      if ['true', 'false'].include?(tok)
        tok = !!(tok =~ /true/)
        token_type = :BOOL
      end

      yield [token_type, tok]
    end

    @prev_tokens << tok
  end

  yield [false, '$end']
end
private :scan

def parse
  yyparse self, :scan
end

def on_error(error_token_id, error_value, value_stack)
  raise_error(error_value)
end

def raise_error(error_value)
  header = "parse error on value: #{error_value}\n"
  prev = (@prev_tokens || [])
  prev = prev.empty? ? '' : prev.join + ' '
  errmsg = prev + "__#{error_value}__"

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
