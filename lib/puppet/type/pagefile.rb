Puppet::Type.newtype(:pagefile) do
  ensurable

  newparam(:path) do
    isnamevar
    desc 'The path and file name of the page file.'
    validate do |value|
      fail("Invalid page file name. Must be an absolute path, got #{value}") unless Pathname.new(value).absolute?
    end
    munge do |value|
      value.capitalize
    end
  end

  newproperty(:systemmanaged) do
    desc 'Whether or not the pagefile size is automatically managed by the system'
    newvalues(:true,:false)
  end

  newproperty(:initialsize) do
    desc 'The initial size of the page file (MB)'
    munge do |value|
      Integer(value)
    end
  end

  newproperty(:maximumsize) do
    desc 'The maximum size of the page file (MB).'
    munge do |value|
      Integer(value)
    end
  end
end