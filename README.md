ARR & Blue-Green Deployment
===========================

Configure Server
----------------

1. Configure WinRM.

    https://github.com/Saritasa/PSGallery/blob/master/docs/WinRMConfiguration.md

2. Install IIS and other software.

    ```
    psake setup-web-server -properties "@{Environment='Production';ServerHost='HOSTNAME'}"
    ```
