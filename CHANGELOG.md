# 2015-02-11 - Bugfix Release 1.2.2

* Munge to lowercase if $::operatinsystemrelease =~ /2008/
* Munge to capitalize if $::operatingsystemrelease =~ /2012/

# 2014-09-17 - Release 1.2.1

* Add requirements to metadata.json

# 2014-09-02 - Release 1.2.0

* Enable `AutomaticManagedPageFile` when destroying a pagefile and the `self.instances` count is 0
* Utilize `self.flush` in the `create` method.
* If `maximumsize` is not set it will inherit the value of `initialsize` and vice versa.
* Refactor some of the WMI interactions to use `to_enum`, `find`, etc.

# 2014-08-12 - Release 1.1.0

* Use `Puppet::Util::Windows::ADSI` for wmi connections with `Puppet::Util::ADSI` as a fallback for Puppet 3.7/PE 3.4 compatibility

# 2014-07-19 - Release 1.0.0

* Initial Commit
