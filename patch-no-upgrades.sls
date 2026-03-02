{% set os_family = grains['os_family'] %}

# -------------------------------------------------------------------------
# SUSE FAMILY (SLES, OpenSUSE)
# Command: 'zypper patch'
# Behavior: Installs all official patches (Security, Bugfix, Enhancement).
# It specifically IGNORES 'zypper up' candidates that are just newer versions
# without an associated Errata/Advisory.
# -------------------------------------------------------------------------
{% if os_family == 'Suse' %}
apply_all_patches_suse:
  cmd.run:
    - name: zypper patch --auto-agree-with-licenses --quiet
    - order: last

# -------------------------------------------------------------------------
# REDHAT FAMILY (RHEL, CentOS, Alma, Rocky)
# Command: 'dnf/yum update --security --bugfix --enhancement'
# Behavior: By explicitly filtering for these three categories, we tell the 
# package manager to ignore updates that do NOT fall into these buckets.
# This prevents installing a package just because it has a higher version number.
# -------------------------------------------------------------------------
{% elif os_family == 'RedHat' %}
apply_errata_only_rhel:
  cmd.run:
    # dnf (RHEL 8+) supports these flags natively.
    # yum (RHEL 7) supports them if yum-plugin-security is installed (standard on SUSA Manager clients).
    {% if grains['osmajorrelease']|int >= 8 %}
    - name: dnf update --security --bugfix --enhancement -y
    {% else %}
    - name: yum update --security --bugfix --enhancement -y
    {% endif %}
    - order: last

# -------------------------------------------------------------------------
# DEBIAN FAMILY (Ubuntu, Debian)
# Command: 'apt-get upgrade' (NOT dist-upgrade)
# Behavior: Apt does not have strict "Advisory" metadata like RPM distros.
# However, 'upgrade' is the "Safe" mode. It upgrades packages but refuses 
# to install NEW dependencies or remove OLD packages. This effectively 
# keeps the system on its current version track without jumping major versions.
# -------------------------------------------------------------------------
{% elif os_family == 'Debian' %}
safe_upgrade_debian:
  cmd.run:
    - name: apt-get update && apt-get upgrade -y
    - order: last
{% endif %}
