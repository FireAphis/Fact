#!/usr/bin/ruby

# System libraries
require "rubygems"
require "test/unit"

# Allow requiring the files in this library even if it wasn't installed
# as a gem
libdir = File.expand_path("../lib", File.dirname(__FILE__))
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

# Local libraries
require "clearcase"
require "activities_cli"
require "files_cli"

class MockClearTool

  def initialize
    @invocations = []
    @succeeded = true
  end

  def succeeded
    @succeeded
  end

  def add_invocation(command, result)
    @invocations.push( { :command => command,
                         :result  => result   } )
  end

  def invoke(command)
    next_invocation = @invocations.shift
    err_msg = "Wrong invocation: expected '#{next_invocation[:command]}', actual '#{command}'"
    if command != next_invocation[:command]
      @succeeded = false
      throw(:wrongInvocation, err_msg)
    else
      return next_invocation[:result]
    end
  end

end

class ClearCaseWrapperTests < Test::Unit::TestCase

  def test_parse_cc_version
    cc = Fact::ClearCase.new
    result = cc.parse_cc_version("/home/FireAphis/views/fireaphis_fact_1.0/vobs/fact/test/test.cpp@@/main/fact_1.0_Integ/fireaphis_fact_1.0/12");
    assert_not_nil(result)
    assert_equal("/home/FireAphis/views/fireaphis_fact_1.0/vobs/fact/test/test.cpp", result[:file])
    assert_equal("/main/fact_1.0_Integ/fireaphis_fact_1.0/12", result[:version])
  end


  def test_parse_lsact_output
    cc = Fact::ClearCase.new

    result = cc.parse_lsact_output("name_1,headline 1,")
    expected = [ { :name => "name_1", :headline => "headline 1" } ]
    assert_equal(expected, result)

    result = cc.parse_lsact_output("name_1,headline 1,name_1,headline 1,name_1,headline 1,")
    expected = [ { :name => "name_1", :headline => "headline 1" },
                 { :name => "name_1", :headline => "headline 1" },
                 { :name => "name_1", :headline => "headline 1" } ]
    assert_equal(expected, result)

    result = cc.parse_lsact_output("name_1,headline 1,name_2,headline 2,name_3,headline 3,")
    expected = [ { :name => "name_1", :headline => "headline 1" },
                 { :name => "name_2", :headline => "headline 2" },
                 { :name => "name_3", :headline => "headline 3" } ]
    assert_equal(expected, result)
  end


  def test_parse_describe_file
    cc = Fact::ClearCase.new

    result = cc.parse_describe_file("version=/main/fact_1.0_Integ/fireaphis_fact_1.0/8, activity=test_fact, date=2011-05-08, type=version, predecessor=/main/fact_1.0_Integ/fireaphis_fact_1.0/7, user=FireAphis, checkout=fireaphis_fact_1.0")
    expected = { :version     => "/main/fact_1.0_Integ/fireaphis_fact_1.0/8", 
                 :activity    => "test_fact",
                 :date        => "2011-05-08",
                 :type        => "version",
                 :predecessor => "/main/fact_1.0_Integ/fireaphis_fact_1.0/7",
                 :user        => "FireAphis",
                 :checkout    => "fireaphis_fact_1.0"}
    assert_equal(expected, result)
  end


  def test_get_activity_change_set
    # Define the expected calls
    ct = MockClearTool.new
    ct.add_invocation('lsact -fmt "%[versions]p" test_fact', '/home/fa/c@@/main/stream/100 ' +
                                                             '/home/fa/a@@/main/stream/CHECKEDOUT.1234 ' +
                                                             '/home/fa/b@@/main/stream/100 ' +
                                                             '/home/fa/c@@/main/stream/102 ' +
                                                             '/home/fa/c@@/main/stream/101 ' +
                                                             '/home/fa/a@@/main/stream/200' )
    cc = Fact::ClearCase.new
    cc.cleartool = ct

    change_set = {}
    err = catch(:wrongInvocation) { change_set = cc.get_activity_change_set("test_fact") }
    assert(ct.succeeded, err)

    expected = {"/home/fa/a"=>["/main/stream/200", "/main/stream/CHECKEDOUT.1234"],
                "/home/fa/b"=>["/main/stream/100"],
                "/home/fa/c"=>["/main/stream/100", "/main/stream/101", "/main/stream/102"]}
    assert_equal(expected, change_set)
  end

end