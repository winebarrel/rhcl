describe Rhcl do
  it 'basic' do
    dumped = Rhcl.dump(
      {"foo" => "bar"}
    )

    expect(dumped).to eq 'foo = "bar"'
  end

  it 'decode_policy' do
    dumped = Rhcl.dump(
      {"key"=>
       {""=>{"policy"=>"read"},
        "foo/"=>{"policy"=>"write"},
        "foo/bar/"=>{"policy"=>"read"},
        "foo/bar/baz"=>{"policy"=>"deny"}}}
    )

    expect(dumped).to eq <<-EOS.strip
key {
  "" {
    policy = "read"
  }
  "foo/" {
    policy = "write"
  }
  "foo/bar/" {
    policy = "read"
  }
  "foo/bar/baz" {
    policy = "deny"
  }
}
    EOS
  end

  it 'decode_tf_variable' do
    dumped = Rhcl.dump(
      {"variable"=>
      {"foo"=>{"default"=>"bar", "description"=>"bar"},
       "amis"=>{"default"=>{"east"=>"foo"}}}}
    )

    expect(dumped).to eq <<-EOS.strip
variable {
  foo {
    default = "bar"
    description = "bar"
  }
  amis {
    default {
      east = "foo"
    }
  }
}
    EOS
  end

  it 'empty' do
    dumped = Rhcl.dump(
      {"resource"=>{"aws_instance"=>{"db"=>{}}}}
    )

    expect(dumped).to eq <<-EOS.strip
resource {
  aws_instance {
    db {

    }
  }
}
    EOS
  end

  it 'flat' do
    dumped = Rhcl.dump(
      {"foo"=>"bar", "Key"=>7}
    )

    expect(dumped).to eq <<-EOS.strip
foo = "bar"
Key = 7
    EOS
  end

  it 'structure' do
    dumped = Rhcl.dump(
      {"foo"=>{"baz"=>{"key"=>7, "foo"=>"bar"}}}
    )

    expect(dumped).to eq <<-EOS.strip
foo {
  baz {
    key = 7
    foo = "bar"
  }
}
    EOS
  end

  it 'structure2' do
    dumped = Rhcl.dump(
      {"foo"=>{"baz"=>{"key"=>7, "foo"=>"bar"}, "key"=>7}}
    )

    expect(dumped).to eq <<-EOS.strip
foo {
  baz {
    key = 7
    foo = "bar"
  }
  key = 7
}
    EOS
  end

  it 'structure_flat' do
    dumped = Rhcl.dump(
      {"foo"=>{"baz"=>{"key"=>7, "foo"=>"bar"}}}
    )

    expect(dumped).to eq <<-EOS.strip
foo {
  baz {
    key = 7
    foo = "bar"
  }
}
    EOS
  end

  it 'structure_flatmap' do
    dumped = Rhcl.dump(
      {"foo"=>{"key"=>7, "foo"=>"bar"}}
    )

    expect(dumped).to eq <<-EOS.strip
foo {
  key = 7
  foo = "bar"
}
    EOS
  end

  it 'structure_multi' do
    dumped = Rhcl.dump(
      {"foo"=>{"baz"=>{"key"=>7}, "bar"=>{"key"=>12}}}
    )

    expect(dumped).to eq <<-EOS.strip
foo {
  baz {
    key = 7
  }
  bar {
    key = 12
  }
}
    EOS
  end

  it 'array' do
    dumped = Rhcl.dump(
      {"foo"=>[1, 2, "baz"], "bar"=>"baz"}
    )

    expect(dumped).to eq <<-EOS.strip
foo = [1, 2, "baz"]
bar = "baz"
    EOS
  end

  it 'object' do
    dumped = Rhcl.dump(
      {"foo"=>{"bar"=>[1, 2, "baz"]}}
    )

    expect(dumped).to eq <<-EOS.strip
foo {
  bar = [1, 2, "baz"]
}
    EOS
  end

  it 'types' do
    dumped = Rhcl.dump(
      {"foo"=>"bar",
       "bar"=>7,
       "baz"=>[1, 2, 3],
       "foo2"=>-12,
       "bar2"=>3.14159,
       "bar3"=>-3.14159,
        "hoge"=>true,
        "fuga"=>false}
    )

    expect(dumped).to eq <<-EOS.strip
foo = "bar"
bar = 7
baz = [1, 2, 3]
foo2 = -12
bar2 = 3.14159
bar3 = -3.14159
hoge = true
fuga = false
    EOS
  end

  it 'complex' do
    dumped = Rhcl.dump(
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

    expect(dumped).to eq <<-EOS.strip
variable {
  foo {
    default = "bar"
    description = "bar"
  }
}
provider {
  aws {
    access_key = "foo"
    secret_key = "bar"
  }
  do {
    api_key = "${var.foo}"
  }
}
resource {
  aws_security_group {
    firewall {
      count = 5
    }
  }
  aws_instance {
    web {
      ami = "${var.foo}"
      security_groups = ["foo", "${aws_security_group.firewall.foo}"]
      network_interface {
        device_index = 0
        description = "Main network interface"
      }
    }
    db {
      security_groups = "${aws_security_group.firewall.*.id}"
      VPC = "foo"
      depends_on = ["aws_instance.web"]
    }
  }
}
output {
  web_ip {
    value = "${aws_instance.web.private_ip}"
  }
}
    EOS
  end
end
