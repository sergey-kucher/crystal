require "spec"
require "process"

describe Process do
  it "runs true" do
    process = Process.run("true")
    process.wait.exit_code.should eq(0)
  end

  it "runs false" do
    process = Process.run("false")
    process.wait.exit_code.should eq(1)
  end

  it "returns status 127 if command could not be executed" do
    process = Process.run("foobarbaz")
    process.wait.exit_code.should eq(127)
  end

  it "runs true in block" do
    Process.run("true") { }
    $?.exit_code.should eq(0)
  end

  it "receives arguments in array" do
    Process.run("/bin/sh", ["-c", "exit 123"]).wait.exit_code.should eq(123)
  end

  it "receives arguments in tuple" do
    Process.run("/bin/sh", {"-c", "exit 123"}).wait.exit_code.should eq(123)
  end

  it "redirects output to /dev/null" do
    # This doesn't test anything but no output should be seen while running tests
    Process.run("/bin/ls", output: false).wait.exit_code.should eq(0)
  end

  it "gets output" do
    value = Process.run("/bin/sh", {"-c", "echo hello"}) do |proc|
      proc.output.read
    end
    value.should eq("hello\n")
  end

  it "sends input in IO" do
    value = Process.run("/bin/cat", input: StringIO.new("hello")) do |proc|
      proc.input?.should be_nil
      proc.output.read
    end
    value.should eq("hello")
  end

  it "sends output to IO" do
    output = StringIO.new
    Process.run("/bin/sh", {"-c", "echo hello"}, output: output).wait
    output.to_s.should eq("hello\n")
  end

  it "sends error to IO" do
    error = StringIO.new
    Process.run("/bin/sh", {"-c", "echo hello 1>&2"}, error: error).wait
    error.to_s.should eq("hello\n")
  end

  it "controls process in block" do
    value = Process.run("/bin/cat") do |proc|
      proc.input.print "hello"
      proc.input.close
      proc.output.read
    end
    value.should eq("hello")
  end

  it "closes ios after block" do
    Process.run("/bin/cat") {}
    $?.exit_code.should eq(0)
  end

  describe "kill" do
    it "kills a process" do
      pid = fork { loop {} }
      Process.kill(Signal::KILL, pid).should eq(0)
    end

    it "kills many process" do
      pid1 = fork { loop {} }
      pid2 = fork { loop {} }
      Process.kill(Signal::KILL, pid1, pid2).should eq(0)
    end
  end

  it "gets the pgid of a process id" do
    pid = fork { loop {} }
    Process.getpgid(pid).should be_a(Int32)
    Process.kill(Signal::KILL, pid)
  end
end
