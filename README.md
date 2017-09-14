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

3. Disable one server in example.com-farm.

4. Publish app.

    ```
    psake publish-web -properties "@{Environment='Production';ServerHost='HOSTNAME';Slot='Disabled'}"
    ```

5. Swap slots.

    ```
    psake swap-slots -properties "@{Environment='Production';ServerHost='HOSTNAME';SourceSlot='Blue';DestinationSlot='Green'}"
    ```
