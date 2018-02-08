# Duplicity salt formula

Install and configure the Duplicity (including systemd timer/ service)

## Available states

### ``init.sls``

Install the `duplicity` package as well as other required packages (by the used
backend) and deploy and enable a systemd timer to automatically take backup
periodically.
