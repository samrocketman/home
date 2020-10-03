# Firewall

These are my firewall rules along with log locations and log rotation.

- [`rsyslog.d/01-iptables.conf`][1] goes into `/etc/rsyslog.d/`.  The rule
  should be alphabetically early so that discard rules apply to other logs.
  `service rsyslog restart` must be run to apply the configuration.  See also
  `man rsyslog.conf`.
- [`logrotate.d/iptables`][2] goes into `/etc/logrotate.d/`.  This is so that
  firewall logs get rotated on a daily basis.  No service restart is required
  because logrotate is executed by anacron periodically.
- [`iptables.rules`][3] is my firewall.

# Applying the firewall

Enable the firewall

    iptables-restore < iptables.rules

Disable the firewall

    iptables -F

View the firewall

    iptables -nL
    iptables -t nat -nL

Render the firewall rules

    iptables-save

See also: `man iptables` and `man iptables-extensions`.

# Testing log rotation

You can test log rotation with the following command.

    sudo logrotate --force /etc/logrotate.d/iptables

See also `man logrotate`.

[1]: rsyslog.d/01-iptables.conf
[2]: logrotate.d/iptables
[3]: iptables.rules
