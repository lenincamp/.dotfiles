; extends

; MyBatis SQL tags in mapper XML.
; Inject direct SQL text nodes inside CRUD statements.
((element
  (STag
    (Name) @_name)
  (content
    (CharData) @injection.content))
  (#match? @_name "^(select|insert|update|delete)$")
  (#set! injection.language "sql"))

((element
  (STag
    (Name) @_name)
  (content
    (CDSect) @injection.content))
  (#match? @_name "^(select|insert|update|delete)$")
  (#set! injection.language "sql"))
