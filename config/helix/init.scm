;; Steel startup file for helix (mattwparas/helix, steel-event-system).
;; This runs when helix starts. Use it to load plugins and to register
;; keybindings and event hooks.

;; Reload open files when they change on disk. The plugin is built in
;; pkgs/helix-file-watcher and installed by modules/user/helix.nix.
(require "helix-file-watcher/file-watcher.scm")
(require "helix/misc.scm")

;; init.scm runs before helix opens the files named on the command line, and
;; the watcher ignores files that open before its thread starts. So start it
;; after a short delay, when those files are open.
(enqueue-thread-local-callback-with-delay 100 (lambda () (spawn-watcher)))
