-- Make cindent (used for C/C++ instead of treesitter indent) agree with
-- ~/.clang-format, so `=` and typing don't fight format-on-save:
--   g0  public:/private: flush with the class      (AccessModifierOffset: -2)
--   :0  case labels flush with the switch          (IndentCaseLabels: false)
--   (0  continuation lines align after the open paren (AlignAfterOpenBracket)
--   N0  namespace bodies are indented              (NamespaceIndentation: All)
vim.opt_local.cinoptions = "g0,:0,(0,N0"
