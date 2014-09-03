# windowspagefile

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with windowspagefile](#setup)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
7. [Contributing - Contribute to this modules development](#contribue)

## Overview

A puppet type and provider to manage the creation/deletion/updation of windows
pagefiles using WMI via ruby's win32ole.

## Module Description

The provider is capable of setting the initial size and maximum size for a
windows page file or it can let the page file size be managed by the operating system.

## Setup

### Installation

The module can be installed directly from the Puppet Forge

     puppet module install ptierno-windowspagefile

Or you can clone this repo into your `modulepath`

     git clone https://github.com/ptierno/puppet-windowspagefile.git

## Usage

### Examples

Managing a page files size

     pagefile { 'c:\pagefile.sys':
       initialsize => 1024,
       maximumsize => 1024
     }

Letting windows manage the page files size

     pagefile { 'c:\pagefile.sys':
       systemmanaged => true
     }

Removing a page file

     pagefile { 'c:\pagefile.sys':
       ensure => absent
     }

If you leave out either `initialsize` or `maximumsize` if will use the value of the other

     # maximumsize will inherit the value of initialsize
     pagefile { 'c:\pagefile.sys':
       initialsize => 1024
     }

If you use this module to manage a pagefile (or more), it will automatically disable the Windows option to
have the system automatically manage pagefiles for all drives. (different than system managed size for a single pagefile)

If you set all of your managed pagefiles `ensure` value to `absent` it will turn this feature back on.


## Limitations

This provider has been tested on the following windows operating systems:

* Windows Server 2008 R2
* Windows Server 2012 R2

## Development

Please submit any issues using the github issue tracker

* https://github.com/ptierno/puppet-windowspagefile/issues

If you have any questions, feel free to contact me via email.

Peter Tierno <peter.a.tierno@gmail.com>

## Contributing

* fork
* update
* pull request
* joy

## License

Copyright (C) 2014 Peter Tierno

     Licensed under the Apache License, Version 2.0 (the "License");
     you may not use this file except in compliance with the License.
     You may obtain a copy of the License at

         http://www.apache.org/licenses/LICENSE-2.0

     Unless required by applicable law or agreed to in writing, software
     distributed under the License is distributed on an "AS IS" BASIS,
     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     See the License for the specific language governing permissions and
     limitations under the License.
