# encoding: utf-8

require "logstash/devutils/rspec/spec_helper"
require "tempfile"
require "stud/temporary"
require "logstash/inputs/leanenginelog"

describe "inputs/leanenginelog" do
  before(:all) do
    @abort_on_exception = Thread.abort_on_exception
    Thread.abort_on_exception = true
  end

  after(:all) do
    Thread.abort_on_exception = @abort_on_exception
  end

  delimiter = (LogStash::Environment.windows? ? "\r\n" : "\n")

  tmpconfigfile_path = Stud::Temporary.pathname
  # write config file
  File.open(tmpconfigfile_path, "w") do |fd|
    config = <<-CONFIG
{"State":{"Running":false,"Paused":false,"Restarting":false,"OOMKilled":false,"Dead":false,"Pid":0,"ExitCode":137,"Error":"","StartedAt":"2015-08-21T10:41:45.897463019Z","FinishedAt":"2015-08-21T12:32:14.601290923Z"},"ID":"1dfdc8a44215a19bde3fb029ecbefb9401adf0b38c74c6417330d39d9c4de247","Created":"2015-08-21T10:41:45.364091462Z","Path":"daemon","Args":["-f","-r","--","node","/mnt/avos/cloud-code/server.js"],"Config":{"Hostname":"1dfdc8a44215","Domainname":"","User":"leanengine","AttachStdin":false,"AttachStdout":false,"AttachStderr":false,"PortSpecs":null,"ExposedPorts":{"3000/tcp":{}},"Tty":false,"OpenStdin":false,"StdinOnce":false,"Env":["LC_APP_ID=8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk","LC_APP_KEY=nfkx5k3p7otysvhr2fp84mxl8ggmehu7swyi18auvmrg7kd4","LC_APP_MASTER_KEY=zhvl25xtgdxvfgijceos1s0eonpxt24gzh3dzq6ec30n0pn4","LC_APP_REPO_PATH=/mnt/avos/data/uluru-cloud-code/repos/8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk","LC_APP_PROD=0","LC_APP_PORT=3000","LC_APP_INSTANCE=3","LC_APP_ENV=stage","LC_API_SERVER=http://api.leancloud.cn","NODE_ENV=stage","PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"],"Cmd":["daemon","-f","-r","--","node","/mnt/avos/cloud-code/server.js"],"Image":"avos/cloud-code","Volumes":null,"VolumeDriver":"","WorkingDir":"/mnt/avos/data/uluru-cloud-code/repos/8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk","Entrypoint":null,"NetworkDisabled":false,"MacAddress":"","OnBuild":null,"Labels":{}},"Image":"5095c5737a8812e78b8c0a5f386e6a5c563d7077b4c721c0cf3f45ca77fe5f26","NetworkSettings":{"Bridge":"","EndpointID":"","Gateway":"","GlobalIPv6Address":"","GlobalIPv6PrefixLen":0,"HairpinMode":false,"IPAddress":"","IPPrefixLen":0,"IPv6Gateway":"","LinkLocalIPv6Address":"","LinkLocalIPv6PrefixLen":0,"MacAddress":"","NetworkID":"","PortMapping":null,"Ports":null,"SandboxKey":"","SecondaryIPAddresses":null,"SecondaryIPv6Addresses":null},"ResolvConfPath":"/var/lib/docker/containers/1dfdc8a44215a19bde3fb029ecbefb9401adf0b38c74c6417330d39d9c4de247/resolv.conf","HostnamePath":"/var/lib/docker/containers/1dfdc8a44215a19bde3fb029ecbefb9401adf0b38c74c6417330d39d9c4de247/hostname","HostsPath":"/var/lib/docker/containers/1dfdc8a44215a19bde3fb029ecbefb9401adf0b38c74c6417330d39d9c4de247/hosts","LogPath":"/var/lib/docker/containers/1dfdc8a44215a19bde3fb029ecbefb9401adf0b38c74c6417330d39d9c4de247/1dfdc8a44215a19bde3fb029ecbefb9401adf0b38c74c6417330d39d9c4de247-json.log","Name":"/8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk_0_b_3_docker11","Driver":"aufs","ExecDriver":"native-0.2","MountLabel":"","ProcessLabel":"","RestartCount":0,"UpdateDns":false,"MountPoints":{"/mnt/avos/cloud-code":{"Name":"","Destination":"/mnt/avos/cloud-code","Driver":"","RW":false,"Source":"/mnt/avos/cloud-code","Relabel":"ro"},"/mnt/avos/data/uluru-cloud-code/repos/8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk":{"Name":"","Destination":"/mnt/avos/data/uluru-cloud-code/repos/8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk","Driver":"","RW":false,"Source":"/mnt/avos/local-data/uluru-cloud-code/repos/8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk/repos/1440153704544","Relabel":"ro"}},"Volumes":{"/mnt/avos/cloud-code":"/mnt/avos/cloud-code","/mnt/avos/data/uluru-cloud-code/repos/8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk":"/mnt/avos/local-data/uluru-cloud-code/repos/8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk/repos/1440153704544"},"VolumesRW":{"/mnt/avos/cloud-code":false,"/mnt/avos/data/uluru-cloud-code/repos/8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk":false},"AppArmorProfile":""}
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
    insist { events[0]["prod"] } == "stage"
    insist { events[0]["instance"] } == "3"
    insist { events[0]["container_name"] } == "/8y5ria0dtbvz7qp6alzy00p9nggky304fafdusfo79fba5sk_0_b_3_docker11"
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

  it "mutil-line log" do
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
      fd.puts('foo\nbar')
      fd.puts('foo\nbar')
    end

    events = input(conf) do |pipeline, queue|
      2.times.collect { queue.pop }
    end

    insist { events[0]["message"] } == "foo\\nbar"
    insist { events[1]["message"] } == "foo\\nbar"
  end

  context "when sincedb_path is an existing directory" do
    let(:tmpfile_path) { Stud::Temporary.pathname }
    let(:sincedb_path) { Stud::Temporary.directory }
    subject { LogStash::Inputs::LeanEngineLog.new("path" => tmpfile_path, "sincedb_path" => sincedb_path) }

    after :each do
      FileUtils.rm_rf(sincedb_path)
    end

    it "should raise exception" do
      expect { subject.register }.to raise_error(ArgumentError)
    end
  end

  context "when #run is called multiple times", :unix => true do
    let(:tmpdir_path)  { Stud::Temporary.directory }
    let(:sincedb_path) { Stud::Temporary.pathname }
    let(:file_path)    { "#{tmpdir_path}/a.log" }
    let(:buffer)       { [] }
    let(:lsof)         { [] }
    let(:stop_proc) do
      lambda do |input, arr|
        Thread.new(input, arr) do |i, a|
          sleep 0.5
          a << `lsof -p #{Process.pid} | grep "a.log"`
          i.teardown
        end
      end
    end

    subject { LogStash::Inputs::LeanEngineLog.new("path" => tmpdir_path + "/*.log", "start_position" => "beginning", "sincedb_path" => sincedb_path) }

    after :each do
      FileUtils.rm_rf(tmpdir_path)
      FileUtils.rm_rf(sincedb_path)
    end
    before do
      File.open(file_path, "w") do |fd|
        fd.puts('foo')
        fd.puts('bar')
      end
    end
    it "should only have one set of files open" do
      subject.register
      lsof_before = `lsof -p #{Process.pid} | grep #{file_path}`
      expect(lsof_before).to eq("")
      stop_proc.call(subject, lsof)
      subject.run(buffer)
      expect(lsof.first).not_to eq("")
      stop_proc.call(subject, lsof)
      subject.run(buffer)
      expect(lsof.last).to eq(lsof.first)
    end
  end
end
