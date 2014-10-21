require 'fileutils'
require 'tempfile'

Puppet::Type.type(:path_env).provide(:ruby) do

  def exists?
    code = match_path

    if ( resource[:ensure].to_s == 'absent' and code == 1 )
      return true
    elsif ( resource[:ensure].to_s == 'absent' and code == 0 )
      return false
    elsif ( resource[:ensure].to_s == 'present' and code == 0 )
      return false
    elsif ( resource[:ensure].to_s == 'present' and code == 1 )
      return true
    end
  end

  def create
    code = match_path

    if code == 0
      add_path
    elsif code == 1
      remove_path

      if match_path == 0
        add_path
      end
    end
  end

  def destroy
    code = match_path

    if code == 1
      remove_path
    end
  end

  def content_path
    txt_path = nil

    if resource[:include_existing_path]
      txt_path = '${PATH}:'
    end

    return "PATH=\"#{txt_path}#{resource[:directories]}\"\n"
  end

  def match_path
    code = 0

    if File.exists?(resource[:path])
      txt_path = nil

      if resource[:include_existing_path]
        txt_path = '\$\{PATH\}:'
      end

      File.readlines(resource[:path]).each do |line|
        if ( line =~ /^PATH\=\"#{txt_path}#{resource[:directories]}\"\n/ )
          code = 1
        end
      end
    end

    return code
  end

  def add_path
    if resource[:state].to_s == 'new'
      if File.exists?(resource[:path])
        code = match_path

        if code == 0
          File.unlink(resource[:path])
        end
      end

      File.open(resource[:path], 'w') do |fh|
        fh.puts "# This file is being maintained by Puppet.\n# DO NOT EDIT\n\n"
        fh.puts content_path
      end
    elsif resource[:state].to_s == 'update'
      append_path
    end
  end

  def remove_path
    if resource[:state].to_s == 'new'
      if File.exists?(resource[:path])
        File.unlink(resource[:path])
      end
    elsif resource[:state].to_s == 'update'
      tmp = Tempfile.new("profile_path")
      prev = 0

      File.open(resource[:path], 'r').each do |line|
        code = 0
        blank = 0

        if line.chomp =~ /#\sPuppet Name:\s#{resource[:name]}|^PATH\=.*/
          code = 1
        elsif ( line.chomp =~ /^$|^\n$/ ) and ( prev == 1 )
          blank = 1
        elsif line.chomp =~ /^$|^\n$/
          prev = 1
        else
          prev = 0
          blank = 0
        end

        tmp << line unless ( ( code == 1 ) or ( blank == 1 ) )
      end

      tmp.close

      FileUtils.mv(tmp.path, resource[:path])
    end
  end

  def append_path
    File.open(resource[:path], 'a') do |fh|
      fh.puts "\n# Puppet Name: #{resource[:name]}"
      fh.puts content_path
    end
  end
end
