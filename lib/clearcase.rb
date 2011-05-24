

module Fact

class ClearCase

  # Get the name of the current stream.
  #
  def ClearCase.get_current_stream
    return `cleartool lsstream -s`.rstrip
  end

  #
  #
  def ClearCase.get_previous_version(file, version)
    return `cleartool desc -pred -s #{create_cc_version(file,version)}`.rstrip
  end

  # Get all the non-obsolete activities in the current view.
  # Returns an array of hashes. Each hash represents an activity and contains 
  # two keys: :name and :headline.
  #
  def ClearCase.get_activities
    return parse_lsact_output(`cleartool lsact -fmt "%[name]p,%[headline]p,"`)
  end

  # Get version information. The argument must be a hash with keys :file and :version.
  # Returns a version info hash.
  #
  def ClearCase.get_version_info(file_version)

    # Get the properties of the latest version of the file
    version_str = create_cc_version(file_version[:file],file_version[:version])
    format_str  = "version=%Sn, activity=%[activity]p, date=%Sd, type=%m, predecessor=%PVn, user=%Fu"
    curr_version_info = parse_describe_file(`cleartool desc -fmt "#{format_str}" #{version_str}`)
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
  def ClearCase.get_activity_change_set(activity_name)

    # Get a string that is space separated list of all the versions in the activity
    versions_dump = `cleartool lsact -fmt "%[versions]p" #{activity_name}`

    # Will convert the string into a hash of filenames and lists of version numbers
    change_set = Hash.new { |hash,key| hash[key]=[] }

    # Convert the string into a sorted array and iterate it
    versions_dump.split(" ").sort.each do |version_str|
      version = parse_cc_version(version_str)
      change_set[version[:file]].push("#{version[:version]}")
    end

    return change_set
  end

  # Launches the default diff tool comparing the a file with its other version.
  # The first parameter is the name of an existing file. The second parameter is
  # a string indicating a version of the same file.
  #
  def ClearCase.diff_other_version(file, version)
    diff_process = fork { exec "cleartool diff -gra #{file} #{create_cc_version(file,version)}" }
    Process.detach(diff_process)
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
  def ClearCase.parse_cc_version(version_str)
    if version_str =~ /(.*)@@(.+)\/(CHECKEDOUT\.)?(\d+)$/
      return { :file => $1, :version => "#{$2}/#{$3}#{$4}" }
    end
  end

  # Build a string that is a qualified ClearCase file version.
  #
  def ClearCase.create_cc_version(file, version)
    return "#{file}@@#{version}"
  end

  #
  #
  def ClearCase.parse_describe_file(describe_str)
    if describe_str =~ /version=(.*), activity=(.*), date=(.*), type=(.*), predecessor=(.*) user=(.*)$/
      return { :version=>$1, :activity=>$2, :date=>$3, :type=>$4, :predecessor=>$5, :user=>$6 }
    end
  end

  # Converts the textual result of the lsact command into an array of activities.
  # The input string is expected to be of the following format:
  #
  #       (<activity name>,<activity headline>,)*
  #
  # Returns an array of hashes. Each hash has two keys: :name and :headline.
  #
  def ClearCase.parse_lsact_output(lsact)

    activities = []

    # Takes the string and convers it to an array of name-headline pairs
    lsact.scan(/(.*?),(.*?),/).each do |pair|
      activities += [{ :name => pair[0], :headline => pair[1] }]
    end

    return activities
  end

  def ClearCase.checkout_version?(version)
    return version =~ /CHECKEDOUT/
  end

end

end

