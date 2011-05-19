
require "rubygems"
require "highline/import"
require "~/dev/fact/clearcase"
require "~/dev/fact/files_cli.rb"

module Fact

class ActivitiesCli

  #
  #
  def ActivitiesCli.choose_undelivered_activity

    stream = ClearCase.get_current_stream
    return if stream==""

    puts ""
    say("The current stream is <%= color('#{stream}', BOLD) %>. Fetching the stream activities... ")
    activities = ClearCase.get_activities
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

      end
    end

  end


  #
  #
  def ActivitiesCli.choose_file_from_activity(activity_name)

    puts ""
    say("Fetching the change set for the activity <%= color('#{activity_name}', BOLD) %>... ")
    changeset = ClearCase.get_activity_change_set(activity_name)
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
          suffix = "version#{"s" unless versions.size<2}) #{"<%= color('CHECKED-OUT!', :red) %>" if ClearCase.checkout_version?(versions.last)}"
          menu.choice("#{file} (#{versions.size} #{suffix}") { file }
        end

      end
    end

  end


end

end



activity = Fact::ActivitiesCli.choose_undelivered_activity
unless activity.nil?
  file = Fact::ActivitiesCli.choose_file_from_activity(activity)
  file_info = Fact::ClearCase.get_file_info(file)
  puts ""
  Fact::FilesCli.show_file_info(file_info)
end
