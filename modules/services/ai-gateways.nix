{ ... }:

{
  # NixOS is the sole owner of these MITM host mappings.
  # Runtime scripts validate them but never mutate /etc/hosts.
  networking.extraHosts = ''
    127.0.0.1 daily-cloudcode-pa.googleapis.com
    127.0.0.1 cloudcode-pa.googleapis.com
  '';
}
