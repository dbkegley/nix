# Kubernetes tools: kubectl, helm, and kubectx and kubens as kubectl plugins.
#
# kubectl finds plugins on PATH by name: `kubectl-ctx` runs as `kubectl ctx`,
# and `kubectl-ns` runs as `kubectl ns`. For tab completion of a plugin,
# kubectl runs `kubectl_complete-<plugin>` with the words typed after the
# plugin name. That program prints one candidate per line, then a Cobra
# directive line (`:4` means "do not complete file names").
#
# kubectx and kubens do not use Cobra, so the completion programs below list
# the contexts and namespaces with kubectl itself.
{ pkgs, ... }:
let
  kubectx = pkgs.unstable.kubectx;

  completeCtx = pkgs.writeShellScriptBin "kubectl_complete-ctx" ''
    if [ "$#" -le 1 ]; then
      kubectl config get-contexts -o name 2>/dev/null
    fi
    echo :4
  '';

  completeNs = pkgs.writeShellScriptBin "kubectl_complete-ns" ''
    if [ "$#" -le 1 ]; then
      kubectl get namespaces -o name 2>/dev/null | sed 's|^namespace/||'
    fi
    echo :4
  '';

  kubectlPlugins = pkgs.runCommand "kubectl-ctx-ns" { } ''
    mkdir -p $out/bin
    ln -s ${kubectx}/bin/kubectx $out/bin/kubectl-ctx
    ln -s ${kubectx}/bin/kubens $out/bin/kubectl-ns
    ln -s ${completeCtx}/bin/kubectl_complete-ctx $out/bin/
    ln -s ${completeNs}/bin/kubectl_complete-ns $out/bin/
  '';
in
{
  home.packages = [
    pkgs.unstable.kubectl
    (pkgs.wrapHelm pkgs.kubernetes-helm {
      plugins = with pkgs.kubernetes-helmPlugins; [
        helm-git
      ];
    })
    kubectlPlugins
  ];

  # Without these, kubectx and kubens open an fzf picker when run with no
  # arguments, instead of printing the list.
  home.sessionVariables = {
    KUBECTX_IGNORE_FZF = "1";
    KUBENS_IGNORE_FZF = "1";
  };

  programs.zsh.initContent = ''
    command -v kubectl >/dev/null && source <(kubectl completion zsh)
    command -v helm >/dev/null && source <(helm completion zsh)
  '';
}
