#!/usr/bin/env ruby
# A Ruby program that bulk renames all files in a specific directory
# by prepending a prefix specified by the user.
#
# Copyright (C) Tim K 2018-2019. Licensed under MIT License.
# This file is a DialogBind example.

require 'dialogbind'
require 'fileutils'

# First get the directory where the files are stored
directory_original = guidirectoryselect('Please select a directory with the files that you want to rename.')

# Now get the prefix that the user wants to prepend to each file
prepend_prefix = guigets('What would you like to prepend to each file in that directory?')

# Iterate over files and rename them
files_processed = 0

Dir.glob(directory_original + '/*').each do |file|
	path_orig = file
	prepend_prefix_applied = prepend_prefix + File.basename(file)
	path_final = File.dirname(path_orig) + '/' + prepend_prefix_applied
	
	FileUtils.mv(path_orig, path_final)
	files_processed += 1
end

# Notify the user that we have just finished
guinotify('Processed and renamed ' + files_processed.to_s + ' files.', 'Finished!')

# Exit
exit 0

