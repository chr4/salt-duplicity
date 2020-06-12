# Duplicity salt formula

![Saltstack](https://github.com/chr4/salt-duplicity/workflows/Saltstack/badge.svg)

Install and configure the Duplicity (including systemd timer/ service)


## Available states

### ``init.sls``

Install the `duplicity` package as well as other required packages (by the used
backend) and deploy and enable a systemd timer to automatically take backup
periodically.

See `pillar.example` for documentation details.


## Monitor time since last backup

The monit state in this forumla deploys a `duplicity-monit` script. It can be used to ensure that you get alerted when the last backup taken exceeds a certain time.

Monit needs to be configured e.g. using the salt-monit formula.

```yaml
  # Check duplicity hourly (cycle is 120s)
  # Do not check between 1 and 7 at night (while backup is running)
  # tune "not every" to match the on_calendar setting in the duplicity pillar
  duplicity: |
    check program duplicity with path /usr/local/bin/duplicity-monit
    every 30 cycles
    not every "* 1-7 * * *"
    if status != 0 then alert
```
