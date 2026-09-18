;; Steel startup file for helix (mattwparas/helix, steel-event-system).
;; This runs when helix starts. Use it to load your command module and to
;; register keybindings and event hooks.

;; Load the command module so its provided commands (for example
;; :insert-greeting) are available.
(require "helix.scm")
