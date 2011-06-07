

module Fact

class ClearTool
    def invoke(command_str)
      return `cleartool #{command_str}`
    end
end

class ClearCase

  def initialize
    @cleartool = ClearTool.new
  end

  # Get the name of the current stream.
  #
  def get_current_stream
    return @cleartool.invoke("lsstream -s").rstrip
  end

  # Get the name of the current view.
  #
  def get_current_view
    return @cleartool.invoke("lsview -s -cview").rstrip
  end

  # Get the previous version of the version specified in the arguments.
  #
  def get_previous_version(file, version)
    return @cleartool.invoke("desc -pred -s #{create_cc_version(file,version)}").rstrip
  end

  # Returns the name of the current activity in the current view.
  #
  def get_current_activity
    return @cleartool.invoke("lsact -cact -s").rstrip
  end

  # Get all the non-obsolete activities in the current view.
  # Returns an array of hashes. Each hash represents an activity and contains 
  # two keys: :name and :headline.
  #
  def get_activities
    return parse_lsact_output(@cleartool.invoke('lsact -fmt "%[name]p,%[headline]p,"'))
  end

  # Creates a new activity and sets it as the active activity.
  def create_activity(act_name)
    @cleartool.invoke("mkact -f -headline \"#{act_name}\"")
  end

  # Get version information. The argument must be a hash with keys :file and :version.
  # Returns a version info hash.
  #
  def get_version_info(file_version)

    # Get the properties of the latest version of the file
    version_str = create_cc_version(file_version[:file],file_version[:version])
    format_str  = '"version=%Sn, activity=%[activity]p, date=%Sd, type=%m, predecessor=%PVn, user=%Fu, checkout=%Tf"'
    curr_version_info = parse_describe_file(@cleartool.invoke("desc -fmt #{format_str} #{version_str}"))
    return if curr_version_info.nil?

    # Retreive all the change set to find the earliest version of the file in the change set
    change_set = get_activity_change_set(curr_version_info[:activity])
    return if change_set.nil?

    # Get the file name component of the file version string
    file = file_version[:file]

    # Get versions array for the file
    versions = change_set[file]

    # Adding additional information to the existing hash
    curr_version_info[:name] = file
    curr_version_info[:changeset_predecessor] = get_previous_version(file, versions.first)
    curr_version_info[:versions_count] = versions.size

    return curr_version_info
  end

  # Returns the changes that were made as a part of the specified activity.
  # Returns a hash where the key is a file names and the value is a list of versions of 
  # that file. If there are no files in the activity, returns an empty hash.
  #
  def get_activity_change_set(activity_name)

    # Get a string that is space separated list of all the versions in the activity
    versions_dump = @cleartool.invoke("lsact -fmt \"%[versions]p\" #{activity_name}")

    # Will convert the string into a hash of filenames and lists of version numbers
    change_set = Hash.new { |hash,key| hash[key]=[] }

    # Convert the string into a sorted array and iterate it
    versions_dump.split(" ").sort.each do |version_str|
      version = parse_cc_version(version_str)
      change_set[version[:file]].push("#{version[:version]}")
    end

    return change_set
  end

  # Get a list of the hijacked files in the current directory and all the
  # subdirectories. Return a list of hashes. Each hash having keys
  # :file and :version.
  #
  def get_hijacked_files
    # Get recursively all the files in the current and child directories
    ls_out = @cleartool.invoke("ls -r")

    files = []

    ls_out.each_line do |ls_line|
      # Find all the hijacks
      if ls_line =~ /(.*) \[hijacked\]/
        files.push(parse_cc_version($1))
      end
    end

    return files
  end

  # Undo the hijack. Return to the VOB version; save the changes in .keep file.
  #
  def undo_hijack(file_name)
    @cleartool.invoke("update -rename #{file_name}")
  end

  #
  #
  def checkout_hijacked(file_name)
    @cleartool.invoke("co -nq -nc #{file_name}")
  end

  # Launches the default diff tool comparing two versions of a file.
  # The first parameter is the name of an existing file. The second and the third 
  # parameters are strings indicating versions of the same file.
  # If one of the versions is checkedout then compared with the file as it appares
  # currently on the disc. Beware that if the file is checked out from a different
  # view, the diff will compare wrong files.
  #
  def diff_versions(file, version1, version2)
    ver1 = checkout_version?(version1) ? file : create_cc_version(file,version1)
    ver2 = checkout_version?(version2) ? file : create_cc_version(file,version2)
    @cleartool.invoke("diff -gra #{ver1} #{ver2}")
  end

  # Launches the default diff tool comparing the local, on-disk version of a file
  # with the specified vob version. The version must be a qualified vob version;
  # it won't work with checked out versions.
  #
  def diff_vob_version(file, version)
    full_version = create_cc_version(file, version)
    @cleartool.invoke("diff -gra #{full_version} #{file}")
  end

  # Parses a string representing ClearCase element version and converts it into a hash
  # with a key for each part of the version string.
  #
  # version_str is expected to be of the following form:
  #
  #       <file full path>@@<branch name>/{<version number>|CHECKEDOUT.<checkout number>}
  #
  # Returns a hash with the following keys: :file, :version.
  #
  def parse_cc_version(version_str)
    if version_str =~ /(.*)@@(.+)\/(CHECKEDOUT\.)?(\d+)$/
      return { :file => $1, :version => "#{$2}/#{$3}#{$4}" }
    end
  end

  # Build a string that is a qualified ClearCase file version.
  #
  def create_cc_version(file, version)
    return "#{file}@@#{version}"
  end

  # Parse the output of the cleartool describe command. The text is expected to be of a specific
  # format and not the regular cleartool describe -long.
  #
  def parse_describe_file(describe_str)
    if describe_str =~ /version=(.*), activity=(.*), date=(.*), type=(.*), predecessor=(.*), user=(.*), checkout=(.*)$/
      return { :version=>$1, :activity=>$2, :date=>$3, :type=>$4, :predecessor=>$5, :user=>$6, :checkout=>$7 }
    end
  end

  # Converts the textual result of the lsact command into an array of activities.
  # The input string is expected to be of the following format:
  #
  #       (<activity name>,<activity headline>,)*
  #
  # Returns an array of hashes. Each hash has two keys: :name and :headline.
  #
  def parse_lsact_output(lsact)

    activities = []

    # Takes the string and convers it to an array of name-headline pairs
    lsact.scan(/(.*?),(.*?),/).each do |pair|
      activities += [{ :name => pair[0], :headline => pair[1] }]
    end

    return activities
  end

  def checkout_version?(version)
    return version =~ /CHECKEDOUT/
  end

  def cleartool=(new_ct)
    @cleartool = new_ct
  end

end

end

