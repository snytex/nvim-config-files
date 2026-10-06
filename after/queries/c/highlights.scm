;; extends

; header names in #include read as module paths, not strings
(preproc_include
  path: (_) @string.special.path)
