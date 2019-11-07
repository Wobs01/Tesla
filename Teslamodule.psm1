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
        [string]$URL = "https://owner-api.teslamotors.com/" 
        
                
    ) 
    if ([string]::IsNullOrEmpty($credentials.UserName)) {
        try {
            $credentials = Get-Credential -Message "Please provide your Tesla credentials" -ErrorAction Stop
        }
        catch {
            throw ("Unable to get credentials, please try again:`n"+$global:Error[0].ToString())
        }
    }
    
    switch ($PSCmdlet.ParameterSetName) {
        "Refreshtoken" {
            $loginhash = @{
                "grant_type"    = "refresh_token";
                "client_id"     = "81527cff06843c8634fdc09e8ac0abefb46ac849f38fe1e431c2ef2106796384";
                "client_secret" = "c7257eb71a564034f9419ee651c7d0e5f7aa6bfbd18bafb5c5c033b093bb2fa3";
                "refresh_token" = $token.refresh_token
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
        ("Login Failed:`n"+$global:Error[0].ToString())
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
        [string]$id,
        [parameter(Mandatory = $false)]
        [string]$URL = "https://owner-api.teslamotors.com/" 
    )
    
    
    $header = @{"Authorization" = "Bearer $($token.access_token)"}
    

    try {        
        $requestURI = $URL + "api/1/vehicles/$id"
        $vehiclelist = Invoke-RestMethod -Method Get -Uri $requestURI -Headers $header -ContentType "application/json" -ErrorAction Stop
    }
    catch {
        throw ("Unable to get vehicle, Error message:`n"+$global:Error[0].Exception.ToString())
       
    }
    return $vehiclelist.response 
}

Export-ModuleMember -Function *