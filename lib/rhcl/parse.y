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

  until @ss.eos?
    if (tok = @ss.scan /\s+/)
      # nothing to do
    elsif (tok = @ss.scan(/#/))
      @ss.scan_until(/\n/)
    elsif (tok = @ss.scan(%r|/|))
      case @ss.getch
      when '/'
        @ss.scan_until(/(\n|\z)/)
      when '*'
        nested = 1

        until nested.zero?
          case @ss.scan_until(%r{(/\*|\*/|\z)})
          when %r|/\*\z|
            nested += 1
          when %r|\*/\z|
            nested -= 1
          else
            break
          end
        end
      else
        raise "comment expected, got '#{tok}'"
      end
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
      identifier = (@ss.scan_until(/(\s|\z)/) || '').sub(/\s\z/, '')
      token_type = :IDENTIFIER

      if ['true', 'false'].include?(identifier)
        identifier = !!(identifier =~ /true/)
        token_type = :BOOL
      end

      yield [token_type, identifier]
    end
  end

  yield [false, '$end']
end
private :scan

def parse
  yyparse self, :scan
end

def self.parse(obj)
  self.new(obj).parse
end
