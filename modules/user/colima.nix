# Colima on macOS: a container VM with the containerd runtime and a k3s
# Kubernetes cluster that share ONE containerd image store.
#
# The point of this setup: an image you build or pull lands in the same store
# that Kubernetes reads. So the image is usable by `kubectl` with no separate
# load step. colima achieves this by starting k3s with
# `--container-runtime-endpoint` pointed at the VM containerd, instead of the
# containerd that k3s normally embeds.
#
# containerd has no Docker daemon, so the client is nerdctl. colima runs
# nerdctl inside the VM. The `docker` and `nerdctl` wrappers below reach it with
# `colima nerdctl --`. A host nerdctl from nixpkgs would not work, because it
# looks for a local containerd that macOS does not have.
{ pkgs, config, ... }:
let
  colimaPkg = pkgs.unstable.colima;

  # `docker` and `nerdctl` are real executables on PATH, not shell aliases, so
  # scripts and every shell resolve them the same way. They forward to colima's
  # in-VM nerdctl, which takes the same arguments as the Docker CLI.
  #
  # `--namespace k8s.io` is a global nerdctl flag, so it pins every subcommand
  # (build, pull, run, compose, ps) to one containerd namespace. That namespace
  # is the store Kubernetes reads, so every image you build or pull is usable by
  # the cluster with no load step. This mirrors Docker's single flat store.
  #
  # colima is referenced by its absolute store path, so the wrapper resolves it
  # even when a script runs with a minimal PATH.
  #
  # For a pod to use a local image, set imagePullPolicy: IfNotPresent and avoid
  # the `latest` tag, or kubelet pulls from a registry instead.
  #
  # Two consequences of the shared namespace: `docker ps` also lists the
  # cluster's own containers (kube-system pods), and kubelet image garbage
  # collection can remove images no pod references when disk runs low.
  mkWrapper =
    name:
    pkgs.writeShellScriptBin name ''
      exec ${colimaPkg}/bin/colima nerdctl -- --namespace k8s.io "$@"
    '';
in
{
  home.packages = [
    (mkWrapper "docker")
    (mkWrapper "nerdctl")
  ];

  # home-manager's colima module installs colima, writes the profile's
  # colima.yaml from `settings`, and adds a launchd agent
  # (org.nix-community.home.colima-default) that runs `colima start default -f`
  # at login. Because `settings` is set, colima runs with --save-config=false and
  # never rewrites the nix-managed file.
  #
  # The agent restarts colima after a clean exit, so `colima stop` alone does not
  # keep it stopped. To stop it until the next login, run:
  #   launchctl bootout gui/$(id -u)/org.nix-community.home.colima-default
  services.colima = {
    enable = true;
    package = colimaPkg;
    kubectlPackage = pkgs.unstable.kubectl;

    profiles.default = {
      isService = true;
      isActive = true;
      # launchd does not create parent directories for log files, and
      # ~/Library/Logs always exists.
      logFile = "${config.kegs.homeDir}/Library/Logs/colima-default.log";

      # Matches the existing instance. runtime, vmType, and arch are fixed when
      # the VM is created; changing them needs `colima delete` first.
      settings = {
        cpu = 4;
        memory = 8;
        disk = 60;
        rootDisk = 20;
        hostname = "colima";
        vmType = "vz";
        rosetta = true;
        binfmt = true;
        mountType = "virtiofs";
        portForwarder = "ssh";
        autoActivate = true;
        mounts = [
          {
            location = config.kegs.homeDir;
            writable = true;
          }
        ];
        runtime = "containerd";
        kubernetes = {
          enabled = true;
          k3sArgs = [ "--disable=traefik" ];
        };
      };
    };
  };

  # colima wrote this file when it created the VM. The nix-managed file above
  # holds the same settings, so replace it instead of failing the switch.
  home.file.".colima/default/colima.yaml".force = true;
}
