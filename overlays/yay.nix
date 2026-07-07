# Fix yay version reporting
#
# The nixpkgs yay package doesn't properly embed the version during build,
# causing yay to report v12.0.4 instead of the actual version.
# The version is hardcoded in main.go as yayVersion = "12.0.4"
# This overlay adds the necessary ldflags to embed the version correctly.
final: prev: {
  yay = prev.yay.overrideAttrs (oldAttrs: {
    ldflags = [
      "-s"
      "-w"
      "-X main.yayVersion=${oldAttrs.version}"
    ];
  });
}
