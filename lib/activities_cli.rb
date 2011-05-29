
# System libraries
require "highline/import"

# Local libraries
require "clearcase"
require "files_cli"


module Fact

class Cli

  # Ask the user to choose from the list of all the undelivered activities
  # in the current stream.
  # Returns the name of the chosen activity.
  #
  def Cli.choose_undelivered_activity

    cc = ClearCase.new

    stream = cc.get_current_stream
    return if stream==""

    puts ""
    say("The current stream is <%= color('#{stream}', BOLD) %>. Fetching the stream activities... ")
    activities = cc.get_activities
    say("Done.")

    if activities.empty?
      say("No undelivered activities.")
    else
      say("These are the undelivered activities in the current stream:")

      return choose do |menu|
        menu.prompt    = "Enter the activity number: "
        menu.select_by = :index

        # Add a menu entry for each activity
        activities.each do |activity|
          menu.choice(activity[:headline]) { activity[:name] }
        end

        # The last entry allows graceful exit
        menu.choice("Exit") { exit(true) }

      end
    end

  end


  # Asks to choose from a list of files in the activity and returns the last version of
  # the file in the activity in a hash with keys :file and :version.
  #
  def Cli.choose_file_from_activity(activity_name)

    cc = ClearCase.new

    puts ""
    say("Fetching the change set for the activity <%= color('#{activity_name}', BOLD) %>... ")
    changeset = cc.get_activity_change_set(activity_name)
    say("Done.")

    if changeset.empty?
      say("The changeset is empty.")
    else
      say("The activity contains the following files:")

      # The method will return the choice from the menu
      return choose do |menu|
        menu.prompt    = "Enter the file number: "
        menu.select_by = :index

        #  Add a menu entry for each file in the changeset
        changeset.each do |file, versions|
          # Suffix contains the versions count and the check-out indicator
          suffix = "version#{"s" unless versions.size<2}) #{"<%= color('CHECKED-OUT!', :red) %>" if cc.checkout_version?(versions.last)}"
          menu.choice("#{file} (#{versions.size} #{suffix}") { {:file => file, :version => versions.last} }
        end

        # The last entry allows graceful exit
        menu.choice("Exit") { exit(true) }

      end
    end

  end


end

end


