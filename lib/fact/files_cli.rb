
# System libraries
require "highline/import"

# Local libraries
require "fact/clearcase"


module Fact

class Cli

  #
  #
  def Cli.browse_hijacked
    cc = Fact::ClearCase.new

    puts ""
    say("Scanning for hijacked files in <%= color('#{File.absolute_path('.')}', BOLD) %>... ")
    files = cc.get_hijacked_files
    say("Done")

    if files.empty?
      say("No hijacked files.")
    else
      say("The hijacked files in the directory and its subdirectories are:")

      # Show the hijacked files list in a menu
      chosen_hijack = choose do |menu|
        menu.prompt    = "Choose a file: "
        menu.select_by = :index

        files.each do |file|
          menu.choice(file[:file]) { file  }
        end

        # Undo hijack for all the files in one command
        file_names = files.collect {|f| f[:file]}
        menu.choice("Keep the changes and checkout all the files") { cc.checkout_hijacked(file_names); exit(true) }

        # The last entry allows graceful exit
        menu.choice("Exit") { exit(true) }
      end

      Cli.operate_hijacked_file(chosen_hijack[:file], chosen_hijack[:version])

    end
  end

  #
  #
  def Cli.operate_hijacked_file(file_name, original_version)
    cc = Fact::ClearCase.new

    puts ""
    say("Hijacked file <%= color('#{file_name}', BOLD) %>")
    choose do |menu|
        menu.prompt    = "Enter command number: "
        menu.select_by = :index

        menu.choice("Compare with the latest version") do
          puts ""
          say("Graphical diff is being opened in an external application.")
          cc.diff_vob_version(file_name, original_version)
        end

        menu.choice("Drop the changes and renounce the hijack") { cc.undo_hijack([file_name])       }
        menu.choice("Keep the changes and checkout")            { cc.checkout_hijacked([file_name]) }
        menu.choice("Exit") { exit(true) }
      end
  end

  # The parameter must be a hash with the following keys:
  #
  #     :version, :name, :activity, :date, :user,
  #     :versions_count, :changeset_predecessor
  #
  def Cli.show_version_info(info)

    cc = ClearCase.new

    if cc.checkout_version?(info[:version])
      last_ver_text = "<%= color('CHECKED-OUT!', :red) %> in #{info[:checkout]}"
    else
      last_ver_text = "#{info[:version]}"
    end

    # Splitting the path and the name so the name can be shown in bold
    path      = info[:name].scan(/.*\//)[0]
    file_name = info[:name].scan(/\/[^\/]+$/)[0]
    file_name.slice!(0) # Removing the leading slash

    say("#{path}<%= color('#{file_name}', BOLD) %>")
    say("    Last activity:")
    say("        Activity name: #{info[:activity]}")
    say("        Last version:  #{last_ver_text}")
    say("                       created on #{info[:date]} by #{info[:user]}")
    say("                       #{info[:versions_count]-1} more version#{"s" unless info[:versions_count]==2} in the activity")
    say("    Activity predecessor: #{info[:changeset_predecessor]}")
  end

end
end
