function New-TeslaConnection {
    <#   
   .SYNOPSIS   
   Function to connect to a Tesla API
       
   .DESCRIPTION 
   Opens a connection to the Tesla API or refreshes the token. Returns the password grant which can be used to follow up on other functions

   .NOTES	
       Author: Robin Verhoeven
       Requestor: -
       Created: -
       
       

   .LINK
       https://github.com/Wobs01/Tesla

   .EXAMPLE   
   . New-TeslaConnection -credentials $cred
   

   #>
   
   
    [Cmdletbinding(DefaultParameterSetName = "NewToken")] 
    param([parameter(Mandatory = $false, ParameterSetName = "NewToken")]
        [PSCredential]$credentials,
        [parameter(Mandatory = $false, ParameterSetName = "Refreshtoken")]
        [switch]$refresh_token,
        [parameter(Mandatory = $false)]
        [string]$URL = "https://owner-api.teslamotors.com/",
        [parameter(Mandatory = $false)]
        [switch]$PassThru
        
                
    )
    
    if ([string]::IsNullOrEmpty($credentials.UserName)) {
        try {
            $credentials = Get-Credential -Message "Please provide your Tesla credentials" -ErrorAction Stop
        }
        catch {
            throw ("Unable to get credentials, please try again:`n" + $global:Error[0].Exception.Message)
        }
    }
    
    switch ($PSCmdlet.ParameterSetName) {
        "Refreshtoken" {
            $loginhash = @{
                "grant_type"    = "refresh_token";
                "client_id"     = "81527cff06843c8634fdc09e8ac0abefb46ac849f38fe1e431c2ef2106796384";
                "client_secret" = "c7257eb71a564034f9419ee651c7d0e5f7aa6bfbd18bafb5c5c033b093bb2fa3";
                "refresh_token" = $global:token.refresh_token
            }
        }
        default {
            $loginhash = @{
                "grant_type"    = "password";
                "client_id"     = "81527cff06843c8634fdc09e8ac0abefb46ac849f38fe1e431c2ef2106796384";
                "client_secret" = "c7257eb71a564034f9419ee651c7d0e5f7aa6bfbd18bafb5c5c033b093bb2fa3";
                "email"         = $credentials.UserName;
                "password"      = $credentials.GetNetworkCredential().password;
            }
        }
    }


    try {
        $loginJSON = $loginhash | ConvertTo-Json
        $requestURI = $URL + "/oauth/token"
        $global:token = Invoke-RestMethod -Method Post -Uri $requestURI -Body $loginJSON -ContentType "application/json" -ErrorAction Stop
        Write-Host "Authentication Successfull"
        
    }
    catch {
        throw ("Login Failed:`n" + $global:Error[0].Exception.Message)
    }
    if ($PassThru) {
        return $global:token
    }
    
}

function Get-TeslaVehiclelist {
    <#   
   .SYNOPSIS   
   Function to get vehicle list from the Tesla API
       
   .DESCRIPTION 
   List the vehicle list for the logged in account, a vehicle id can be specified

   .NOTES	
       Author: Robin Verhoeven
       Requestor: -
       Created: -
       
       

   .LINK
       https://github.com/Wobs01/Tesla

   .EXAMPLE   
   . Get-TeslaVehiclelist -id <id>
   

   #>
    
    [Cmdletbinding()] 
    param([parameter(Mandatory = $false)]
        [string]$id         
    )    

    $requestURI = "https://owner-api.teslamotors.com/api/1/vehicles/$id"
    $APIparameters = @{
        "URI"                = $requestURI;
        "method"             = "GET";
        "functionname"       = $MyInvocation.MyCommand;
        "functionparameters" = $PSBoundParameters
    }
   
    $vehicledata = New-TeslaAPICall @APIparameters
   
    return $vehicledata    
}

function Get-TeslaVehicleData {
    <#   
   .SYNOPSIS   
   Function to get vehicle data from the Tesla API
       
   .DESCRIPTION 
   List the vehicle date for the logged in account, a vehicle id must be specified

   .NOTES	
       Author: Robin Verhoeven
       Requestor: -
       Created: -
       
       

   .LINK
       https://github.com/Wobs01/Tesla

   .EXAMPLE   
   . Get-TeslaVehicleData -id <id>
   

   #>
    
    [Cmdletbinding()] 
    param([parameter(Mandatory = $true)]
        [string]$id
    )
    $requestURI = "https://owner-api.teslamotors.com/api/1/vehicles/$id/vehicle_data"
    $APIparameters = @{
        "URI"                = $requestURI;
        "method"             = "GET";
        "functionname"       = $MyInvocation.MyCommand;
        "functionparameters" = $PSBoundParameters
    }
   
    $vehicledata = New-TeslaAPICall @APIparameters
   
    return $vehicledata    
    
}

function Get-TeslaChargeState {
    <#   
   .SYNOPSIS   
   Function to get vehicle charge state from the Tesla API
       
   .DESCRIPTION 
   Get charge state for the vehicle, a vehicle id must be specified

   .NOTES	
       Author: Robin Verhoeven
       Requestor: -
       Created: -
       
       

   .LINK
       https://github.com/Wobs01/Tesla

   .EXAMPLE   
   . Get-TeslaChargeState -id <id>
   

   #>
    
    [Cmdletbinding()] 
    param([parameter(Mandatory = $true)]
        [string]$id,
        [parameter(Mandatory = $false)]
        [switch]$continious     
    )  
    $requestURI = "https://owner-api.teslamotors.com/api/1/vehicles/$id/data_request/charge_state"       
    $APIparameters = @{
        "URI"                = $requestURI;
        "method"             = "GET";
        "functionname"       = $MyInvocation.MyCommand;
        "functionparameters" = $PSBoundParameters
    }
   
    $vehicledata = New-TeslaAPICall @APIparameters
    if ($continious) {
        do {
            try {
                Write-Progress -Activity "Percent Charged $($vehicledata.battery_level)" -Status $vehicledata.charging_state -PercentComplete $vehicledata.battery_level
            }
            catch {
                throw ("Unable to show vehicle charge state, Error message:`n" + $global:Error[0].Exception.message)
            }
            Start-Sleep 1
            $vehicledata = New-TeslaAPICall @APIparameters
        } while ($vehicledata.charging_state -eq "Charging")
    }
    return $vehicledata
   
}

function Get-TeslaClimateState {
    <#   
   .SYNOPSIS   
   Function to get vehicle climate state from the Tesla API
       
   .DESCRIPTION 
   Get climate state for the vehicle, a vehicle id must be specified

   .NOTES	
       Author: Robin Verhoeven
       Requestor: -
       Created: -
       
       

   .LINK
       https://github.com/Wobs01/Tesla

   .EXAMPLE   
   . Get-TeslaClimateState -id <id>
   

   #>
    
    [Cmdletbinding()] 
    param([parameter(Mandatory = $true)]
        [string]$id      
    )  
    $requestURI = "https://owner-api.teslamotors.com/api/1/vehicles/$id/data_request/climate_state"       
    $APIparameters = @{
        "URI"                = $requestURI;
        "method"             = "GET";
        "functionname"       = $MyInvocation.MyCommand;
        "functionparameters" = $PSBoundParameters
    }
  
    $vehicledata = New-TeslaAPICall @APIparameters
  
    return $vehicledata
}

function Get-TeslaDriveState {
    <#   
  .SYNOPSIS   
  Function to get vehicle drive state from the Tesla API
      
  .DESCRIPTION 
  Get drive state for the vehicle, a vehicle id must be specified

  .NOTES	
      Author: Robin Verhoeven
      Requestor: -
      Created: -
      
      

  .LINK
      https://github.com/Wobs01/Tesla

  .EXAMPLE   
  . Get-TeslaDriveState -id <id>
  

  #>
   
    [Cmdletbinding()] 
    param([parameter(Mandatory = $true)]
        [string]$id      
    )  
    $requestURI = "https://owner-api.teslamotors.com/api/1/vehicles/$id/data_request/drive_state"       
    $APIparameters = @{
        "URI"                = $requestURI;
        "method"             = "GET";
        "functionname"       = $MyInvocation.MyCommand;
        "functionparameters" = $PSBoundParameters
    }
 
    $vehicledata = New-TeslaAPICall @APIparameters
 
    return $vehicledata
}

function Get-TeslaGUISettings {
    <#   
  .SYNOPSIS   
  Function to get vehicle GUI settings from the Tesla API
      
  .DESCRIPTION 
  Get the GUI settings state for the vehicle, a vehicle id must be specified

  .NOTES	
      Author: Robin Verhoeven
      Requestor: -
      Created: -
      
      

  .LINK
      https://github.com/Wobs01/Tesla

  .EXAMPLE   
  . Get-TeslaGUISettings -id <id>
  

  #>
   
    [Cmdletbinding()] 
    param([parameter(Mandatory = $true)]
        [string]$id      
    )  
    $requestURI = "https://owner-api.teslamotors.com/api/1/vehicles/$id/data_request/gui_settings"       
    $APIparameters = @{
        "URI"                = $requestURI;
        "method"             = "GET";
        "functionname"       = $MyInvocation.MyCommand;
        "functionparameters" = $PSBoundParameters
    }
 
    $vehicledata = New-TeslaAPICall @APIparameters
 
    return $vehicledata
}

function Get-TeslaVehicleConfig {
    <#   
  .SYNOPSIS   
  Function to get vehicle config from the Tesla API
      
  .DESCRIPTION 
  Get the config for the vehicle, a vehicle id must be specified

  .NOTES	
      Author: Robin Verhoeven
      Requestor: -
      Created: -
      
      

  .LINK
      https://github.com/Wobs01/Tesla

  .EXAMPLE   
  . Get-TeslaVehicleConfig -id <id>
  

  #>
   
    [Cmdletbinding()] 
    param([parameter(Mandatory = $true)]
        [string]$id      
    )  
    $requestURI = "https://owner-api.teslamotors.com/api/1/vehicles/$id/data_request/vehicle_config"       
    $APIparameters = @{
        "URI"                = $requestURI;
        "method"             = "GET";
        "functionname"       = $MyInvocation.MyCommand;
        "functionparameters" = $PSBoundParameters
    }
 
    $vehicledata = New-TeslaAPICall @APIparameters
 
    return $vehicledata
}

function Get-TeslaNearbyChargeSites {
    <#   
  .SYNOPSIS   
  Function to get charging sites from the Tesla API
      
  .DESCRIPTION 
  Get the nearby charging sites for the vehicle, based on the vehicle location. 
  A vehicle id must be specified

  .NOTES	
      Author: Robin Verhoeven
      Requestor: -
      Created: -
      
      

  .LINK
      https://github.com/Wobs01/Tesla

  .EXAMPLE   
  . Get-TeslaNearbyChargeSites -id <id>
  

  #>
   
    [Cmdletbinding()] 
    param([parameter(Mandatory = $true)]
        [string]$id      
    )  
    $requestURI = "https://owner-api.teslamotors.com/api/1/vehicles/$id/nearby_charging_sites"       
    $APIparameters = @{
        "URI"                = $requestURI;
        "method"             = "GET";
        "functionname"       = $MyInvocation.MyCommand;
        "functionparameters" = $PSBoundParameters
    }
 
    $vehicledata = New-TeslaAPICall @APIparameters
 
    return $vehicledata
}

function Start-TeslaSoftwareUpdate {
    <#   
  .SYNOPSIS   
  Function to start a software update if available, sends a post command to the Tesla API
      
  .DESCRIPTION 
  Starts a software update, with the selected offset.

  .NOTES	
      Author: Robin Verhoeven
      Requestor: -
      Created: -
      
      

  .LINK
      https://github.com/Wobs01/Tesla

  .EXAMPLE   
  . Start-TeslaSoftwareUpdate -id <id> -offset <offset in seconds>
  

  #>
   
    [Cmdletbinding()] 
    param([parameter(Mandatory = $true)]
        [string]$id,
        [parameter(Mandatory = $true)]
        [int]$offset     
    )  
    $requestURI = "https://owner-api.teslamotors.com/api/1/vehicles/$id/command/schedule_software_update?offset_sec=$offset"       
    $APIparameters = @{
        "URI"                = $requestURI;
        "method"             = "POST";
        "functionname"       = $MyInvocation.MyCommand;
        "functionparameters" = $PSBoundParameters
    }
 
    $vehicledata = New-TeslaAPICall @APIparameters
 
    return $vehicledata
}

function New-TeslaAlert {
    <#   
  .SYNOPSIS   
  Function to initiate an alarm, sends a post command to the Tesla API
      
  .DESCRIPTION 
  Starts an alarm on the Tesla, Either flashing the lights or honking the horn.

  .NOTES	
      Author: Robin Verhoeven
      Requestor: -
      Created: -
      
      

  .LINK
      https://github.com/Wobs01/Tesla

  .EXAMPLE   
  . New-TeslaAlert -id <id> -Alert FlashLights
  

  #>
   
    [Cmdletbinding()] 
    param([parameter(Mandatory = $true)]
        [string]$id,
        [parameter(Mandatory = $true)]
        [validateset('HonkHorn', 'FlashLights')]$Alert

    )
    switch ($Alert) {
        "HonkHorn" {
            $requestURI = "https://owner-api.teslamotors.com/api/1/vehicles/$id/api/1/vehicles/{id}/command/honk_horn"
        }
        "FlashLights" {
            $requestURI = "https://owner-api.teslamotors.com/api/1/vehicles/$id/api/1/vehicles/{id}/command/flash_lights"
        }
    }
         
    $APIparameters = @{
        "URI"                = $requestURI;
        "method"             = "POST";
        "functionname"       = $MyInvocation.MyCommand;
        "functionparameters" = $PSBoundParameters
    }
 
    $vehicledata = New-TeslaAPICall @APIparameters
 
    return $vehicledata
}

function New-TeslaAPICall {
    #internal function for API calls
    [Cmdletbinding()] 
    param(
        [parameter(Mandatory = $true)]
        [string]$URI,
        [parameter(Mandatory = $true)]
        [validateset('GET', 'POST')]
        $method,
        [parameter(Mandatory = $false)]
        [string]$functionname,
        [parameter(Mandatory = $false)]
        $functionparameters
    )
    $header = @{"Authorization" = "Bearer $($token.access_token)" }
    try {     
        $vehicledata = Invoke-RestMethod -Method $method -Uri $URI -Headers $header -ContentType "application/json" -ErrorAction Stop
    }
    catch {
        $response = Start-TeslaErrorHandling -functionname $functionname -functionparameters $functionparameters
        if ($response -eq $false) { 
            throw ("Unable to execute $functionname, Error message:`n" + $global:Error[0].Exception.message)
        }
        else {
            return $response
        }
       
    }
    return $vehicledata.response 
}

function Start-TeslaErrorHandling {
    #internal function for Error handling
    [Cmdletbinding()] 
    param([parameter(Mandatory = $true)]
        [string]$functionname,
        [parameter(Mandatory = $false)]
        $functionparameters
    )
    switch -Regex ($global:Error[0].Exception.message) {
        "(401)" {
            $validationtoken = Test-TeslaLoginToken
            #recall function after authentication
            if (![string]::IsNullOrEmpty($validationtoken)) {                 
                $returnvalue = . $functionname @functionparameters
                return $returnvalue
            }
        }
        "(408)" {
            Send-TeslaWakeUpCall @functionparameters
            #recall function
            $returnvalue = . $functionname @functionparameters
            return $returnvalue
        }
        default {
            return $false
        }
    }

}

function Test-TeslaLoginToken {
    #internal function for token check
    if ([string]::IsNullOrEmpty($global:token)) {
        $localtoken = New-TeslaConnection -PassThru
    }
    else {
        $localtoken = New-TeslaConnection -refresh_token $global:token.refresh_token -PassThru
    }
    return $localtoken
}

function Send-TeslaWakeUpCall {
    #internal function to connect to tesla or wake vehicle
    [Cmdletbinding()] 
    param([parameter(Mandatory = $true)]
        [string]$id,
        [parameter(Mandatory = $false)]
        [string]$URL = "https://owner-api.teslamotors.com/",
        [parameter(Mandatory = $false)]
        [int]$TimeoutSec = 5 
    )
     
    $header = @{"Authorization" = "Bearer $($token.access_token)" }
   
    try {        
        $requestURI = $URL + "/api/1/vehicles/$id/wake_up"
        Write-Host waking up vehicle $id
        $i = 1
        do {
            $global:vehiclestatus = Invoke-RestMethod -Method Post -Uri $requestURI -Headers $header -ContentType "application/json" -ErrorAction Stop
            Start-Sleep -Milliseconds 500
            $i++
        } while (($i -lt ($TimeoutSec * 2)) -or ($global:vehiclestatus.response.state -eq "online"))
    }
    catch {
        throw ("Unable to wake vehicle, Error message:`n" + $global:Error[0].Exception.message)
    }

}

$exporthash = @{
    "Function" = "New-TeslaConnection",
    "Get-TeslaVehiclelist",
    "Get-TeslaVehicleData",
    "Get-TeslaChargeState",
    "Get-TeslaClimateState",
    "Get-TeslaDriveState",
    "Get-TeslaGUISettings",
    "Get-TeslaVehicleConfig",
    "Get-TeslaNearbyChargeSites",
    "Start-TeslaSoftwareUpdate"
}

Export-ModuleMember @exporthash 