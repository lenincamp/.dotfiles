; Java context.scm — overrides nvim-treesitter-context default.
; Fix: @Override annotation appears above method_declaration, causing the
; sticky context to show "@Override" instead of the method signature.
; Solution: use @context.start anchored to the return type field, which is
; always on the same line as the method name — AFTER any annotations.

(if_statement
  consequence: (_) @context.end) @context

; Anchor method context at return type (skips @Override / other annotations)
(method_declaration
  type: (_) @context.start
  body: (_) @context.end) @context

; Constructor: anchor at name (no return type, but name is after annotations)
(constructor_declaration
  name: (_) @context.start
  body: (_) @context.end) @context

(for_statement
  body: (_) @context.end) @context

(enhanced_for_statement
  body: (_) @context.end) @context

(while_statement
  body: (_) @context.end) @context

(class_declaration
  body: (_) @context.end) @context

(interface_declaration
  body: (_) @context.end) @context

(enum_declaration
  body: (_) @context.end) @context

(switch_expression) @context

(switch_block_statement_group) @context

; Removed: (expression_statement) @context
; — was causing standalone @Override lines to appear as context headers
