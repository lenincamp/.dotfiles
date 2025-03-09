return {
  {
    "oclay1st/maven.nvim",
    cmd = { "Maven", "MavenInit", "MavenExec" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    opts = { mvn_executable = "/opt/homebrew/bin/mvn" }, -- options, see default configuration
    keys = { { "<Leader>M", "<cmd>Maven<cr>", desc = "Maven" } },
  },
}
