require 'puppet/parameter/boolean'

Puppet::Type.newtype(:proxy_env) do
  @doc = %q{Set http proxy env variables. Depending
    on the state, this may create a new file or update an existing file.

    Example:

        proxy_env { 'example1':
          ensure     => 'present',
          state      => 'new',
          fqdn       => 'proxy.example.com',
          port       => 8080,
          exceptions => 'localhost,.example.com',
          path       => '/etc/profile.d/proxy.sh',
        }

        proxy_env { 'example2':
          ensure     => 'present',
          state      => 'update',
          fqdn       => 'proxy.example.com',
          port       => 8080,
          exceptions => 'localhost,.example.com',
          path       => '/etc/profile',
        }
    }

  ensurable

  newparam(:name, :namevar => true) do
    desc 'An arbitrary name used as the identity of the resource.'
  end

  newparam(:state) do
    desc 'State is new or update.'

    newvalues(:new, :update)
  end

  newparam(:fqdn) do
    desc 'Proxy host fqdn address.'

    validate do |value|
      unless value =~ /(?=^[a-zA-Z0-9\-\.]{1,254}$)(^(?!\-)([a-zA-Z0-9\-]{1,63}\.)+[a-zA-Z]{2,63}$)/
        raise(Puppet::Error, "'#{value}' is not a valid fqdn")
      end
    end
  end

  newparam(:port) do
    desc 'Proxy port number.'

    #validate do |value|
    #  unless value =~ /^([1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$/
    #    raise(Puppet::Error, "'#{value}' is not a valid port number")
    #  end
    #end
  end

  newparam(:exceptions) do
    desc 'Exceptions'
  end

  newparam(:path) do
    desc 'The file Puppet will ensure contains the lines specified.'

    validate do |value|
      unless Puppet.features.posix? and value =~ /^\//
        raise(Puppet::Error, "File paths must be fully qualified, not '#{value}'")
      end
    end
  end

  autorequire(:file) do
    self[:path]
  end

  validate do
    unless self[:state] and self[:fqdn] and self[:path]
      raise(Puppet::Error, 'state, fqdn, and path are required attributes')
    end
  end
end
