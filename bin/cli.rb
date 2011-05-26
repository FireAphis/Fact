#!/usr/bin/ruby

# System libraries
require "rubygems"

# Allow requiring the files in this library even if it wasn't installed
# as a gem
libdir = File.expand_path("../lib", File.dirname(__FILE__))
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

# Local libraries
require "clearcase"
require "activities_cli"
require "files_cli"



cc = Fact::ClearCase.new

activity = Fact::Cli.choose_undelivered_activity

unless activity.nil?
  # Come back every time to showing the files in the activity
  loop do
    file_version = Fact::Cli.choose_file_from_activity(activity)

    say("Fetching the file description... ")
    version_info = cc.get_version_info(file_version)
    say("Done")

    puts ""
    Fact::Cli.show_version_info(version_info)
 
    puts ""
    if version_info[:checkout] != "" and version_info[:checkout] != cc.get_current_view
      say("The file is checked out in a different view. Check it in to diff.")
    elsif agree("Compare with the change set predecessor?")
      say("Graphical diff is being opened in an external application.")
      cc.diff_other_version(file_version[:file], file_version[:version], version_info[:changeset_predecessor])
    end
  end
end
