
require "rubygems"
require "highline/import"
require "~/dev/fact/clearcase"

module Fact

class FilesCli

  #
  #
  def FilesCli.show_file_info(info)

    if ClearCase.checkout_version?(info[:version])
      last_ver_text = "<%= color('CHECKED-OUT!', :red) %>"
    else
      last_ver_text = "#{info[:version]}"
    end

    # Spliting the path and the name so the name can be shown in bold
    path      = info[:name].scan(/.*\//)[0]
    file_name = info[:name].scan(/\/[^\/]+$/)[0]
    file_name.slice!(0) # Removing the leading slash

    say("#{path}<%= color('#{file_name}', BOLD) %>")
    say("    Last activity:")
    say("        Activity name: #{info[:activity]}")
    say("        Last version:  #{last_ver_text}")
    say("                       created on #{info[:date]}")
    say("                       #{info[:versions_count]-1} more version#{"s" unless info[:versions_count]==2} in the activity")
    say("    Activity predecessor: #{info[:changeset_predecessor]}")
  end

end
end
