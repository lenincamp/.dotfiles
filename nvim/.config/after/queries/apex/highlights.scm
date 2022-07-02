(class_declaration
  name: (identifier) @name) @definition.class

(method_declaration
  name: (identifier) @name) @definition.method

(method_invocation
  name: (identifier) @name
  arguments: (argument_list) @reference.call)

(interface_declaration
  name: (identifier) @name) @definition.interface

(interface_type_list
  (type_identifier) @name) @reference.implementation

(object_creation_expression
  type: (type_identifier) @name) @reference.class

(superclass (type_identifier) @name) @reference.class

; Methods

(method_declaration
  name: (identifier) @function.method)
(method_invocation
  name: (identifier) @function.method)
(super) @function.builtin

; Annotations

(annotation
  name: (identifier) @attribute)
(marker_annotation
  name: (identifier) @attribute)


; Operators
; Annotations
[
"@"
"+"
":"
"++"
"-"
"--"
"&"
"&&"
"|"
"||"
"!="
"=="
"*"
"/"
"%"
"<"
"<="
">"
">="
"="
"-="
"+="
"*="
"/="
"%="
"->"
"^"
"^="
"&="
"|="
"~"
">>"
">>>"
"<<"
"::"
] @operator

; Types
(record_declaration
  name: (identifier) @type)
((method_invocation
  object: (identifier) @type)
 (#lua-match? @type "^[A-Z]"))
((method_reference
  . (identifier) @type)
 (#lua-match? @type "^[A-Z]"))

(interface_declaration
  name: (identifier) @type)
(class_declaration
  name: (identifier) @type)
(enum_declaration
  name: (identifier) @type)

((field_access
  object: (identifier) @type)
 (#match? @type "^[A-Z]"))
((scoped_identifier
  scope: (identifier) @type)
 (#match? @type "^[A-Z]"))

(constructor_declaration
  name: (identifier) @type)

(type_identifier) @type

[
  (boolean_type)
  (integral_type)
  (floating_point_type)
  (floating_point_type)
  (void_type)
  ; (array_soql)
] @type.builtin


; Parameters
(formal_parameter
  name: (identifier) @parameter)
(catch_formal_parameter
  name: (identifier) @parameter)

(spread_parameter
 (variable_declarator) @parameter) ; int... foo

;; Lambda parameter
(inferred_parameters (identifier) @parameter) ; (x,y) -> ...
(lambda_expression
    parameters: (identifier) @parameter) ; x -> ...

; Fields

(field_declaration
  declarator: (variable_declarator) @field)

(field_access
  field: (identifier) @field)

; Variables

((identifier) @constant
 (#match? @constant "^_*[A-Z][A-Z\\d_]+$"))

(identifier) @variable

(this) @variable.builtin

; Literals

[
  (hex_integer_literal)
  (decimal_integer_literal)
  (octal_integer_literal)
  (decimal_floating_point_literal)
  (hex_floating_point_literal)
] @number

[
(decimal_floating_point_literal)
(hex_floating_point_literal)
] @float

[
  (character_literal)
  (string_literal)
] @string


(null_literal) @constant.builtin

(comment) @comment

[
(true)
(false)
] @boolean


; Keywords

[
  "abstract"
  "assert"
  "break"
  "case"
  "catch"
  "class"
  "continue"
  "default"
  "do"
  "else"
  "enum"
  "exports"
  "extends"
  "final"
  "finally"
  "for"
  "if"
  "implements"
  "import"
  "instanceof"
  "interface"
  "module"
  "native"
  "new"
  "open"
  "opens"
  "package"
  "private"
  "protected"
  "provides"
  "public"
  "requires"
  "return"
  "static"
  "strictfp"
  "switch"
  "synchronized"
  "throw"
  "throws"
  "to"
  "transient"
  "transitive"
  "try"
  "uses"
  "volatile"
  "while"
  "with"
] @keyword


[
"return"
"yield"
] @keyword.return

[
 "new"
] @keyword.operator

; Conditionals

[
"if"
"else"
"switch"
"case"
] @conditional
(ternary_expression ["?" ":"] @conditional)

;bucles
[
"for"
"while"
"do"
] @repeat


; Includes
"import" @include
"package" @include

; Punctuation

[
";"
"."
"..."
","
] @punctuation.delimiter


[
"["
"]"
"{"
"}"
"("
")"
] @punctuation.bracket


; Exceptions

[
"throw"
"throws"
"finally"
"try"
"catch"
] @exception


; Labels
(labeled_statement
  (identifier) @label)
