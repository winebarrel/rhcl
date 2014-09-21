describe Rhcl do
  it 'basic' do
    parsed = Rhcl.parse(<<-EOS)
      foo = "bar"
    EOS

    expect(parsed).to eq(
      {"foo" => "bar"}
    )
  end

  it 'decode_policy' do
    parsed = Rhcl.parse(<<-EOS)
      key "" {
        policy = "read"
      }

      key "foo/" {
        policy = "write"
      }

      key "foo/bar/" {
        policy = "read"
      }

      key "foo/bar/baz" {
        policy = "deny"
      }
    EOS

    expect(parsed).to eq(
      {"key"=>
       {""=>{"policy"=>"read"},
        "foo/"=>{"policy"=>"write"},
        "foo/bar/"=>{"policy"=>"read"},
        "foo/bar/baz"=>{"policy"=>"deny"}}}
    )
  end

  it 'decode_tf_variable' do
    parsed = Rhcl.parse(<<-EOS)
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

    expect(parsed).to eq(
      {"variable"=>
      {"foo"=>{"default"=>"bar", "description"=>"bar"},
       "amis"=>{"default"=>{"east"=>"foo"}}}}
    )
  end

  it 'empty' do
    parsed = Rhcl.parse(<<-EOS)
      resource "aws_instance" "db" {}
    EOS

    expect(parsed).to eq(
      {"resource"=>{"aws_instance"=>{"db"=>{}}}}
    )
  end

  it 'flat' do
    parsed = Rhcl.parse(<<-EOS)
      foo = "bar"
      Key = 7
    EOS

    expect(parsed).to eq(
      {"foo"=>"bar", "Key"=>7}
    )
  end

  it 'structure' do
    parsed = Rhcl.parse(<<-EOS)
      // This is a test structure for the lexer
      foo "baz" {
        key = 7
        foo = "bar"
      }
    EOS

    expect(parsed).to eq(
      {"foo"=>{"baz"=>{"key"=>7, "foo"=>"bar"}}}
    )
  end

  it 'structure2' do
    parsed = Rhcl.parse(<<-EOS)
      // This is a test structure for the lexer
      foo "baz" {
        key = 7
        foo = "bar"
      }

      foo {
        key = 7
      }
    EOS

    expect(parsed).to eq(
      {"foo"=>{"baz"=>{"key"=>7, "foo"=>"bar"}, "key"=>7}}
    )
  end

  it 'structure_flat' do
    parsed = Rhcl.parse(<<-EOS)
      # This is a test structure for the lexer
      foo "baz" {
        key = 7
        foo = "bar"
      }
    EOS

    expect(parsed).to eq(
      {"foo"=>{"baz"=>{"key"=>7, "foo"=>"bar"}}}
    )
  end

  it 'structure_flatmap' do
    parsed = Rhcl.parse(<<-EOS)
      /*
        comment
      */
      foo {
        key = 7
      }

      foo {
        foo = "bar"
      }
    EOS

    expect(parsed).to eq(
      {"foo"=>{"key"=>7, "foo"=>"bar"}}
    )
  end

  it 'structure_multi' do
    parsed = Rhcl.parse(<<-EOS)
      foo "baz" {
        key = 7
      }

      foo "bar" {
        key = 12
      }
    EOS

    expect(parsed).to eq(
      {"foo"=>{"baz"=>{"key"=>7}, "bar"=>{"key"=>12}}}
    )
  end

  it 'array' do
    parsed = Rhcl.parse(<<-EOS)
      foo = [1, 2, "baz"]
      bar = "baz"
    EOS

    expect(parsed).to eq(
      {"foo"=>[1, 2, "baz"], "bar"=>"baz"}
    )
  end

  it 'object' do
    parsed = Rhcl.parse(<<-EOS)
      foo = {
        bar = [1, 2, "baz"]
      }
    EOS

    expect(parsed).to eq(
      {"foo"=>{"bar"=>[1, 2, "baz"]}}
    )
  end

  it 'types' do
    parsed = Rhcl.parse(<<-EOS)
      foo = "bar"
      bar = 7
      baz = [1,2,3]
      foo2 = -12
      bar2 = 3.14159
      bar3 = -3.14159
      hoge = true
      fuga = false
    EOS

    expect(parsed).to eq(
      {"foo"=>"bar",
       "bar"=>7,
       "baz"=>[1, 2, 3],
       "foo2"=>-12,
       "bar2"=>3.14159,
       "bar3"=>-3.14159,
        "hoge"=>true,
        "fuga"=>false}
    )
  end

  it 'assign_colon' do
    expect {
      Rhcl.parse(<<-EOS)
        resource = [{
          "foo": {
            "bar": {},
            "baz": [1, 2, "foo"],
          }
        }]
      EOS
    }.to raise_error
  end

  it 'assign_deep' do
    expect {
      Rhcl.parse(<<-EOS)
        resource = [{
          foo = [{
            bar = {}
          }]
        }]
      EOS
    }.to raise_error
  end

  it 'comment' do
    parsed = Rhcl.parse(<<-EOS)
      // Foo

      /* Bar */

      /*
      /*
      Baz
      */
      */

      # Another

      # Multiple
      # Lines

      foo = "bar"
    EOS

    expect(parsed).to eq(
      {"foo"=>"bar"}
    )
  end

  it 'complex' do
    parsed = Rhcl.parse(<<-EOS)
// This comes from Terraform, as a test
variable "foo" {
    default = "bar"
    description = "bar"
}

provider "aws" {
  access_key = "foo"
  secret_key = "bar"
}

provider "do" {
  api_key = "${var.foo}"
}

resource "aws_security_group" "firewall" {
    count = 5
}

resource aws_instance "web" {
    ami = "${var.foo}"
    security_groups = [
        "foo",
        "${aws_security_group.firewall.foo}"
    ]

    network_interface {
        device_index = 0
        description = "Main network interface"
    }
}

resource "aws_instance" "db" {
    security_groups = "${aws_security_group.firewall.*.id}"
    VPC = "foo"

    depends_on = ["aws_instance.web"]
}

output "web_ip" {
    value = "${aws_instance.web.private_ip}"
}
    EOS

    expect(parsed).to eq(
{"variable"=>{"foo"=>{"default"=>"bar", "description"=>"bar"}},
 "provider"=>
  {"aws"=>{"access_key"=>"foo", "secret_key"=>"bar"},
   "do"=>{"api_key"=>"${var.foo}"}},
 "resource"=>
  {"aws_security_group"=>{"firewall"=>{"count"=>5}},
   "aws_instance"=>
    {"web"=>
      {"ami"=>"${var.foo}",
       "security_groups"=>["foo", "${aws_security_group.firewall.foo}"],
       "network_interface"=>
        {"device_index"=>0, "description"=>"Main network interface"}},
     "db"=>
      {"security_groups"=>"${aws_security_group.firewall.*.id}",
       "VPC"=>"foo",
       "depends_on"=>["aws_instance.web"]}}},
 "output"=>{"web_ip"=>{"value"=>"${aws_instance.web.private_ip}"}}}
    )
  end

  it 'bool types' do
    parsed = Rhcl.parse(<<-EOS)
      foo  = true
      bar  = false
      zoo  = on
      foo2 = off
      bar2 = yes
      zoo2 = no
    EOS

    expect(parsed).to eq(
      {"foo"=>true,
       "bar"=>false,
       "zoo"=>true,
       "foo2"=>false,
       "bar2"=>true,
       "zoo2"=>false}
    )
  end
end
