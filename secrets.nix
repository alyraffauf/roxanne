{self, ...}: {
  age.secrets = {
    rclone-b2.file = "${self.inputs.secrets}/rclone/b2.age";
    restic-passwd.file = "${self.inputs.secrets}/restic.age";
    tailscaleAuthKey.file = "${self.inputs.secrets}/tailscale/authKeyFile.age";
  };
}
