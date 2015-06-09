# encoding: utf-8

require "logstash/devutils/rspec/spec_helper"
require "tempfile"
require "stud/temporary"

describe "inputs/leanenginelog" do

  delimiter = (LogStash::Environment.windows? ? "\r\n" : "\n")

  tmpconfigfile_path = Stud::Temporary.pathname
  # write config file
  File.open(tmpconfigfile_path, "w") do |fd|
    config = <<-CONFIG
{"State":{"Running":false,"Paused":false,"Restarting":false,"OOMKilled":false,"Pid":0,"ExitCode":-1,"Error":"","StartedAt":"2015-06-07T01:10:16.326550926Z","FinishedAt":"2015-06-07T02:41:03.972710647Z"},"ID":"797ecae5f13dc6c2fd1ccf9740e55080f7a465d7a0d58be756183314fcaa8220","Created":"2015-06-07T01:10:15.578846026Z","Path":"daemon","Args":["-f","-r","--","node","/mnt/avos/cloud-code/main.js","server.js","--container","8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk_1_a_0_docker9"],"Config":{"Hostname":"797ecae5f13d","Domainname":"","User":"leanengine","Memory":0,"MemorySwap":0,"CpuShares":0,"Cpuset":"","AttachStdin":false,"AttachStdout":false,"AttachStderr":false,"PortSpecs":null,"ExposedPorts":{"3000/tcp":{}},"Tty":false,"OpenStdin":false,"StdinOnce":false,"Env":["LC_APP_ID=8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk","LC_APP_KEY=nfkx5k3p7otysvhr2fp84mxl8ggmehu7swyi18auvmrg7kd4","LC_APP_MASTER_KEY=zhvl25xtgdxvfgijceos1s0eonpxt24gzh3dzq6ec30n0pn4","LC_APP_REPO_PATH=/mnt/avos/data/uluru-cloud-code/repos/8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk","LC_APP_PROD=1","LC_APP_PORT=3000","LC_APP_ENV=production","LC_API_SERVER=http://10.10.53.248","NODE_ENV=production","PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"],"Cmd":["daemon","-f","-r","--","node","/mnt/avos/cloud-code/main.js","server.js","--container","8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk_1_a_0_docker9"],"Image":"avos/cloud-code","Volumes":null,"WorkingDir":"/mnt/avos/data/uluru-cloud-code/repos/8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk","Entrypoint":null,"NetworkDisabled":false,"MacAddress":"","OnBuild":null},"Image":"5095c5737a8812e78b8c0a5f386e6a5c563d7077b4c721c0cf3f45ca77fe5f26","NetworkSettings":{"IPAddress":"","IPPrefixLen":0,"MacAddress":"","Gateway":"","Bridge":"","PortMapping":null,"Ports":null},"ResolvConfPath":"/var/lib/docker/containers/797ecae5f13dc6c2fd1ccf9740e55080f7a465d7a0d58be756183314fcaa8220/resolv.conf","HostnamePath":"/var/lib/docker/containers/797ecae5f13dc6c2fd1ccf9740e55080f7a465d7a0d58be756183314fcaa8220/hostname","HostsPath":"/var/lib/docker/containers/797ecae5f13dc6c2fd1ccf9740e55080f7a465d7a0d58be756183314fcaa8220/hosts","Name":"/8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk_1_a_0_docker9","Driver":"aufs","ExecDriver":"native-0.2","MountLabel":"","ProcessLabel":"","AppArmorProfile":"","RestartCount":0,"Volumes":{"/mnt/avos/cloud-code":"/mnt/avos/cloud-code","/mnt/avos/data/uluru-cloud-code/repos/8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk":"/mnt/avos/local-data/uluru-cloud-code/repos/8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk/repos/1432828602490"},"VolumesRW":{"/mnt/avos/cloud-code":false,"/mnt/avos/data/uluru-cloud-code/repos/8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk":false}}
    CONFIG
    fd.puts(config)
  end

  it "should starts at the end of an existing file" do
    tmpfile_path = Stud::Temporary.pathname
    sincedb_path = Stud::Temporary.pathname

    conf = <<-CONFIG
      input {
        leanenginelog {
          type => "blah"
          path => "#{tmpfile_path}"
          config_file => "#{File.basename(tmpconfigfile_path)}"
          sincedb_path => "#{sincedb_path}"
          delimiter => "#{delimiter}"
        }
      }
    CONFIG

    File.open(tmpfile_path, "w") do |fd|
      fd.puts("ignore me 1")
      fd.puts("ignore me 2")
    end

    events = input(conf) do |pipeline, queue|

      # at this point the plugins
      # threads might still be initializing so we cannot know when the
      # file plugin will have seen the original file, it could see it
      # after the first(s) hello world appends below, hence the
      # retry logic.

      events = []

      retries = 0
      while retries < 20
        File.open(tmpfile_path, "a") do |fd|
          fd.puts("hello")
          fd.puts("world")
        end

        if queue.size >= 2
          events = 2.times.collect { queue.pop }
          break
        end

        sleep(0.1)
        retries += 1
      end

      events
    end

    insist { events[0]["message"] } == "hello"
    insist { events[1]["message"] } == "world"
    insist { events[0]["app_id"] } == "8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk"
    insist { events[0]["app_key"] } == "nfkx5k3p7otysvhr2fp84mxl8ggmehu7swyi18auvmrg7kd4"
  end

  it "should start at the beginning of an existing file" do
    tmpfile_path = Stud::Temporary.pathname
    sincedb_path = Stud::Temporary.pathname

    conf = <<-CONFIG
      input {
        leanenginelog {
          type => "blah"
          path => "#{tmpfile_path}"
          config_file => "#{File.basename(tmpconfigfile_path)}"
          start_position => "beginning"
          sincedb_path => "#{sincedb_path}"
          delimiter => "#{delimiter}"
        }
      }
    CONFIG

    File.open(tmpfile_path, "a") do |fd|
      fd.puts("hello")
      fd.puts("world")
    end

    events = input(conf) do |pipeline, queue|
      2.times.collect { queue.pop }
    end

    insist { events[0]["message"] } == "hello"
    insist { events[1]["message"] } == "world"
  end

  it "should restarts at the sincedb value" do
    tmpfile_path = Stud::Temporary.pathname
    sincedb_path = Stud::Temporary.pathname

    conf = <<-CONFIG
      input {
        leanenginelog {
          type => "blah"
          path => "#{tmpfile_path}"
          config_file => "#{File.basename(tmpconfigfile_path)}"
          start_position => "beginning"
          sincedb_path => "#{sincedb_path}"
          delimiter => "#{delimiter}"
        }
      }
    CONFIG

    File.open(tmpfile_path, "w") do |fd|
      fd.puts("hello3")
      fd.puts("world3")
    end

    events = input(conf) do |pipeline, queue|
      2.times.collect { queue.pop }
    end

    insist { events[0]["message"] } == "hello3"
    insist { events[1]["message"] } == "world3"

    File.open(tmpfile_path, "a") do |fd|
      fd.puts("foo")
      fd.puts("bar")
      fd.puts("baz")
    end

    events = input(conf) do |pipeline, queue|
      3.times.collect { queue.pop }
    end

    insist { events[0]["message"] } == "foo"
    insist { events[1]["message"] } == "bar"
    insist { events[2]["message"] } == "baz"
  end

  it "should not overwrite existing path and host fields" do
    tmpfile_path = Stud::Temporary.pathname
    sincedb_path = Stud::Temporary.pathname

    conf = <<-CONFIG
      input {
        leanenginelog {
          type => "blah"
          path => "#{tmpfile_path}"
          config_file => "#{File.basename(tmpconfigfile_path)}"
          start_position => "beginning"
          sincedb_path => "#{sincedb_path}"
          delimiter => "#{delimiter}"
          codec => "json"
        }
      }
    CONFIG

    File.open(tmpfile_path, "w") do |fd|
      fd.puts('{"path": "my_path", "host": "my_host"}')
      fd.puts('{"my_field": "my_val"}')
    end

    events = input(conf) do |pipeline, queue|
      2.times.collect { queue.pop }
    end

    insist { events[0]["path"] } == "my_path"
    insist { events[0]["host"] } == "my_host"

    insist { events[1]["path"] } == "#{tmpfile_path}"
    insist { events[1]["host"] } == "#{Socket.gethostname.force_encoding(Encoding::UTF_8)}"
  end
end
