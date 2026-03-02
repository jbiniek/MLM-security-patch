{% set os_family = grains['os_family'] %}

# -------------------------------------------------------------------------
# SUSE FAMILY (SLES, OpenSUSE)
# Uses zypper with the specific patch category filter.
# -------------------------------------------------------------------------
{% if os_family == 'Suse' %}
install_security_patches_suse:
  cmd.run:
    - name: zypper patch --category security --auto-agree-with-licenses --quiet
    - order: last

# -------------------------------------------------------------------------
# REDHAT FAMILY (RHEL, CentOS, Alma, Rocky, Fedora)
# Differentiates between dnf (RHEL 8+) and yum (RHEL 7).
# -------------------------------------------------------------------------
{% elif os_family == 'RedHat' %}
  {% if grains['osmajorrelease']|int >= 8 %}
install_security_patches_rhel8plus:
  cmd.run:
    - name: dnf update --security -y
    - order: last
  {% else %}
install_security_patches_rhel7:
  cmd.run:
    # Ensure the plugin is present first, though standard on most RHEL7 systems
    - name: yum -y install yum-plugin-security && yum update --security -y
    - order: last
  {% endif %}

# -------------------------------------------------------------------------
# DEBIAN FAMILY (Ubuntu, Debian)
# "apt-get" does not have a native --security flag. The standard way to do 
# this is using the 'unattended-upgrades' tool in manual execution mode.
# -------------------------------------------------------------------------
{% elif os_family == 'Debian' %}

# Ensure the tool exists first
install_unattended_upgrades_tool:
  pkg.installed:
    - name: unattended-upgrades

run_security_updates_debian:
  cmd.run:
    # Running it without arguments defaults to the 'security' profile
    - name: unattended-upgrade -v
    - require:
      - pkg: install_unattended_upgrades_tool
    - order: last

{% endif %}
