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