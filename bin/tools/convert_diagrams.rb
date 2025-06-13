#!/usr/bin/env ruby

require 'find'
require 'optparse'

# Path to Draw.io desktop app (default installation path)
DRAWIO_PATH = "C:/Program Files/draw.io/draw.io.exe"

# Parse command line options
OPTIONS = {
  force: false
}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby convert_diagrams.rb [options]"
  opts.on("--force", "Convert all files regardless of modification time") do
    OPTIONS[:force] = true
  end
end.parse!

def validate_drawio_installation
  unless File.exist?(DRAWIO_PATH)
    puts "Error: draw.io executable not found at '#{DRAWIO_PATH}'"
    puts "Please install draw.io desktop app or update the path in the script"
    exit 1
  end
end

def needs_conversion?(drawio_file)
  return true if OPTIONS[:force]  # Always convert if force flag is used

  png_file = drawio_file.sub(/\.drawio$/, ".png")

  # If PNG doesn't exist, definitely need to convert
  return true unless File.exist?(png_file)

  # Compare modification times
  drawio_mtime = File.mtime(drawio_file)
  png_mtime = File.mtime(png_file)

  # Convert if drawio file is newer than PNG
  drawio_mtime > png_mtime
end

def convert_file(input_file)
  output_file = input_file.sub(/\.drawio$/, ".png")

  # Skip if no conversion needed
  unless needs_conversion?(input_file)
    puts "Skipping: #{input_file} (no changes detected)"
    return :skipped
  end

  # Construct and execute the command
  command = "\"#{DRAWIO_PATH}\" -x -f png -o \"#{output_file}\" \"#{input_file}\""

  print "Converting: #{input_file}... "
  result = system(command)

  if result
    puts "✓ Done"
    :success
  else
    puts "✗ Failed"
    :failed
  end
end

def process_project
  validate_drawio_installation

  # Statistics
  total_files = 0
  successful = 0
  failed = 0
  skipped = 0

  # Get the current directory (assumes script is in Rails root)
  rails_root = Dir.pwd

  puts "\nSearching for .drawio files in: #{rails_root}"
  puts "Force mode: #{OPTIONS[:force] ? 'ON' : 'OFF'}"
  puts "=" * 50

  Find.find(rails_root) do |path|
    # Skip common directories we don't want to process
    if File.directory?(path)
      if [ '.git', 'tmp', 'log', 'node_modules' ].include?(File.basename(path))
        Find.prune  # Don't descend into these directories
      else
        next
      end
    end

    # Process only .drawio files
    next unless path.end_with?('.drawio')

    total_files += 1
    case convert_file(path)
    when :success
      successful += 1
    when :failed
      failed += 1
    when :skipped
      skipped += 1
    end
  end

  # Print summary
  puts "\nConversion Summary"
  puts "=" * 50
  puts "Total .drawio files found: #{total_files}"
  puts "Successfully converted:    #{successful}"
  puts "Skipped (no changes):     #{skipped}"
  puts "Failed conversions:       #{failed}"
end

# Run the script
begin
  process_project
rescue => e
  puts "\nError: #{e.message}"
  puts e.backtrace
  exit 1
end
