return {
  "stevearc/conform.nvim",
  optional = true,
  opts = {
    formatters_by_ft = {
      kotlin = { "ktlint" },
      javascript = { "eslint_d", "prettier" },
      html = { "prettier" },
      css = { "prettier" },
      xml = { "prettier", "plugin-xml" },
      apex = { "prettier", "prettier-plugin-apex" },
    },
  },
}
