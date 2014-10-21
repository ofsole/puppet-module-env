require 'puppet/parameter/boolean'

Puppet::Type.newtype(:path_env) do
  @doc = %q{Set path env variables. Depending
    on the state, this may create a new file or update an existing file.

    Example:

        proxy_env { 'example1':
          ensure                => 'present',
          state                 => 'new',
          include_existing_path => true,
          directories           => '/opt/example/bin:${PATH}',
          path                  => '/etc/profile.d/path.sh',
        }

        proxy_env { 'example2':
          ensure                => 'present',
          state                 => 'update',
          include_existing_path => true,
          directories           => '/opt/example/bin:${PATH}',
          path                  => '/etc/profile',
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

  newparam(:include_existing_path) do
    desc 'Include existing PATH variable'
  end

  newparam(:directories) do
    desc 'Directories'
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
    unless self[:state] and self[:include_existing_path] and self[:directories] and self[:path]
      raise(Puppet::Error, 'state, include_existing_path, directories, and path are required attributes')
    end
  end
end
