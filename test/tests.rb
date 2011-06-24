#!/usr/bin/ruby

require "rubygems"
require "test/unit"
require "fact"

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

  def test_get_hijacked_files
    # Define the expected calls
    ct = MockClearTool.new
    ct.add_invocation('ls -r', 
      [ "Connect",
        "a1.cpp.obsolete@@/main/fact_1.0_Integ/4        Rule: fact_1.0_1.0.0.0-663_31-MAY-2011_02.22.291 -mkbranch fireaphis_1.0_2",
        "a2.h.obsolete@@/main/fact_1.0_Integ/5          Rule: fact_1.0_1.0.0.0-663_31-MAY-2011_02.22.291 -mkbranch fireaphis_1.0_2",
        "a3.cpp.obsolete@@/main/fact_1.0_Integ/fireaphis_1.0_2/1             Rule: .../fireaphis_1.0_2/LATEST",
        "a4.h.obsolete@@/main/fact_1.0_Integ/fireaphis_1.0_2/2               Rule: .../fireaphis_1.0_2/LATEST",
        "a5.h.obsolete@@/main/fact_1.0_Integ/2        Rule: fact_1.0_1.0.0.0-663_31-MAY-2011_02.22.291 -mkbranch fireaphis_1.0_2",
        "a6.cpp.obsolete@@/main/fact_1.0_Integ/fireaphis_1.0_2/4                Rule: .../fireaphis_1.0_2/LATEST",
        "a7.h.obsolete@@/main/fact_1.0_Integ/fireaphis_1.0_2/3  Rule: .../fireaphis_1.0_2/LATEST",
        "a8.h.obsolete@@/main/fact_1.0_Integ/3         Rule: fact_1.0_1.0.0.0-663_31-MAY-2011_02.22.291 -mkbranch fireaphis_1.0_2",
        "a9.cpp.keep",
        "a10.cpp.keep.1",
        "a11.cpp.keep.2",
        "a12.h@@/main/fireaphis_1.0_2/4   Rule: .../fireaphis_1.0_2/LATEST",
        "a13.h@@/main/fact_1.0_Integ/2  Rule: fact_1.0_1.0.0.0-663_31-MAY-2011_02.22.291 -mkbranch fireaphis_1.0_2",
        "a14.h@@/main/fact_1.0_Integ/1            Rule: fact_1.0_1.0.0.0-663_31-MAY-2011_02.22.291 -mkbranch fireaphis_1.0_2",
        "a15.cpp@@/main/fact_1.0_Integ/4  Rule: fact_1.0_1.0.0.0-663_31-MAY-2011_02.22.291 -mkbranch fireaphis_1.0_2",
        "a16.h@@/main/fact_1.0_Integ/fireaphis_1.0_2/2 [hijacked]             Rule: .../fireaphis_1.0_2/LATEST",
        "a17.h@@/main/fact_1.0_Integ/1               Rule: fact_1.0_1.0.0.0-663_31-MAY-2011_02.22.291 -mkbranch fireaphis_1.0_2",
        "test@@/main/fact_1.0_Integ/fireaphis_1.0_2/3    Rule: .../fireaphis_1.0_2/LATEST",
        "./test/a18.h.obsolete@@/main/fact_1.0_Integ/3 [hijacked] Rule: fact_1.0_1.0.0.0-663_31-MAY-2011_02.22.291 -mkbranch fireaphis_1.0_2",
        "./test/a19.cpp.obsolete@@/main/fact_1.0_Integ/9  Rule: fact_1.0_1.0.0.0-663_31-MAY-2011_02.22.291 -mkbranch fireaphis_1.0_2",
        "./test/a20.cpp@@/main/fact_1.0_Integ/3 [hijacked]            Rule: fact_1.0_1.0.0.0-663_31-MAY-2011_02.22.291 -mkbranch fireaphis_1.0_2",
        "./test/a21.h@@/main/fact_1.0_Integ/fireaphis_1.0_2/2     Rule: .../fireaphis_1.0_2/LATEST",
        "./test/a22.cpp.obsolete@@/main/fact_1.0_Integ/3              Rule: fact_1.0_1.0.0.0-663_31-MAY-2011_02.22.291 -mkbranch fireaphis_1.0_2",
        "./test/a23.h.obsolete@@/main/fact_1.0_Integ/2                Rule: fact_1.0_1.0.0.0-663_31-MAY-2011_02.22.291 -mkbranch fireaphis_1.0_2"
      ].join("\n"))

    cc = Fact::ClearCase.new
    cc.cleartool = ct

    hijacked = []

    err = catch(:wrongInvocation) { hijacked = cc.get_hijacked_files }
    assert(ct.succeeded, err)

    expected = [{:file=>"a16.h",                 :version=>"/main/fact_1.0_Integ/fireaphis_1.0_2/2"},
                {:file=>"./test/a18.h.obsolete", :version=>"/main/fact_1.0_Integ/3"                },
                {:file=>"./test/a20.cpp",        :version=>"/main/fact_1.0_Integ/3"                }] 
    assert_equal(expected, hijacked)
  end

end


class FileBackupTests < Test::Unit::TestCase

  def setup
    @dir  = "test_backup_file" 
    @file = "#{@dir}/test.cpp.keep"
    Dir.mkdir(@dir)
  end

  def teardown
    system("rm -r #{@dir}")
  end

  def test_no_file
    # Create existing backup files
    (1 .. Fact::ClearCase::MAX_BACKUP_VERSIONS).each do |ver| 
      File.open("#{@file}.#{ver}", "w") { |f| f.write("booga") }
    end
    # Ensure that the correct number of files was created
    assert_equal(Fact::ClearCase::MAX_BACKUP_VERSIONS+2, Dir.entries(@dir).size)

    cc = Fact::ClearCase.new
    # The method should raise because the backed up file doesn't exist
    assert_raise(RuntimeError) { cc.backup_file(@file) }
    # Ensure that no new files were added
    assert_equal(Fact::ClearCase::MAX_BACKUP_VERSIONS+2, Dir.entries(@dir).size)
  end

  def test_99_files
    # Create the file that will be backed up
    File.open(@file, "w") {|f| f.write("booga")}

    # Create existing backup files
    (1 .. Fact::ClearCase::MAX_BACKUP_VERSIONS-1).each do |ver| 
      File.open("#{@file}.#{ver}", "w") { |f| f.write("booga") }
    end
    # Ensure that the correct number of files was created
    assert_equal(Fact::ClearCase::MAX_BACKUP_VERSIONS+2, Dir.entries(@dir).size)
    # Ensure that the back-up file that will be created doesn't exist yet
    assert(!File.exists?("#{@file}.#{Fact::ClearCase::MAX_BACKUP_VERSIONS}"))

    cc = Fact::ClearCase.new
    assert_nothing_raised { cc.backup_file(@file) }
    # Ensure that the backup was created
    assert(File.exists?("#{@file}.#{Fact::ClearCase::MAX_BACKUP_VERSIONS}"))
    # The orginal file should not exist now
    assert(!File.exists?(@file))
  end

  def test_100_files
    # Create the file that will be backed up
    File.open(@file, "w") {|f| f.write("booga")}

    # Create existing backup files
    (1 .. Fact::ClearCase::MAX_BACKUP_VERSIONS).each do |ver| 
      File.open("#{@file}.#{ver}", "w") { |f| f.write("booga") }
    end
    # Ensure that the correct number of files was created
    assert_equal(Fact::ClearCase::MAX_BACKUP_VERSIONS+3, Dir.entries(@dir).size)

    cc = Fact::ClearCase.new
    # The method should raise because there are too many back up files 
    assert_raise(RuntimeError) { cc.backup_file(@file) }
    # Ensure that no new files were added
    assert_equal(Fact::ClearCase::MAX_BACKUP_VERSIONS+3, Dir.entries(@dir).size)
    # The orginal file should still exist
    assert(File.exists?(@file))
  end

end
