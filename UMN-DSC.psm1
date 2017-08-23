###
# Copyright 2017 University of Minnesota, Office of Information Technology

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
###
enum State
{
    Enabled
    Disabled
}

enum Present
{
    Present
    NotPresent
}
<#
    dsc CLASS to enable the IIS remote management service 
#>
[DscResource()]
class WebMgmtSvcState
{

    # A DSC resource must define at least one key property.
    [DscProperty(Key)]
    [State]$state

    [DscProperty(NotConfigurable)]
    [string]$Key = "HKLM:\SOFTWARE\Microsoft\WebManagement\Server"

    [DscProperty(NotConfigurable)]
    [string]$ValueName = "EnableRemoteManagement"
    # Sets the desired state of the resource.
    [void] Set()
    {
        if ($this.state -eq [State]::Enabled)
        {
            ## Stop wmsvc
            Stop-Service wmsvc            
            $ValueData = "1"
            New-ItemProperty -Path $this.Key -Name $this.ValueName -Value $ValueData -Force
            ## re-enable service
            start-service wmsvc
        }
        else
        {
            ## Stop wmsvc
            Stop-Service wmsvc            
            $ValueData = "0"
            New-ItemProperty -Path $this.Key -Name $this.ValueName -Value $ValueData -Force
            ## re-enable service
            start-service wmsvc
        }
    }        
    
    # Tests if the resource is in the desired state.
    [bool] Test()
    {        
        if ($this.state -eq [State]::Enabled)
        {
            return ((Get-ItemPropertyValue -Path $this.Key -Name $this.ValueName) -eq 1)
        }
        else
        {
            return ((Get-ItemPropertyValue -Path $this.Key -Name $this.ValueName) -eq 0)
        }
    }    
    # Gets the resource's current state.
    [WebMgmtSvcState] Get()
    {
        $curState = Get-ItemPropertyValue -Path $this.Key -Name $this.ValueName
        if ($curState -eq 1){$this.state = [State]::Enabled}
        else {$this.state = [State]::Disabled}
        # Return this instance or construct a new instance.
        return $this 
    }    
}


# [DscResource()] indicates the class is a DSC resource.
[DscResource()]
class PackageProvider
{

    # A DSC resource must define at least one key property.
    [DscProperty(Key)]
    [Present]$present

    # Mandatory indicates the property is required and DSC will guarantee it is set.
    [DscProperty(Mandatory)]
    [string]$packageProvider
    
    # Sets the desired state of the resource.
    [void] Set()
    {
        if ($this.present -eq [Present]::Present){Install-PackageProvider -Name $this.packageProvider -MinimumVersion 2.8.5.201 -Force}
        # there doesn't seam to be a uninstall
    }        
    
    # Tests if the resource is in the desired state.
    [bool] Test()
    {        
        if ($this.present -eq [Present]::Present)
        {
            try{if((Get-PackageProvider -Name $this.packageProvider).Name -eq $this.packageProvider){return $true}else{return $false}}
            catch{return $false}
        }
        else{
            try{if((Get-PackageProvider -Name $this.packageProvider).Name -eq $this.packageProvider){return $false}else{return $true}}
            catch{return $true}
        }
    }    
    # Gets the resource's current state.
    [PackageProvider] Get()
    {        
        try{if((Get-PackageProvider -Name $this.packageProvider).Name -eq $this.packageProvider){$this.present = [Present]::Present}else{$this.present = [Present]::NotPresent}}
        catch{$this.present = [Present]::NotPresent}
        return $this
    }    
}

# The docker package is all jacked up.  Once you install it and logout, get-package will not return it so the test is broken
# hence the need for this goof thing
[DscResource()]
class PackageDocker
{

    # A DSC resource must define at least one key property.
    [DscProperty(Key)]
    [Present]$present
    
    # Sets the desired state of the resource.
    [void] Set()
    {
        if ($this.present -eq [Present]::Present){Install-Package -Name docker -ProviderName DockerMsftProvider -Confirm:$false -Force}
    }        
    
    # Tests if the resource is in the desired state.
    [bool] Test()
    {        
        if ($this.present -eq [Present]::Present)
        {
            if(Test-Path -Path 'C:\Program Files\Docker'){return $true}else{return $false}
        }
        else{
            if(Test-Path -Path 'C:\Program Files\Docker'){return $false}else{return $true}
        }
    }    
    # Gets the resource's current state.
    [PackageDocker] Get()
    {        
        if(Test-Path -Path 'C:\Program Files\Docker'){$this.present = [Present]::Present}else{$this.present = [Present]::NotPresent}
        return $this
    }    
}

# [DscResource()] indicates the class is a DSC resource. 
[DscResource()]
class cModule
{

    # A DSC resource must define at least one key property.
    [DscProperty(Mandatory)]
    [Present]$present

    # Mandatory indicates the property is required and DSC will guarantee it is set.
    [DscProperty(Key)]
    [string]$module
    
    [string]$requiredVersion

    # Sets the desired state of the resource.
    [void] Set()
    {
        if ($this.present -eq [Present]::Present)
        {
            if ($this.requiredVersion){Install-Module -Name $this.module -RequiredVersion $this.requiredVersion -Force}
            else{Install-Module -Name $this.module -Force}
            
        }
        else{
            if ($this.requiredVersion){Uninstall-Module -Name $this.module -RequiredVersion $this.requiredVersion -Force}
            else{Uninstall-Module -Name $this.module -Force}
        }
        # there doesn't seam to be a uninstall
    }        
    
    # Tests if the resource is in the desired state.
    [bool] Test()
    {        
        $mod = Get-Module -Name $this.module -ListAvailable
        if ($this.present -eq [Present]::Present)
        {
            if ($this.requiredVersion){if ($mod.Version -eq $this.requiredVersion){return $true}else{return $false}}
            else{if($mod -ne $null){return $true}else{return $false}}
        }
        else{
            if ($this.requiredVersion){if ($mod.Version -eq $this.requiredVersion){return $false}else{return $true}}
            else{if($mod -ne $null){return $false}else{return $true}}
        }
    }    
    # Gets the resource's current state.
    [cModule] Get()
    {        
        $mod = Get-Module -Name $this.module -ListAvailable
        if ($this.requiredVersion){if ($mod.Version -eq $this.requiredVersion){$this.present = [Present]::Present}else{$this.present = [Present]::NotPresent}}
        else{if($mod -ne $null){$this.present = [Present]::Present}else{$this.present = [Present]::NotPresent}}
        return $this
    }    
}
#

[DscResource()]
class DockerTransNet
{

    # A DSC resource must define at least one key property.
    [DscProperty(Key)]
    [Present]$present

    # Mandatory indicates the property is required and DSC will guarantee it is set.
    [DscProperty(Mandatory)]
    [string]$name
    
    [DscProperty(Mandatory)]
    [string]$interfaceName

    # Sets the desired state of the resource.
    [void] Set()
    { 
        $ErrorActionPreference = 'Stop'
        if ($this.present -eq [Present]::Present)
        {
            ## Validate InterfaceName exits
            # (Get-NetIPInterface -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"}).InterfaceAlias # single nic instance or containers with dynamic Interface names
            try{
                if (Get-NetAdapter -Name $this.interfaceName)
                {
                    docker network create -d transparent -o com.docker.network.windowsshim.interface=$($this.interfaceName) $($this.name)
                }
                else{Throw "Unable to Find Network Interface"}
            }catch{Throw "Unable to Find Network Interface"}
        }
    }        
    
    # Tests if the resource is in the desired state.
    [bool] Test()
    {        
        $ErrorActionPreference = 'Stop'
        if ($this.present -eq [Present]::Present)
        {
            try{if ((docker network inspect $($this.name) | ConvertFrom-Json).Name -eq $this.name){return $true}else{return $false}}
            catch{return $false}
        }
        else{
            try{if ((docker network inspect $($this.name) | ConvertFrom-Json).Name -eq $this.name){return $false}else{return $true}}
            catch{return $true}
        }
    }    
    # Gets the resource's current state.
    [DockerTransNet] Get()
    { 
        $ErrorActionPreference = 'Stop'
        try{if ((docker network inspect $($this.name) | ConvertFrom-Json).Name -eq $this.name){$this.present = [Present]::Present}else{$this.present = [Present]::NotPresent}}
        catch{$this.present = [Present]::NotPresent}
        return $this
    }    
}
