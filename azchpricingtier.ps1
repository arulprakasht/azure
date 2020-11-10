# PowerShell code to change Az SQL DB Pricing tier
########################################################
# Parameters
########################################################
[CmdletBinding()]
param(
    [Parameter(Mandatory=$True,Position=0)]
    [ValidateLength(1,100)]
    [string]$ResourceGroupName,
 
    [Parameter(Mandatory=$True,Position=1)]
    [ValidateLength(1,100)]
    [string]$ServerName,
 
    [Parameter(Mandatory=$True,Position=2)]
    [ValidateLength(1,100)]
    [string]$DatabaseName,
 
    [Parameter(Mandatory=$False,Position=3)]
    [ValidateLength(1,100)]
    [string]$Edition,
     
    [Parameter(Mandatory=$False,Position=4)]
    [ValidateLength(1,100)]
    [string]$PricingTier
)
 
# Keep track of time
$StartDate=(GET-DATE)
 
 
 
########################################################
# Log in to Azure with AZ (standard code)
########################################################
Write-Verbose -Message 'Connecting to Azure'
  
# Name of the Azure Run As connection
$ConnectionName = 'AzureRunAsConnection'
try
{
    # Get the connection properties
    $ServicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName      
   
    'Log in to Azure...'
    $null = Connect-AzAccount `
        -ServicePrincipal `
        -TenantId $ServicePrincipalConnection.TenantId `
        -ApplicationId $ServicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint 
}
catch 
{
    if (!$ServicePrincipalConnection)
    {
        # You forgot to turn on 'Create Azure Run As account' 
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    }
    else
    {
        # Something else went wrong
        Write-Error -Message $_.Exception.Message
        throw $_.Exception
    }
}
########################################################
  
 
 
########################################################
# Getting the database for testing and logging purposes
########################################################
$MyAzureSqlDatabase = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName
if (!$MyAzureSqlDatabase)
{
    Write-Error "$($ServerName)\$($DatabaseName) not found in $($ResourceGroupName)"
    return
}
else
{
    Write-Output "Current pricing tier of $($ServerName)\$($DatabaseName): $($MyAzureSqlDatabase.Edition) - $($MyAzureSqlDatabase.CurrentServiceObjectiveName)"
}
 
 
 
########################################################
# Set Pricing Tier Database
########################################################
# Check for incompatible actions
if ($MyAzureSqlDatabase.Edition -eq $Edition -And $MyAzureSqlDatabase.CurrentServiceObjectiveName -eq $PricingTier)
{
    Write-Error "Cannot change pricing tier of $($ServerName)\$($DatabaseName) because the new pricing tier is equal to current pricing tier"
    return
}
else
{
    Write-Output "Changing pricing tier to $($Edition) - $($PricingTier)"
    $null = Set-AzSqlDatabase -DatabaseName $DatabaseName -ServerName $ServerName -ResourceGroupName $ResourceGroupName -Edition $Edition -RequestedServiceObjectiveName $PricingTier
}
 
 
 
########################################################
# Show when finished
########################################################
$Duration = NEW-TIMESPAN –Start $StartDate –End (GET-DATE)
Write-Output "Done in $([int]$Duration.TotalMinutes) minute(s) and $([int]$Duration.Seconds) second(s)"
