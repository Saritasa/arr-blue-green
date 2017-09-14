Expand-PsakeConfiguration `
@{
    Configuration = 'Release'

    Slots = @('Blue', 'Green')
    SiteName = 'example.com'
    WwwrootPath = 'C:\inetpub\wwwroot'

    DeployUsername = 'DeployUser'
    DeployPassword = 'TestPwd@1234'
}