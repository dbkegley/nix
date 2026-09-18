;; Steel command module for helix (mattwparas/helix, steel-event-system).
;; Every function that is provided here becomes a typed command, called as
;; `:function-name` from the helix prompt.

;; Built-in static commands, exposed under the helix.static. prefix.
(require-builtin helix/core/static as helix.static.)

(provide insert-greeting)

;; Sample command: insert a greeting at the cursor. Run it with :insert-greeting
(define (insert-greeting)
  (helix.static.insert_string "Hello from Steel!"))
