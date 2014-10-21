require 'fileutils'
require 'tempfile'

Puppet::Type.type(:proxy_env).provide(:ruby) do

  def exists?
    code = match_proxy

    if ( resource[:ensure].to_s == 'absent' ) and ( code == 1 or code == 2 )
      return true
    elsif ( resource[:ensure].to_s == 'absent' ) and ( code == 0 )
      return false
    elsif ( resource[:ensure].to_s == 'present' ) and ( code == 0 or code == 2 )
      return false
    elsif ( resource[:ensure].to_s == 'present' ) and ( code == 1 )
      return true
    end
  end

  def create
    code = match_proxy

    if code == 0
      add_proxy
    elsif code == 2
      remove_proxy

      if match_proxy == 0
        add_proxy
      end
    end
  end

  def destroy
    code = match_proxy

    if code == 1 or code == 2
      remove_proxy
    end
  end

  def content_proxy
    set_no_proxy = nil
    export_no_proxy = nil

    if resource[:exceptions]
      set_no_proxy = "no_proxy=\"#{resource[:exceptions]}\"\n\n"
      export_no_proxy = ' no_proxy'
    end

    return "http_proxy=\"http://#{resource[:fqdn]}:#{resource[:port]}\"\nhttps_proxy=\$\{http_proxy\}\nHTTP_PROXY=\$\{http_proxy\}\nHTTPS_PROXY=\$\{http_proxy\}\nftp_proxy=\$\{http_proxy\}\n\n#{set_no_proxy}export http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ftp_proxy#{export_no_proxy}\n"
  end

  def match_proxy
    code = 0

    if File.exists?(resource[:path])
      match = Array.new

      File.readlines(resource[:path]).each do |line|
        if ( line =~ /^http_proxy=\"http:\/\/#{resource[:fqdn]}:#{resource[:port]}\"\n/ )
          match.push(1)
        elsif ( line =~ /^https_proxy=\$\{http_proxy\}\n/ )
          match.push(1)
        elsif ( line =~ /^HTTP_PROXY=\$\{http_proxy\}\n/ )
          match.push(1)
        elsif ( line =~ /^HTTPS_PROXY=\$\{http_proxy\}\n/ )
          match.push(1)
        elsif ( line =~ /^ftp_proxy=\$\{http_proxy\}\n/ )
          match.push(1)
        elsif ( line =~ /^no_proxy=\"#{resource[:exceptions]}\"\n/ )
          match.push(1)
        elsif ( resource[:exceptions] and line =~ /^export http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ftp_proxy no_proxy\n$/ )
          match.push(1)
        elsif ( resource[:exceptions] == nil and line =~ /^export http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ftp_proxy\n$/ )
          match.push(1)
        end
      end

      if match.size == 0
        code = 0
      elsif ( resource[:exceptions] and match.size == 7 ) or ( resource[:exceptions] == nil and match.size == 6 )
        code = 1
      elsif ( resource[:exceptions] and ( match.size > 0 and match.size < 7 ) ) or ( resource[:exceptions] == nil and ( match.size > 0 and match.size < 6 ) )
        code = 2
      end
    end

    return code
  end

  def add_proxy
    if resource[:state].to_s == 'new'
      if File.exists?(resource[:path])
        code = match_proxy

        if code == 0 or code == 2
          File.unlink(resource[:path])
        end
      end

      File.open(resource[:path], 'w') do |fh|
        fh.puts "# This file is being maintained by Puppet.\n# DO NOT EDIT\n\n"
        fh.puts content_proxy
      end
    elsif resource[:state].to_s == 'update'
      append_proxy
    end
  end

  def remove_proxy
    if resource[:state].to_s == 'new'
      if File.exists?(resource[:path])
        File.unlink(resource[:path])
      end
    elsif resource[:state].to_s == 'update'
      tmp = Tempfile.new("profile_proxy")
      prev = 0

      File.open(resource[:path], 'r').each do |line|
        code = 0
        blank = 0

        if line.chomp =~ /#\sPuppet Name:\s.*|^(?i)[fht]*tp[s]?_proxy|^no_proxy|^export (?i:[fht]*tp[s]?_proxy\s?)+(no_proxy)?$/
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

  def append_proxy
    File.open(resource[:path], 'a') do |fh|
      fh.puts "\n# Puppet Name: #{resource[:name]}"
      fh.puts content_proxy
    end
  end
end
