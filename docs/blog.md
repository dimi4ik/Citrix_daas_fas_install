As SAML-based identity providers become more popular in the enterprise space, many companies are looking to integrating the tools into their overall Citrix solution. At the same time, companies are quickly adopting a DevOps mindset and looking to automate common installation, deployment, and configuration tasks.

After realizing the potential for automating Citrix solutions we figured: why not write a blog on this?

For many companies, implementing an automated solution alone could be a hassle, but luckily Citrix Consulting Services is here to help! If you need to brush up on what Citrix Federated Authentication Service (FAS) can do, go here for more information.

This blog post will provide a baseline understanding of how FAS automation works and includes PowerShell code required to build a scalable solution. When designing for an automated solution, it’s very difficult to take an one-size-fits-all approach. In the spirit of this automation, you may need to modify these to incorporate them into your overall framework. In this blog, we wanted to lay out the ground work to make you successful in automating FAS.

Like any piece of coding, you typically start with breaking the problem down into smaller problems, and then breaking down the smaller problems into simple steps. Personally, I like to think of it as building a run book for an IT admin and then making the computer perform each step in the run book for me. The high-level steps are: install, configure, and then enjoy.

With FAS, the installation on the command line involves using the MSI (I wrapped this in PowerShell to make it consistent); configuring using the Citrix PowerShell SDK which you can find at this link; and enjoying by having the satisfaction of a single sign-on with an authentication mechanism of your choice! I hope you can take some of the examples in this post and implement them at your organization!

Tips for Running the PowerShell Script
The FAS scripts were written as functions and to run them standalone, you may need to do a dot include to utilize them. An example of doing a dot include is highlighted in orange:



Software Installation
The first step to any automated deployment is installing the software. Our goal is to perform an unattended installation of the FAS server. For this implementation, we leveraged the provided FAS MSI to perform a standard quiet-mode installation.

Keep in mind that with automating any component using the MSI, you lose out on some of the luxuries built into Citrix’s metainstaller. In this case, the biggest thing we are losing is the automatic configuration of the firewall rules. The firewall rules configuration can be automated separately, but for the sake of this blog, I will focus only on the FAS installation/configuration. Click here to see the full firewall rule set.

PowerShell Script (Deploy-FAS.ps1)
The FAS Server installation script has a single parameter that defines the path to the MSI file. The code for this is simple. It starts the installation process, waits for the process to finish, and then checks the Event Viewer logs for a successful installation. To manually verify installation, simply check the start menu and see if the FAS server installed properly.

Parameters

Path to the FAS MSI file (FASMSIPath): Typically, this is found in the ISO located at “D:\x64\Federated Authentication Service\FederatedAuthenticationService_x64.msi”
An example running the code:



Initial Setup Configuration

The initial FAS Server configuration is broken into three steps:

Deploy Certificate Templates: The first step is to publish the certificate templates to the current Active Directory Domain.
Setup Certificate Authority: The next step is to specify a Certificate Authority and allow it to issue certificates based off the templates uploaded in the previous step.
Authorize FAS Server: The last step is to authorize this FAS server to issue certificates upon the certificate authorities’ behalf.
In terms of automating the configuration, we take the same approach as the GUI. Breaking down the script we created, three Citrix FAS PowerShell SDK commandlets were used to automate the “Initial Setup” tab in the FAS GUI:



1. New-FasMsTemplate maps to Deploy Certificate Templates
New-FasMsTemplate -FileName $templatePath -acl $sddlString

The New-FasMsTemplate is the equivalent of Deploy certificate templates. It takes a specified certificate template and publishes it to the Active Directory domain. The FileName parameter is the path to the certificate template, and the acl parameter allows you to specify an SDDL string to curate the permissions for these templates. By default, the GUI sets these permissions for you, however, on PowerShell, you must specify the permissions explicitly. For the latest recommended permissions, refer to the FAS Security documentation.

2. Publish-FasMsTemplate maps to Setup Certificate Authority
Publish-FasMsTemplate -Name $templateName -CertificateAuthority $CAServer

The Publish-FasMsTemplate is the equivalent of Setup Certificate Authority. It essentially takes in the template name (under the Name parameter) and authorizes a specific Certificate Authority server (under CertificateAuthority) to utilize this template. Prior to this step, the templates are installed onto the Active Directory environment but are not necessarily useable by the Certificate Authority. This command lets the specified Certificate Authority use these templates.

3. New-FasAuthorizationCertificate maps to Authorize this Service
New-FasAuthorizationCertificate -CertificateAuthority $CAServer -Address $FASAddress -CertificateTemplate "Citrix_RegistrationAuthority" -AuthorizationTemplate "Citrix_RegistrationAuthority_ManualAuthorization"

The New-FasAuthorizationCertificate cmdlet is the equivalent of Authorize this Service. It initiates a request to the Certificate Authority for an Authorization Certificate. This allows FAS to automatically issue virtual smartcard certificates on behalf of the user for logon, allowing different authentication methods to be used for a single sign-on.

One of the largest pain points encountered when developing this solution was alleviated in this script. Traditionally, the user initiates the request in the GUI, and administrator would need to go into the Certificate Authority console to approve the pending request. To remediate this dependency, we used a scraping-like method to remotely execute code that approves the latest request in the Certificate Authority.

PowerShell Script (Configure-FAS.ps1)
This script emulates what is happening in the GUI with the three basic steps — installing the certificate templates to the domain, publishing them to each certificate authority, and creating a registration authority certificate (referred to as the Authorization Certificate in the PowerShell SDK) allowing FAS to issue smart card certificates on behalf of the user. At the end of running the script, you should see three solid green bars in the FAS GUI indicating that the initial configuration was a success!

Parameters

Certificate Authority servers: An array of strings where each string represents the name of the CA server. If you only have a single CA server, this will be an array of size 1.
FAS server FQDN: Because an environment may have more than one FAS server, we aimed to be explicit and let the bigger framework decide which FAS server it wants to configure.
FAS security group SID: In this implementation, we had multiple FAS servers. To simply things, we could use a security group containing the multiple FAS servers and reference the SID when creating the certificate templates.
Below is an example of running the code:



Permissions

To run this code, the following permissions are required as outlined in the FAS Security documentation:

Local Administrator: The user account running the script must be a Local Administrator on the FAS server.
Enterprise Forest Administrator: The permission required to install certificate templates.
Certificate Authority Administrator: The permission required to configure the CA server.
Validation

You may want to check the Authorization Certificate in PowerShell, as well using the Get-FasAuthorizationCertificate command noted below. Note that this FasAuthorizationCertificate will be referenced in the next step for Configuring User Rules.



User Rules Configuration

The user rules configuration is the next step in sequentially configuring FAS. The user rules specify which users, StoreFront servers, and Virtual Delivery Agent (VDA) machines are authorized for FAS logons. Breaking down the FAS GUI below, you are creating a rule that specifies which machine can issue certificates based on the template Citrix_SmartCardLogon.

Automating this component is actually three lines, however, building the access control list’s SDDL Strings that specify the individuals StoreFronts, VDAs, and Users is what makes up the majority of the script. Another thing to note is that under the hood (and only seen in the PowerShell configuration), the GUI is broken up into two major components: the FasCertificateDefinition and the FasRule. Together, these utilize the the FasAuthorizationCertificate requested in the initial configuration to issue the certificate to the specified users/components.

Now let’s break down the major commands used in configuring User-Rules using the GUI as a reference:



1. New-FasCertificateDefinition maps to the GUI outlined in orange
New-FasCertificateDefinition -Name "default_Definition" -MsTemplate "Citrix_SmartcardLogon" -AuthorizationCertificate $FasAuthorizationCertificateGUID -CertificateAuthorities $CAservers -Address $FASAddress

In the example provided, I am creating a certificate definition called “default_Definition.” We are specifying “Citrix_SmartcardLogon” as the certificate template via the MsTemplate parameter, and we are specifying one or more Certificate Authorities in the CertificateAuthorities parameter. Lastly, we are binding it to the FasAuthorizationCertificate from the initial config automation using the GUID via the AuthorizationCertificate parameter.

Note that we need to specify the FAS server’s FQDN as well as noted by the Address parameter.

2. New-FasRule maps to the GUI outlined in blue
New-FasRule -Name default -CertificateDefinitions @("default_Definition") -Address $FASAddress -StoreFrontAcl "$($SFACLString)" -UserAcl "$($UserACLString)" -VdaAcl "$($VDAACLString)"
In this case, we are making a User Rule called “default” (noted by the Name parameter) and adding the Certificate Definition specified as a single element in an array. Note, this means you can have multiple certificate definitions bound by the same User Rule, and this can be very powerful in a more complex deployment.

We then specify the SDDL strings and bind them to the appropriate ACL for StoreFront (noted by StoreFrontAcl), users (noted by UserAcl), and the VDAs (noted by VdaAcl).

Note that we need to specify the FAS server’s FQDN as well as noted by the Address parameter.

PowerShell Script (Configure-FAS-UserRules.ps1)
We pass in the following parameters:

StoreFront permissions: An array of hash tables where each hash table has a corresponding StoreFront (or security group of StoreFront servers) SID and an Allow/Deny permission.
VDA permissions: An array of hash tables where each hash table has a corresponding VDA (or security group of VDAs) SID and an Allow/Deny permission.
User permissions: An array of hash tables where each table has a corresponding user (or security group of users) SID and an Allow/Deny permission
Certificate Authority servers: An array of strings where each string represents the name of the CA server. If you only have a single CA server, this will be an array of size 1.
FAS server FQDN: Because an environment may have more than one FAS server, we aimed to be explicit and let the bigger framework decide which FAS server it wants to configure.
This script first gets the AuthorizationCertificate’s GUID from the initial setup (remember the third step?) and uses it to create the Certificate Definition. We then build out the Access Control List SDDL Strings for StoreFront, Users, and the VDAs using basic String manipulation techniques. Lastly, we create the FasRule that binds the ACL’s to the Certificate Definition.

Below is an example of running the code.

First define your StoreFront, VDA, and User permissions hashtables (I copied and pasted them in from notepad for ease):



Then run the script referencing the StoreFront, VDA, and User variables defined in the previous step.



At the end of running this script, if you have multiple CAs configured, the GUI may be inaccessible (as of the time writing this article). The Certificate Authorities and the Certificate template dropdowns may appear to be empty. This is a known issue and is documented here. If you are using a single Certificate Authority, simply verify against the GUI. Otherwise, the next best way to check this is to run the “Get-FASRule” commands to see if it works as expected. Noting the screenshots below:





To validate the ACL’s to see if they are resolving with Active Directory properly (regardless of multiple Certificate Authorities or not), simple click the edit button on the GUI and look at the popups.



Note, when you are done, click the cancel button, as you do not want to overwrite anything performed by the automation.

Conclusion & Additional Notes
I hope this gave you a better idea of what it takes to automate a FAS deployment. With more companies moving towards a DevOps mindset, they should consider scripting out portions of the Citrix deployment. This way, when they need to upgrade or redeploy, it is as simple as building up the new infrastructure and tearing down the old. Hopefully, companies adopt this mindset moving forward to reduce the amount of admin time, and to focus on building out the successful Workspace.

As of the time writing this article, StoreFront doesn’t natively support configuring FAS in the GUI. Luckily, with a few simple commands, we can automate this too. StoreFront is a critical piece of the FAS process, and it needs to be configured to support FAS. The required PowerShell code can be found here.
