
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

    say("Scanning for hijacked files in <%= color('#{File.absolute_path('.')}', BOLD) %>... ")
    files = cc.get_hijacked_files
    say("Done")

    if files.empty?
      say("No hijacked files.")
    else
      puts files
    end
  end

  # Format and print to stdout the specified information.
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
