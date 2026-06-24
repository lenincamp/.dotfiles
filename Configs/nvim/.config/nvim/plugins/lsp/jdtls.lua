-- jdtls.nvim plugin configuration.
-- Delegates all JDTLS lifecycle to the plugin; user-specific settings only.

local home = os.getenv("HOME") or ""
local brew = "/opt/homebrew/Cellar"

require("jdtls-nvim").setup({
  -- Use JDK 21 directly to launch jdtls (bypasses Homebrew wrapper which
  -- unconditionally picks config_mac instead of config_mac_arm on Apple Silicon)
  jdtls_java_home = brew .. "/openjdk@21/21.0.11/libexec/openjdk.jdk/Contents/Home",

  -- Machine-specific JDK paths
  java_runtimes = {
    { name = "JavaSE-1.8", path = "/Library/Java/JavaVirtualMachines/jdk1.8.0_202.jdk/Contents/Home" },
    { name = "JavaSE-11", path = brew .. "/openjdk@11/11.0.31/libexec/openjdk.jdk/Contents/Home" },
    { name = "JavaSE-17", path = "/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home" },
    { name = "JavaSE-21", path = brew .. "/openjdk@21/21.0.11/libexec/openjdk.jdk/Contents/Home", default = true },
  },

  -- Lombok auto-detection (Mason → ~/.m2)
  lombok = true,

  -- Eclipse formatter
  style_file = vim.fn.stdpath("config") .. "/lua/lang/java/SofiProjectsStyle.xml",
  format_profile = "Patagonia-Style",

  -- Project-specific import exclusions (beyond plugin defaults)
  extra_import_exclusions = {
    "**/frontend/**",
    "**/cybo/**",
    "**/tools/**",
  },

  -- Feature toggles
  semantic_tokens = false,
  inlay_hints = false,
  treesitter_indent = true,

  -- User on_attach: project-specific keymaps
  on_attach = function(_, bufnr)
    local ok_java, java = pcall(require, "java")
    if ok_java and type(java.java_keymaps) == "function" then
      java.java_keymaps(bufnr)
    end
  end,
})
