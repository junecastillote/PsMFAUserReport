
<#PSScriptInfo

.VERSION 0.1

.GUID 7552fb98-672a-4122-b5a6-211a996d46a1

.AUTHOR June Castillote

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI https://github.com/junecastillote/PsMFAUserReport/blob/main/LICENSE

.PROJECTURI https://github.com/junecastillote/PsMFAUserReport

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<#
.SYNOPSIS
Retrieves Multi-Factor Authentication (MFA) registration details of Microsoft 365 users using Microsoft Graph.

.DESCRIPTION
This script uses Microsoft Graph to retrieve the MFA registration status of either a single user (specified by UPN)
or all users in the tenant. The output includes display name, UPN, admin status, MFA capability, registration status,
default MFA method, and a list of registered methods. Optionally, results can be exported to a CSV file.

.PARAMETER UserPrincipalName
Specifies the user principal name (UPN) of a single user whose MFA registration details should be retrieved.

.PARAMETER AllUsers
Switch to retrieve MFA registration details for all users in the tenant.
This parameter is mutually exclusive with -UserPrincipalName.

.PARAMETER OutputCsv
Specifies the path to a CSV file to which the results should be exported. If not provided, the results will be displayed in the console.

.EXAMPLE
.\Get-UserMFARegState.ps1 -UserPrincipalName jane.doe@contoso.com
Retrieves the MFA registration status for a single user.

.EXAMPLE
.\Get-UserMFARegState.ps1 -AllUsers
Retrieves the MFA registration status for all users in the tenant.

.EXAMPLE
.\Get-UserMFARegState.ps1 -AllUsers -OutputCsv "C:\Reports\MFA_Report.csv"
Retrieves the MFA registration status for all users and saves the result to a CSV file.

.NOTES
Requires Microsoft Graph PowerShell SDK and appropriate permissions:
- Reports.Read.All
- User.Read.All

Connect using:
Connect-MgGraph -Scopes "Reports.Read.All", "User.Read.All"

The script uses the beta endpoint of Microsoft Graph API.
#>


[CmdletBinding(DefaultParameterSetName = 'UserPrincipalName')]
param (
    [Parameter(Mandatory, ParameterSetName = 'UserPrincipalName')]
    [string]
    $UserPrincipalName,

    [Parameter(Mandatory, ParameterSetName = 'AllUsers')]
    [switch]
    $AllUsers,

    [Parameter()]
    [string]
    $OutputCsv
)

## Function to split strings.
## Example: "seriesMaster" to "Series Master"
function Format-String ($str) {
    # Convert the first character to uppercase
    $str = $str.Substring(0, 1).ToUpper() + $str.Substring(1)

    # Insert a space before each uppercase character
    $str = [regex]::Replace($str, '([A-Z])', ' ${1}')

    # Remove leading space
    $str = $str.TrimStart()

    return $str
}

# Initialize empty array
$mfa_user_coll = @()

# If -AllUsers is used, set URL to get all users without filter
if ($PSCmdlet.ParameterSetName -eq 'AllUsers') {
    $uri = 'https://graph.microsoft.com/beta/reports/authenticationMethods/userRegistrationDetails'
    "Getting all user MFA registration details..." | Out-Default

}

# If -UserPrincipalName is used, set URL to get specific user only
if ($PSCmdlet.ParameterSetName -eq 'UserPrincipalName') {
    try {
        $user = Get-MgUser -UserId $UserPrincipalName -ErrorAction Stop
        $uri = "https://graph.microsoft.com/beta/reports/authenticationMethods/userRegistrationDetails?`$filter=userPrincipalName eq '$UserPrincipalName'"
        "Getting user MFA registration details for $($user.UserPrincipalName)..." | Out-Default
    }
    catch {
        $_.Exception.Message | Out-Default
        return $null
    }
}

# Retrieve userRegistrationDetails until '@odata.nextLink' is empty.
do {
    $response = Invoke-MgGraphRequest -Uri $uri -OutputType PSObject
    $mfa_user_coll += $response.value
    $uri = $response.'@odata.nextLink'
} while ($uri)

if (-not $mfa_user_coll) {
    return $null
}

# Get result count.
$total_reg = $mfa_user_coll.Count

$mfa_report = @()

# Process each item in userRegistrationDetails
for ($i = 0 ; $i -lt $total_reg ; $i++ ) {
    $percentComplete = [math]::Round(($i / $total_reg) * 100)

    Write-Progress -Activity "Processing MFA Registrations" `
        -Status "Processing $i of $total_reg" `
        -PercentComplete $percentComplete

    $mfa_report += [PSCustomObject]@{
        DisplayName          = $mfa_user_coll[$i].UserDisplayName
        UserPrincipalName    = $mfa_user_coll[$i].UserPrincipalName
        Administator         = $mfa_user_coll[$i].IsAdmin
        MFACapable           = $mfa_user_coll[$i].IsMfaCapable
        MFARegistered        = $mfa_user_coll[$i].isMfaRegistered
        MFADefaultMethod     = Format-String $mfa_user_coll[$i].defaultMfaMethod
        MFAMethodsRegistered = $(
            ($mfa_user_coll[$i].MethodsRegistered | ForEach-Object {
                Format-String $_
            }) -join ", "
        )
    }
}

if ($mfa_report) {
    if ($OutputCsv) {
        $mfa_report | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8 -Append
        "Output saved to @ $($OutputCsv)." | Out-Default
    }
    else {
        $mfa_report
    }
}