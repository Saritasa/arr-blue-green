Expand-PsakeConfiguration `
@{
    Configuration = 'Release'

    Slots = @('Blue', 'Green')
    SiteName = 'example.com'
    WwwrootPath = 'C:\inetpub\wwwroot'

    DeployUsername = 'DeployUser'
    DeployPassword = 'TestPwd@1234'
    AdminUsername = 'Administrator'
    AdminPassword = 'Qwerty123'

    CertificatePassword = 'rDXQL9n3'
}