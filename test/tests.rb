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

class ClearCaseWrapperTests < Test::Unit::TestCase

  @@cc = Fact::ClearCase

  def test_parse_cc_version
    result = @@cc.parse_cc_version("/home/FireAphis/views/fireaphis_fact_1.0/vobs/fact/test/test.cpp@@/main/fact_1.0_Integ/fireaphis_fact_1.0/12");
    assert_not_nil(result)
    assert_equal("/home/FireAphis/views/fireaphis_fact_1.0/vobs/fact/test/test.cpp", result[:file])
    assert_equal("/main/fact_1.0_Integ/fireaphis_fact_1.0/12", result[:version])
  end

  def test_parse_lsact_output
    result = @@cc.parse_lsact_output("name_1,headline 1,")
    expected = [ { :name => "name_1", :headline => "headline 1" } ]
    assert_equal(expected, result)

    result = @@cc.parse_lsact_output("name_1,headline 1,name_1,headline 1,name_1,headline 1,")
    expected = [ { :name => "name_1", :headline => "headline 1" },
                 { :name => "name_1", :headline => "headline 1" },
                 { :name => "name_1", :headline => "headline 1" } ]
    assert_equal(expected, result)

    result = @@cc.parse_lsact_output("name_1,headline 1,name_2,headline 2,name_3,headline 3,")
    expected = [ { :name => "name_1", :headline => "headline 1" },
                 { :name => "name_2", :headline => "headline 2" },
                 { :name => "name_3", :headline => "headline 3" } ]
    assert_equal(expected, result)
  end

  def test_parse_describe_file
    result = @@cc.parse_describe_file("version=/main/fact_1.0_Integ/fireaphis_fact_1.0/8, activity=test_fact, date=2011-05-08, type=version, predecessor=/main/fact_1.0_Integ/fireaphis_fact_1.0/7, user=FireAphis")
    expected = { :version     => "/main/fact_1.0_Integ/fireaphis_fact_1.0/8", 
                 :activity    => "test_fact",
                 :date        => "2011-05-08",
                 :type        => "version",
                 :predecessor => "/main/fact_1.0_Integ/fireaphis_fact_1.0/7",
                 :user=>"FireAphis" }
    assert_equal(expected, result)
  end
end