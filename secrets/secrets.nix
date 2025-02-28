let
  hosts = [
    "lilycove"
    "petalburg"
    "roxanne"
    "sootopolis"
  ];
  users = [
    "aly_lilycove"
    "aly_petalburg"
    "aly_roxanne"
    "aly_sootopolis"
  ];
  systemKeys = builtins.map (host: builtins.readFile ./publicKeys/root_${host}.pub) hosts;
  userKeys = builtins.map (user: builtins.readFile ./publicKeys/${user}.pub) users;
  keys = systemKeys ++ userKeys;
in {
  "rclone/b2.age".publicKeys = keys;
  "restic.age".publicKeys = keys;
  "tailscale/authKeyFile.age".publicKeys = keys;
}
