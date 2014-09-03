Puppet::Type.type(:pagefile).provide(:wmi) do
  @doc = "Manages Windows page files with WMI using win32ole"

  confine    :operatingsystem => :windows
  defaultfor :operatingsystem => :windows

  mk_resource_methods

  if Puppet.features.microsoft_windows?
    begin
      require 'puppet/util/windows/adsi'
    rescue LoadError
      require 'puppet/util/adsi'
    end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def self.instances
    pagefiles = adsi.wmi_connection.InstancesOf('Win32_PageFileSetting').to_enum

    pagefiles.collect do |pagefile|
      # if the initial and maximum size of the pagefile == 0
      # then the size is managed by the operating system
      if pagefile.InitialSize == 0 and pagefile.MaximumSize == 0
        system_managed = :true
      else
        system_managed = :false
      end
      new(
        :name          => pagefile.Name,
        :ensure        => :present,
        :initialsize   => pagefile.InitialSize,
        :maximumsize   => pagefile.MaximumSize,
        :systemmanaged => system_managed
      )
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    # We want to validate the properties before calling the Put_ method
    # So we won't have a rogue pagefile without its properties being managed
    validate_props

    # Turn off automatic pagefile management since
    # puppet will be managing them
    if automatic_managed?
      set_automatic_managed(false)
      resource.notice('Automatic pagefile management has been disabled')
    end

    objService    = adsi.connect('winmgmts:{impersonationLevel=impersonate}//./root/CIMV2:Win32_PageFileSetting')
    pagefile      = objService.SpawnInstance_()
    pagefile.Name = resource[:path]

    # Need to call the Put_ method to actually create the pagefile
    # Then call the setter methods after.
    pagefile.Put_()

    self.systemmanaged = resource[:systemmanaged] if resource[:systemmanaged]
    self.initialsize   = resource[:initialsize] if resource[:initialsize]
    self.maximumsize   = resource[:maximumsize] if resource[:maximumsize]
    self.flush
  end

  def destroy
    pagefile = adsi.wmi_connection.InstancesOf('Win32_PageFileSetting').to_enum.find { |f| f.Name == resource[:path] }
    pagefile.Delete_()

    # Turn on automatic pagefile management
    # if puppet is not managing any pagefiles
    if self.class.instances.count == 0
      set_automatic_managed(true)
      resource.notice('Automatic pagefile management has been enabled')
    end

    @property_hash.clear
  end

  def systemmanaged=(value)
    @property_flush[:initialsize]   = 0
    @property_flush[:maximumsize]   = 0
    @property_flush[:systemmanaged] = value
  end

  def initialsize=(value)
    self.maximumsize = value unless resource[:maximumsize]
    @property_flush[:initialsize] = value
  end

  def maximumsize=(value)
    self.initialsize = value unless resource[:initialsize]
    @property_flush[:maximumsize] = value
  end

  def flush
    if @property_flush

      validate_props

      instance = adsi.wmi_connection.InstancesOf('Win32_PageFileSetting').to_enum.find { |f| f.Name == resource[:path] }
      pagefile = instance if @property_flush[:initialsize] or @property_flush[:maximumsize] or @property_flush[:systemmanaged]

      if pagefile
        pagefile.InitialSize = @property_flush[:initialsize]
        pagefile.MaximumSize = @property_flush[:maximumsize]
        pagefile.Put_()
        resource.notice('A reboot is required for the pagefile settings to take effect.')
      end
    end
    @property_hash = resource.to_hash
  end

  private

  def automatic_managed?
    sys = adsi.wmi_connection.InstancesOf('Win32_ComputerSystem').to_enum.first
    sys.AutomaticManagedPageFile
  end

  def set_automatic_managed(bool)
    sys = adsi.wmi_connection.InstancesOf('Win32_ComputerSystem').to_enum.first
    if sys.AutomaticManagedPageFile != bool
      begin
        sys.AutomaticManagedPageFile = bool
        sys.Put_()
      rescue WIN32OLERuntimeError => e
        # Although the above Put_ operation succeeds
        # it still raises an OLE exception matching /0x80041001/
        # catching it here and raising if a different OLE
        # exception occurred
        raise e unless e.message =~ /80041001/
      end
    end
  end

  def validate_props
    # cannot set initial or maximumsize if
    # the system is managing the pagefile size
    if (resource[:initialsize] or resource[:maximumsize]) and resource[:systemmanaged] == :true
      resource.fail('initialsize and maximumsize should not be used with systemmanaged.')
    end
  end

  def self.adsi
    begin
      Puppet::Util::Windows::ADSI
    rescue NameError
      Puppet::Util::ADSI
    end
  end

  def adsi
    self.class.adsi
  end

end
