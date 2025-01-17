# snowUtils

A collection of Functions and Cmdlets which I use regularly.

## Building & Importing

This project follows the Compiler-Compiler Problem (use the compiled software to compile itself). It essentially boils down to this:

- The first compile needs to be manual
- From the second one onward you can use an internal function called ``Build-Module`` which will rebuild the project and optionally load the just compiled module.

### The first build

To build this module for Windows and load it, use these commands:

```powershell
dotnet restore -r win-x64
dotnet publish -r win-x64 -o ./build ./snowUtils

# load the module
Import-Module ./build/snowUtils.psd1

# Verify that the module has been loaded
Get-Module -Name snowUtils
```

### Using the module to build the module easier

This module, as mentioned previously contains the Function ``Build-Module`` which can be used to rebuild the module and then (possibly) load it.

```powershell
Build-Module snowUtils; Import-Module .\build\snowUtils.psd1
```