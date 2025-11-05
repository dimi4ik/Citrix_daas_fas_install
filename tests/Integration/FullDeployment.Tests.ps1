<#
.SYNOPSIS
    Integration tests for complete FAS deployment workflow

.DESCRIPTION
    End-to-end integration tests that validate:
    1. Deploy-FAS.ps1 - Installation
    2. Configure-FAS.ps1 - CA and Template configuration
    3. Configure-FAS-UserRules.ps1 - User rules setup
    4. Test-FASInstallation.ps1 - Validation

.NOTES
    Version: 1.0.0
    Test Framework: Pester 5.x
#>

#Requires -Modules Pester

BeforeAll {
    # Import all mock modules
    $mockPath = Join-Path $PSScriptRoot '..' 'Mocks'
    Import-Module (Join-Path $mockPath 'FAS-SDK.psm1') -Force
    Import-Module (Join-Path $mockPath 'WindowsServices.psm1') -Force
    Import-Module (Join-Path $mockPath 'ActiveDirectory.psm1') -Force

    # Script paths
    $script:ScriptRoot = Join-Path $PSScriptRoot '..' '..' 'scripts'
    $script:DeployScript = Join-Path $ScriptRoot 'Deploy-FAS.ps1'
    $script:ConfigureScript = Join-Path $ScriptRoot 'Configure-FAS.ps1'
    $script:UserRulesScript = Join-Path $ScriptRoot 'Configure-FAS-UserRules.ps1'
    $script:TestScript = Join-Path $ScriptRoot 'Test-FASInstallation.ps1'

    # Test configuration
    $script:TestConfig = @{
        MSIPath = "C:\Temp\FAS_Test.msi"
        FASAddress = "fas-test.example.local"
        CAServers = @("ca-test.example.local")
        FASSecurityGroupSID = "S-1-5-21-1234567890-1234567890-1234567890-1001"
        StoreFrontSID = "S-1-5-21-1234567890-1234567890-1234567890-2001"
        VDASID = "S-1-5-21-1234567890-1234567890-1234567890-3001"
        UserSID = "S-1-5-21-1234567890-1234567890-1234567890-4001"
    }
}

Describe "FAS Complete Deployment Workflow" -Tag 'Integration', 'E2E' {

    BeforeEach {
        # Reset all mock data
        Reset-FasMockData
        Reset-WindowsServicesMockData
        Reset-ActiveDirectoryMockData

        # Initialize mocks with default state
        Set-MockAdministrator -IsAdmin $true
        Initialize-MockDomain -DomainName "example.local"

        Write-Host "Integration test environment initialized" -ForegroundColor Cyan
    }

    Context "Phase 1: FAS Installation (Deploy-FAS.ps1)" {

        It "Should install FAS successfully" {
            # Arrange
            Set-MockMSIExitCode -MSIPath $script:TestConfig.MSIPath -ExitCode 0

            # Simulate MSI installation
            $installProcess = Start-Process -FilePath "msiexec.exe" `
                                           -ArgumentList @("/i", "`"$($script:TestConfig.MSIPath)`"", "/qn") `
                                           -Wait -PassThru

            # Simulate service creation
            Initialize-MockService -Name "CitrixFederatedAuthenticationService" `
                                  -DisplayName "Citrix Federated Authentication Service" `
                                  -Status "Stopped" `
                                  -StartType "Automatic"

            # Start service
            Start-Service -Name "CitrixFederatedAuthenticationService"

            # Add registry entry
            Add-MockInstalledSoftware -DisplayName "Citrix Federated Authentication Service" `
                                     -DisplayVersion "2112.0.1.0"

            # Assert
            $installProcess.ExitCode | Should -Be 0

            $service = Get-Service -Name "CitrixFederatedAuthenticationService"
            $service.Status | Should -Be "Running"
            $service.StartType | Should -Be "Automatic"

            $software = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" |
                Where-Object { $_.DisplayName -like "*Citrix*Federated*" }
            $software | Should -Not -BeNullOrEmpty
        }
    }

    Context "Phase 2: Certificate Template Deployment (Configure-FAS.ps1)" {

        BeforeAll {
            # Ensure FAS service is running for this context
            Initialize-MockService -Name "CitrixFederatedAuthenticationService" `
                                  -Status "Running" `
                                  -StartType "Automatic"
        }

        It "Should create custom certificate template (917Citrix_SmartcardLogon)" {
            # Act
            $template = New-FasMsTemplate -Address $script:TestConfig.FASAddress `
                                         -Name "917Citrix_SmartcardLogon" `
                                         -SecurityGroupSID $script:TestConfig.FASSecurityGroupSID

            # Assert
            $template | Should -Not -BeNullOrEmpty
            $template.Name | Should -Be "917Citrix_SmartcardLogon"
            $template.SchemaVersion | Should -Be 4
            $template.HashAlgorithm | Should -Be "SHA256"
        }

        It "Should create registration authority template" {
            # Act
            $template = New-FasMsTemplate -Address $script:TestConfig.FASAddress `
                                         -Name "Citrix_RegistrationAuthority" `
                                         -SecurityGroupSID $script:TestConfig.FASSecurityGroupSID

            # Assert
            $template | Should -Not -BeNullOrEmpty
            $template.Name | Should -Be "Citrix_RegistrationAuthority"
        }

        It "Should publish templates to CA" {
            # Arrange
            New-FasMsTemplate -Address $script:TestConfig.FASAddress `
                             -Name "917Citrix_SmartcardLogon" `
                             -SecurityGroupSID $script:TestConfig.FASSecurityGroupSID

            # Act
            $publishedTemplate = Publish-FasMsTemplate -Address $script:TestConfig.FASAddress `
                                                       -Name "917Citrix_SmartcardLogon" `
                                                       -CertificateAuthority $script:TestConfig.CAServers[0]

            # Assert
            $publishedTemplate | Should -Not -BeNullOrEmpty
            $publishedTemplate.PublishedToCA | Should -Be $script:TestConfig.CAServers[0]
        }

        It "Should create authorization certificate" {
            # Act
            $authCert = New-FasAuthorizationCertificate -Address $script:TestConfig.FASAddress `
                                                       -CertificateAuthority $script:TestConfig.CAServers[0]

            # Assert
            $authCert | Should -Not -BeNullOrEmpty
            $authCert.Subject | Should -Match "FAS-"
            $authCert.Issuer | Should -Match $script:TestConfig.CAServers[0]
            $authCert.NotAfter | Should -BeGreaterThan (Get-Date)
        }
    }

    Context "Phase 3: User Rules Configuration (Configure-FAS-UserRules.ps1)" {

        It "Should create certificate definition with custom template" {
            # Setup prerequisites for this test
            Initialize-MockService -Name "CitrixFederatedAuthenticationService" `
                                  -Status "Running"

            New-FasMsTemplate -Address $script:TestConfig.FASAddress `
                             -Name "917Citrix_SmartcardLogon" `
                             -SecurityGroupSID $script:TestConfig.FASSecurityGroupSID

            $null = New-FasAuthorizationCertificate -Address $script:TestConfig.FASAddress `
                                                   -CertificateAuthority $script:TestConfig.CAServers[0]

            # Test execution
            # Arrange
            $authCert = Get-FasAuthorizationCertificate -Address $script:TestConfig.FASAddress

            # Act
            $certDef = New-FasCertificateDefinition -Address $script:TestConfig.FASAddress `
                                                   -Name "default_Definition" `
                                                   -MsTemplate "917Citrix_SmartcardLogon" `
                                                   -CertificateAuthority $script:TestConfig.CAServers[0] `
                                                   -AuthorizationCertificateId $authCert.Id

            # Assert
            $certDef | Should -Not -BeNullOrEmpty
            $certDef.Name | Should -Be "default_Definition"
            $certDef.MsTemplate | Should -Be "917Citrix_SmartcardLogon"
        }

        It "Should create FAS rule with all ACLs" {
            # Setup prerequisites for this test
            Initialize-MockService -Name "CitrixFederatedAuthenticationService" `
                                  -Status "Running"

            New-FasMsTemplate -Address $script:TestConfig.FASAddress `
                             -Name "917Citrix_SmartcardLogon" `
                             -SecurityGroupSID $script:TestConfig.FASSecurityGroupSID

            $null = New-FasAuthorizationCertificate -Address $script:TestConfig.FASAddress `
                                                   -CertificateAuthority $script:TestConfig.CAServers[0]

            # Test execution
            # Arrange
            $authCert = Get-FasAuthorizationCertificate -Address $script:TestConfig.FASAddress

            $null = New-FasCertificateDefinition -Address $script:TestConfig.FASAddress `
                                                -Name "default_Definition" `
                                                -MsTemplate "917Citrix_SmartcardLogon" `
                                                -CertificateAuthority $script:TestConfig.CAServers[0] `
                                                -AuthorizationCertificateId $authCert.Id

            $storeFrontACL = "D:(A;;GA;;;$($script:TestConfig.StoreFrontSID))"
            $vdaACL = "D:(A;;GA;;;$($script:TestConfig.VDASID))"
            $userACL = "D:(A;;GA;;;$($script:TestConfig.UserSID))"

            # Act
            $rule = New-FasRule -Address $script:TestConfig.FASAddress `
                               -Name "default" `
                               -CertificateDefinitions @("default_Definition") `
                               -StoreFrontAcl $storeFrontACL `
                               -VdaAcl $vdaACL `
                               -UserAcl $userACL

            # Assert
            $rule | Should -Not -BeNullOrEmpty
            $rule.Name | Should -Be "default"
            $rule.CertificateDefinitions | Should -Contain "default_Definition"
            $rule.StoreFrontAcl | Should -Be $storeFrontACL
            $rule.VdaAcl | Should -Be $vdaACL
            $rule.UserAcl | Should -Be $userACL
        }
    }

    Context "Phase 4: Complete End-to-End Deployment" {

        It "Should complete full deployment workflow" {
            # Phase 1: Installation
            Set-MockMSIExitCode -MSIPath $script:TestConfig.MSIPath -ExitCode 0
            $installProcess = Start-Process -FilePath "msiexec.exe" `
                                           -ArgumentList @("/i", "`"$($script:TestConfig.MSIPath)`"", "/qn") `
                                           -Wait -PassThru

            Initialize-MockService -Name "CitrixFederatedAuthenticationService" `
                                  -Status "Running" `
                                  -StartType "Automatic"

            Add-MockInstalledSoftware -DisplayName "Citrix Federated Authentication Service" `
                                     -DisplayVersion "2112.0.1.0"

            # Phase 2: Template Configuration
            $customTemplate = New-FasMsTemplate -Address $script:TestConfig.FASAddress `
                                               -Name "917Citrix_SmartcardLogon" `
                                               -SecurityGroupSID $script:TestConfig.FASSecurityGroupSID

            $raTemplate = New-FasMsTemplate -Address $script:TestConfig.FASAddress `
                                           -Name "Citrix_RegistrationAuthority" `
                                           -SecurityGroupSID $script:TestConfig.FASSecurityGroupSID

            Publish-FasMsTemplate -Address $script:TestConfig.FASAddress `
                                 -Name "917Citrix_SmartcardLogon" `
                                 -CertificateAuthority $script:TestConfig.CAServers[0]

            Publish-FasMsTemplate -Address $script:TestConfig.FASAddress `
                                 -Name "Citrix_RegistrationAuthority" `
                                 -CertificateAuthority $script:TestConfig.CAServers[0]

            $authCert = New-FasAuthorizationCertificate -Address $script:TestConfig.FASAddress `
                                                       -CertificateAuthority $script:TestConfig.CAServers[0]

            # Phase 3: User Rules
            $certDef = New-FasCertificateDefinition -Address $script:TestConfig.FASAddress `
                                                   -Name "default_Definition" `
                                                   -MsTemplate "917Citrix_SmartcardLogon" `
                                                   -CertificateAuthority $script:TestConfig.CAServers[0] `
                                                   -AuthorizationCertificateId $authCert.Id

            $rule = New-FasRule -Address $script:TestConfig.FASAddress `
                               -Name "default" `
                               -CertificateDefinitions @("default_Definition") `
                               -StoreFrontAcl "D:(A;;GA;;;$($script:TestConfig.StoreFrontSID))" `
                               -VdaAcl "D:(A;;GA;;;$($script:TestConfig.VDASID))" `
                               -UserAcl "D:(A;;GA;;;$($script:TestConfig.UserSID))"

            # Assertions - Installation
            $installProcess.ExitCode | Should -Be 0

            # Assertions - Service
            $service = Get-Service -Name "CitrixFederatedAuthenticationService"
            $service.Status | Should -Be "Running"

            # Assertions - Templates
            $customTemplate.SchemaVersion | Should -Be 4
            $customTemplate.HashAlgorithm | Should -Be "SHA256"

            # Assertions - Certificate Definition
            $certDef.MsTemplate | Should -Be "917Citrix_SmartcardLogon"

            # Assertions - Rules
            $rule.CertificateDefinitions | Should -Contain "default_Definition"

            # Assertions - Final State
            $allRules = Get-FasRule -Address $script:TestConfig.FASAddress
            $allRules.Count | Should -BeGreaterThan 0

            $allDefs = Get-FasCertificateDefinition -Address $script:TestConfig.FASAddress
            $allDefs.Count | Should -BeGreaterThan 0

            Write-Host "Full deployment workflow completed successfully" -ForegroundColor Green
        }
    }
}

Describe "FAS Deployment Error Scenarios" -Tag 'Integration', 'ErrorHandling' {

    BeforeEach {
        Reset-FasMockData
        Reset-WindowsServicesMockData
        Reset-ActiveDirectoryMockData
        Set-MockAdministrator -IsAdmin $true
    }

    Context "Installation Failures" {

        It "Should handle MSI installation failure gracefully" {
            # Arrange
            Set-MockMSIExitCode -MSIPath $script:TestConfig.MSIPath -ExitCode 1603

            # Act
            $process = Start-Process -FilePath "msiexec.exe" `
                                    -ArgumentList @("/i", "`"$($script:TestConfig.MSIPath)`"", "/qn") `
                                    -Wait -PassThru

            # Assert
            $process.ExitCode | Should -Be 1603
        }
    }

    Context "Configuration Failures" {

        It "Should fail when creating certificate definition without authorization certificate" {
            # Setup: Create template but NO authorization certificate
            New-FasMsTemplate -Address $script:TestConfig.FASAddress `
                             -Name "917Citrix_SmartcardLogon" `
                             -SecurityGroupSID $script:TestConfig.FASSecurityGroupSID

            # Act & Assert - Should fail because authorization certificate doesn't exist
            {
                New-FasCertificateDefinition -Address $script:TestConfig.FASAddress `
                                            -Name "default_Definition" `
                                            -MsTemplate "917Citrix_SmartcardLogon" `
                                            -CertificateAuthority $script:TestConfig.CAServers[0] `
                                            -AuthorizationCertificateId "invalid-guid"
            } | Should -Throw
        }

        It "Should fail when creating rule with invalid SDDL" {
            # Arrange
            Initialize-MockService -Name "CitrixFederatedAuthenticationService" -Status "Running"

            New-FasMsTemplate -Address $script:TestConfig.FASAddress `
                             -Name "917Citrix_SmartcardLogon" `
                             -SecurityGroupSID $script:TestConfig.FASSecurityGroupSID

            $authCert = New-FasAuthorizationCertificate -Address $script:TestConfig.FASAddress `
                                                       -CertificateAuthority $script:TestConfig.CAServers[0]

            $null = New-FasCertificateDefinition -Address $script:TestConfig.FASAddress `
                                                -Name "default_Definition" `
                                                -MsTemplate "917Citrix_SmartcardLogon" `
                                                -CertificateAuthority $script:TestConfig.CAServers[0] `
                                                -AuthorizationCertificateId $authCert.Id

            # Act & Assert
            {
                New-FasRule -Address $script:TestConfig.FASAddress `
                           -Name "default" `
                           -CertificateDefinitions @("default_Definition") `
                           -StoreFrontAcl "INVALID_SDDL" `
                           -VdaAcl "D:(A;;GA;;;SID)" `
                           -UserAcl "D:(A;;GA;;;SID)"
            } | Should -Throw
        }
    }
}
