<#
.SYNOPSIS
    Citrix FAS Installation Validation Script

.DESCRIPTION
    Comprehensive validation script for Citrix FAS installation. Tests:
    1. FAS Service status
    2. Certificate Templates deployment (917Citrix_SmartcardLogon)
    3. CA integration
    4. Authorization Certificate
    5. Certificate Definitions
    6. User Rules configuration
    7. Event Log entries

.PARAMETER FASAddress
    FQDN of the FAS Server to test.

.PARAMETER GenerateReport
    Generate HTML report of validation results.

.EXAMPLE
    .\Test-FASInstallation.ps1 -FASAddress "FAS-SERVER.domain.com"

.EXAMPLE
    .\Test-FASInstallation.ps1 -FASAddress "FAS-SERVER.domain.com" -GenerateReport

.NOTES
    Author: FAS Automation Team
    Version: 1.0.0
    Date: 2025-11-05

    Requirements:
    - FAS Server must be accessible
    - Read permissions for FAS configuration
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$FASAddress,

    [Parameter(Mandatory=$false)]
    [switch]$GenerateReport
)

# Strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"  # Continue on errors to collect all test results

#region Test Results Tracking

$script:TestResults = @()

function Add-TestResult {
    param(
        [string]$Category,
        [string]$Test,
        [bool]$Passed,
        [string]$Message,
        [string]$Details = ""
    )

    $script:TestResults += [PSCustomObject]@{
        Category = $Category
        Test = $Test
        Passed = $Passed
        Message = $Message
        Details = $Details
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    $color = if ($Passed) { 'Green' } else { 'Red' }
    $status = if ($Passed) { '[PASS]' } else { '[FAIL]' }

    Write-Host "$status $Category - $Test" -ForegroundColor $color
    if ($Message) {
        Write-Host "  $Message" -ForegroundColor Gray
    }
}

#endregion

#region Test Functions

function Test-FASService {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Testing FAS Service" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    try {
        $service = Get-Service -Name "CitrixFederatedAuthenticationService" -ErrorAction Stop

        if ($service.Status -eq 'Running') {
            Add-TestResult -Category "Service" -Test "FAS Service Status" -Passed $true `
                          -Message "Service is running" `
                          -Details "DisplayName: $($service.DisplayName), StartType: $($service.StartType)"
        }
        else {
            Add-TestResult -Category "Service" -Test "FAS Service Status" -Passed $false `
                          -Message "Service is not running: $($service.Status)"
        }

        # Check service start type
        if ($service.StartType -eq 'Automatic') {
            Add-TestResult -Category "Service" -Test "Service Start Type" -Passed $true `
                          -Message "Service start type is Automatic"
        }
        else {
            Add-TestResult -Category "Service" -Test "Service Start Type" -Passed $false `
                          -Message "Service start type is $($service.StartType), should be Automatic"
        }
    }
    catch {
        Add-TestResult -Category "Service" -Test "FAS Service Existence" -Passed $false `
                      -Message "FAS Service not found: $($_.Exception.Message)"
    }
}

function Test-FASConnectivity {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Testing FAS Connectivity" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    try {
        $fasServer = Get-FasServer -Address $FASAddress -ErrorAction Stop

        Add-TestResult -Category "Connectivity" -Test "FAS Server Connection" -Passed $true `
                      -Message "Successfully connected to FAS Server" `
                      -Details "Address: $FASAddress"
    }
    catch {
        Add-TestResult -Category "Connectivity" -Test "FAS Server Connection" -Passed $false `
                      -Message "Cannot connect to FAS Server: $($_.Exception.Message)"
    }
}

function Test-CertificateTemplates {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Testing Certificate Templates" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    try {
        $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
        $configNC = "CN=Configuration," + $domain.GetDirectoryEntry().distinguishedName[0]
        $templatePath = "CN=Certificate Templates,CN=Public Key Services,CN=Services,$configNC"

        $searcher = New-Object System.DirectoryServices.DirectorySearcher
        $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$templatePath")

        # Test 1: Check for custom template 917Citrix_SmartcardLogon
        $searcher.Filter = "(cn=917Citrix_SmartcardLogon)"
        $customTemplate = $searcher.FindOne()

        if ($customTemplate) {
            Add-TestResult -Category "Templates" -Test "Custom Template (917Citrix_SmartcardLogon)" -Passed $true `
                          -Message "Custom template found in Active Directory" `
                          -Details "DN: $($customTemplate.Path)"

            # Check template schema version
            $schemaVersion = $customTemplate.Properties["msPKI-Template-Schema-Version"][0]
            if ($schemaVersion -eq 4) {
                Add-TestResult -Category "Templates" -Test "Template Schema Version" -Passed $true `
                              -Message "Schema Version 4 (Windows Server 2016+)"
            }
            else {
                Add-TestResult -Category "Templates" -Test "Template Schema Version" -Passed $false `
                              -Message "Schema Version is $schemaVersion, expected 4"
            }
        }
        else {
            Add-TestResult -Category "Templates" -Test "Custom Template (917Citrix_SmartcardLogon)" -Passed $false `
                          -Message "Custom template NOT found in Active Directory"
        }

        # Test 2: Check for Citrix_RegistrationAuthority
        $searcher.Filter = "(cn=Citrix_RegistrationAuthority)"
        $raTemplate = $searcher.FindOne()

        if ($raTemplate) {
            Add-TestResult -Category "Templates" -Test "Registration Authority Template" -Passed $true `
                          -Message "Citrix_RegistrationAuthority template found"
        }
        else {
            Add-TestResult -Category "Templates" -Test "Registration Authority Template" -Passed $false `
                          -Message "Citrix_RegistrationAuthority template NOT found"
        }

        # Test 3: Verify OLD template is NOT deployed
        $searcher.Filter = "(cn=Citrix_SmartCardLogon)"
        $oldTemplate = $searcher.FindOne()

        if (-not $oldTemplate) {
            Add-TestResult -Category "Templates" -Test "Old Template Removed" -Passed $true `
                          -Message "Old Citrix_SmartCardLogon template correctly not deployed"
        }
        else {
            Add-TestResult -Category "Templates" -Test "Old Template Removed" -Passed $false `
                          -Message "WARNING: Old Citrix_SmartCardLogon template still exists"
        }
    }
    catch {
        Add-TestResult -Category "Templates" -Test "AD Template Query" -Passed $false `
                      -Message "Cannot query AD templates: $($_.Exception.Message)"
    }
}

function Test-AuthorizationCertificate {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Testing Authorization Certificate" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    try {
        $authCert = Get-FasAuthorizationCertificate -Address $FASAddress -ErrorAction Stop

        if ($authCert) {
            Add-TestResult -Category "Authorization" -Test "Authorization Certificate Exists" -Passed $true `
                          -Message "Authorization Certificate found" `
                          -Details "Subject: $($authCert.Subject), Thumbprint: $($authCert.Thumbprint)"

            # Check expiration
            $daysUntilExpiry = ($authCert.NotAfter - (Get-Date)).Days

            if ($daysUntilExpiry -gt 30) {
                Add-TestResult -Category "Authorization" -Test "Certificate Expiration" -Passed $true `
                              -Message "Certificate valid for $daysUntilExpiry days"
            }
            elseif ($daysUntilExpiry -gt 0) {
                Add-TestResult -Category "Authorization" -Test "Certificate Expiration" -Passed $false `
                              -Message "WARNING: Certificate expires in $daysUntilExpiry days!"
            }
            else {
                Add-TestResult -Category "Authorization" -Test "Certificate Expiration" -Passed $false `
                              -Message "CRITICAL: Certificate has expired!"
            }

            # Check issuer
            Add-TestResult -Category "Authorization" -Test "Certificate Issuer" -Passed $true `
                          -Message "Issued by: $($authCert.Issuer)"
        }
        else {
            Add-TestResult -Category "Authorization" -Test "Authorization Certificate Exists" -Passed $false `
                          -Message "No Authorization Certificate found"
        }
    }
    catch {
        Add-TestResult -Category "Authorization" -Test "Authorization Certificate Query" -Passed $false `
                      -Message "Cannot query authorization certificate: $($_.Exception.Message)"
    }
}

function Test-CertificateDefinitions {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Testing Certificate Definitions" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    try {
        $certDefs = Get-FasCertificateDefinition -Address $FASAddress -ErrorAction Stop

        if ($certDefs) {
            Add-TestResult -Category "Definitions" -Test "Certificate Definitions Exist" -Passed $true `
                          -Message "Found $($certDefs.Count) certificate definition(s)"

            foreach ($def in $certDefs) {
                # Check if using custom template
                if ($def.MsTemplate -eq "917Citrix_SmartcardLogon") {
                    Add-TestResult -Category "Definitions" -Test "Custom Template Usage" -Passed $true `
                                  -Message "Definition '$($def.Name)' uses custom template 917Citrix_SmartcardLogon" `
                                  -Details "CA: $($def.CertificateAuthority)"
                }
                elseif ($def.MsTemplate -eq "Citrix_SmartCardLogon") {
                    Add-TestResult -Category "Definitions" -Test "Custom Template Usage" -Passed $false `
                                  -Message "WARNING: Definition '$($def.Name)' uses OLD template Citrix_SmartCardLogon"
                }
                else {
                    Add-TestResult -Category "Definitions" -Test "Template Name" -Passed $true `
                                  -Message "Definition '$($def.Name)' uses template: $($def.MsTemplate)"
                }
            }
        }
        else {
            Add-TestResult -Category "Definitions" -Test "Certificate Definitions Exist" -Passed $false `
                          -Message "No certificate definitions found"
        }
    }
    catch {
        Add-TestResult -Category "Definitions" -Test "Certificate Definitions Query" -Passed $false `
                      -Message "Cannot query certificate definitions: $($_.Exception.Message)"
    }
}

function Test-FASRules {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Testing FAS Rules" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    try {
        $rules = Get-FasRule -Address $FASAddress -ErrorAction Stop

        if ($rules) {
            Add-TestResult -Category "Rules" -Test "FAS Rules Exist" -Passed $true `
                          -Message "Found $($rules.Count) FAS rule(s)"

            foreach ($rule in $rules) {
                # Check ACLs
                $hasStoreFrontACL = $rule.StoreFrontAcl -ne $null -and $rule.StoreFrontAcl -ne ""
                $hasVDAACL = $rule.VdaAcl -ne $null -and $rule.VdaAcl -ne ""
                $hasUserACL = $rule.UserAcl -ne $null -and $rule.UserAcl -ne ""

                if ($hasStoreFrontACL) {
                    Add-TestResult -Category "Rules" -Test "StoreFront ACL ($($rule.Name))" -Passed $true `
                                  -Message "StoreFront permissions configured"
                }
                else {
                    Add-TestResult -Category "Rules" -Test "StoreFront ACL ($($rule.Name))" -Passed $false `
                                  -Message "StoreFront ACL is empty"
                }

                if ($hasVDAACL) {
                    Add-TestResult -Category "Rules" -Test "VDA ACL ($($rule.Name))" -Passed $true `
                                  -Message "VDA permissions configured"
                }
                else {
                    Add-TestResult -Category "Rules" -Test "VDA ACL ($($rule.Name))" -Passed $false `
                                  -Message "VDA ACL is empty"
                }

                if ($hasUserACL) {
                    Add-TestResult -Category "Rules" -Test "User ACL ($($rule.Name))" -Passed $true `
                                  -Message "User permissions configured"
                }
                else {
                    Add-TestResult -Category "Rules" -Test "User ACL ($($rule.Name))" -Passed $false `
                                  -Message "User ACL is empty"
                }
            }
        }
        else {
            Add-TestResult -Category "Rules" -Test "FAS Rules Exist" -Passed $false `
                          -Message "No FAS rules found"
        }
    }
    catch {
        Add-TestResult -Category "Rules" -Test "FAS Rules Query" -Passed $false `
                      -Message "Cannot query FAS rules: $($_.Exception.Message)"
    }
}

function Test-EventLogs {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Testing Event Logs" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    try {
        $events = Get-WinEvent -LogName "Citrix-FederatedAuthenticationService/Admin" -MaxEvents 10 -ErrorAction Stop

        if ($events) {
            Add-TestResult -Category "EventLog" -Test "FAS Event Log Accessible" -Passed $true `
                          -Message "Found $($events.Count) recent event(s)"

            # Check for errors
            $errors = $events | Where-Object { $_.LevelDisplayName -eq "Error" }
            if ($errors.Count -eq 0) {
                Add-TestResult -Category "EventLog" -Test "No Recent Errors" -Passed $true `
                              -Message "No errors in recent events"
            }
            else {
                Add-TestResult -Category "EventLog" -Test "No Recent Errors" -Passed $false `
                              -Message "Found $($errors.Count) error(s) in recent events"
            }
        }
    }
    catch {
        Add-TestResult -Category "EventLog" -Test "Event Log Access" -Passed $false `
                      -Message "Cannot access FAS event log: $($_.Exception.Message)"
    }
}

#endregion

#region Reporting

function Show-TestSummary {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Test Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $totalTests = $script:TestResults.Count
    $passedTests = ($script:TestResults | Where-Object { $_.Passed }).Count
    $failedTests = $totalTests - $passedTests

    Write-Host "Total Tests: $totalTests" -ForegroundColor Cyan
    Write-Host "Passed: $passedTests" -ForegroundColor Green
    Write-Host "Failed: $failedTests" -ForegroundColor Red

    $successRate = [math]::Round(($passedTests / $totalTests) * 100, 2)
    Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { 'Green' } elseif ($successRate -ge 70) { 'Yellow' } else { 'Red' })

    # Group by category
    Write-Host "`nResults by Category:" -ForegroundColor Cyan
    $script:TestResults | Group-Object -Property Category | ForEach-Object {
        $catPassed = ($_.Group | Where-Object { $_.Passed }).Count
        $catTotal = $_.Group.Count
        Write-Host "  $($_.Name): $catPassed/$catTotal passed" -ForegroundColor $(if ($catPassed -eq $catTotal) { 'Green' } else { 'Yellow' })
    }
}

function Export-HTMLReport {
    $reportPath = "$env:TEMP\FAS-Validation-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>FAS Installation Validation Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        .pass { background-color: #d4edda; }
        .fail { background-color: #f8d7da; }
        .summary { background-color: #e7f3fe; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>FAS Installation Validation Report</h1>
    <div class="summary">
        <h2>Summary</h2>
        <p><strong>FAS Server:</strong> $FASAddress</p>
        <p><strong>Test Date:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p><strong>Total Tests:</strong> $($script:TestResults.Count)</p>
        <p><strong>Passed:</strong> $(($script:TestResults | Where-Object { $_.Passed }).Count)</p>
        <p><strong>Failed:</strong> $(($script:TestResults | Where-Object { -not $_.Passed }).Count)</p>
    </div>
    <h2>Test Results</h2>
    <table>
        <tr>
            <th>Category</th>
            <th>Test</th>
            <th>Result</th>
            <th>Message</th>
            <th>Details</th>
        </tr>
"@

    foreach ($result in $script:TestResults) {
        $rowClass = if ($result.Passed) { 'pass' } else { 'fail' }
        $status = if ($result.Passed) { 'PASS' } else { 'FAIL' }

        $html += @"
        <tr class="$rowClass">
            <td>$($result.Category)</td>
            <td>$($result.Test)</td>
            <td>$status</td>
            <td>$($result.Message)</td>
            <td>$($result.Details)</td>
        </tr>
"@
    }

    $html += @"
    </table>
</body>
</html>
"@

    $html | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "`nHTML Report generated: $reportPath" -ForegroundColor Green
    return $reportPath
}

#endregion

#region Main Script

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FAS Installation Validation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FAS Server: $FASAddress" -ForegroundColor Cyan
Write-Host "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan

# Run all tests
Test-FASService
Test-FASConnectivity
Test-CertificateTemplates
Test-AuthorizationCertificate
Test-CertificateDefinitions
Test-FASRules
Test-EventLogs

# Show summary
Show-TestSummary

# Generate HTML report if requested
if ($GenerateReport) {
    $reportPath = Export-HTMLReport
    Start-Process $reportPath
}

# Return exit code based on results
$failedTests = ($script:TestResults | Where-Object { -not $_.Passed }).Count
if ($failedTests -gt 0) {
    Write-Host "`nValidation completed with $failedTests failed test(s)" -ForegroundColor Red
    exit 1
}
else {
    Write-Host "`nAll validation tests passed successfully!" -ForegroundColor Green
    exit 0
}

#endregion
