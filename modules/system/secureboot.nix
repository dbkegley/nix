{ ... }:
{
  config = {
    environment.etc."kernel/uki.conf" = {
      replaceExisting = true;
      text = ''
        [UKI]
        SecureBootSigningTool=systemd-sbsign
        SignKernel=true
        SecureBootPrivateKey=/etc/kernel/secure-boot-private-key.pem
        SecureBootCertificate=/etc/kernel/secure-boot-certificate.pem
      '';
    };
  };
}
