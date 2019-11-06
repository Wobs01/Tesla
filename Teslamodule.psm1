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
    param([parameter(Mandatory = $false,ParameterSetName='NewToken')]
        [PSCredential]$credentials,
        [parameter(Mandatory = $false,ParameterSetName='Refreshtoken')]
        [string]$refresh_token,
        [parameter(Mandatory = $false)]
        [string]$URL = "https://owner-api.teslamotors.com/" 
        
                
    ) 
    
    $loginhash = @{
        "grant_type"= "password";
        "client_id"= "81527cff06843c8634fdc09e8ac0abefb46ac849f38fe1e431c2ef2106796384";
        "client_secret"= "c7257eb71a564034f9419ee651c7d0e5f7aa6bfbd18bafb5c5c033b093bb2fa3";
        "email"= $credentials.UserName;
        "password"= $credentials.GetNetworkCredential().password;
    }
    

    try {
        $loginJSON = $loginhash | ConvertTo-Json
        $requestURI = $URL+"/oauth/token"
        $global:token = Invoke-RestMethod -Method Post -Uri $requestURI -Body $loginJSON -ContentType "application/json"
    }
    catch {
        throw $Error[0]
    }    
    
}

function Get-TeslaVehiclelist {


}

Export-ModuleMember -Function *