# helix-file-watcher (https://github.com/mattwparas/helix-file-watcher), a
# Steel plugin for the helix fork that reloads open files when they change on
# disk. Built here instead of with forge, the Steel package manager.
{
  rustPlatform,
  inputs,
}:
rustPlatform.buildRustPackage {
  pname = "helix-file-watcher";
  version = "0.1.0";
  src = inputs.helix-file-watcher;

  # steel-core is a git dependency. allowBuiltinFetchGit fetches it at the
  # rev in Cargo.lock, so it needs no output hash.
  cargoLock = {
    lockFile = "${inputs.helix-file-watcher}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

  # Upstream bug: path->doc-id compares a path with symlinks resolved to
  # helix's document path, which keeps symlinks. Files opened through a
  # symlink (for example /tmp on macOS) then never reload. Resolve both sides.
  postPatch = ''
    substituteInPlace file-watcher.scm --replace-fail \
      '(equal? (editor-document->path doc-id) path)' \
      '(let ([p (editor-document->path doc-id)]) (and p (equal? (try-canonicalize-path p) path)))'
  '';

  cargoBuildFlags = [ "--lib" ];
  doCheck = false;

  # The Steel modules that wrap the library.
  postInstall = ''
    mkdir -p $out/share/helix-file-watcher
    cp *.scm $out/share/helix-file-watcher/
  '';
}
