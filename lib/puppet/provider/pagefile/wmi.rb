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
    if ENV.has_key?('ProgramFiles(x86)')
      commands :wmic => "#{Dir::WINDOWS}\\sysnative\\wbem\\WMIC.exe"
    else
      commands :wmic => "#{Dir::WINDOWS}\\system32\\wbem\\WMIC.exe"
    end
  end

  def initialize(value={})
    super(value)
    wmic('computersystem','set','AutomaticManagedPageFile=False') if `wmic computersystem get automaticmanagedpagefile`.scan(/FALSE/).empty?
    @property_flush = {}
  end

  def self.adsi
    begin
      Puppet::Util::Windows::ADSI
    rescue
      Puppet::Util::ADSI
    end
  end

  def adsi
    self.class.adsi
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def self.instances
    pagefiles = []
    adsi.execquery('SELECT * FROM Win32_PageFileSetting').each do |pagefile|
      pagefiles << pagefile
    end

    pagefiles.collect do |pagefile|
      if pagefile.initialsize == 0 and pagefile.maximumsize == 0
        system_managed = :true
      else
        system_managed = :false
      end
      new(
        :name          => pagefile.name,
        :ensure        => :present,
        :initialsize   => pagefile.initialsize,
        :maximumsize   => pagefile.maximumsize,
        :systemmanaged => system_managed
      )
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    if resource[:systemmanaged] == :true
      if resource[:initialsize] or resource[:maximumsize]
        resource.fail('initialsize and maximumsize should not be set when using systemmanaged')
      else
        initialsize = 0
        maximumsize = 0
      end
    else
      initialsize = resource[:initialsize]
      maximumsize = resource[:maximumsize]
    end
    objService = adsi.connect('winmgmts:{impersonationLevel=impersonate}//./root/CIMV2:Win32_PageFileSetting')
    pagefile   = objService.SpawnInstance_()

    pagefile.name        = resource[:path]
    pagefile.initialsize = initialsize
    pagefile.maximumsize = maximumsize
    pagefile.Put_()
    true
  end

  def destroy
    adsi.wmi_connection.InstancesOf('Win32_PageFileSetting').each do |pagefile|
      pagefile.Delete_() if pagefile.name == resource[:path]
    end
    @property_hash.clear
  end

  def systemmanaged=(value)
    @property_flush[:systemmanaged] = value
  end

  def initialsize=(value)
    @property_flush[:initialsize] = value
  end

  def maximumsize=(value)
    @property_flush[:maximumsize] = value
  end

  def flush
    pagefile = nil
    if @property_flush
      if (resource[:initialsize] or resource[:maximumsize]) and resource[:systemmanaged] == :true
        resource.fail('initialsize and maximumsize should not be set when using systemmanaged')
      end
      adsi.wmi_connection.InstancesOf('Win32_PageFileSetting').each do |instance|
        if instance.name == resource[:path]
          pagefile = instance if @property_flush[:initialsize] or @property_flush[:maximumsize] or @property_flush[:systemmanaged]
        end
      end
      if pagefile
        if resource[:systemmanaged] == :true
          pagefile.initialsize = 0
          pagefile.maximumsize = 0
        else
          pagefile.initialsize = resource[:initialsize]
          pagefile.maximumsize = resource[:maximumsize]
        end
        pagefile.Put_()
        Puppet.notice("Pagefile[#{resource[:path]}]: A reboot is required for the pagefile settings to take effect.")
      end
    end
    @property_hash = resource.to_hash
  end
end
