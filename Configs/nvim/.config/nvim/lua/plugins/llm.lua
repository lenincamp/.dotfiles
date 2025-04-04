return {
  "huggingface/llm.nvim",
  enabled = true,
  event = "VeryLazy",
  keys = {
    {
      "<c-j>",
      function()
        require("llm.completion").complete()
      end,
      mode = "i",
      desc = "complete",
    },
  },
  opts = {
    lsp = {
      bin_path = vim.api.nvim_call_function("stdpath", { "data" }) .. "/mason/bin/llm-ls",
      cmd_env = { LLM_LOG_LEVEL = "DEBUG" },
    },
    backend = "ollama",
    model = "deepseek-coder:6.7b-base",
    url = "http://localhost:11434", -- llm-ls uses "/api/generate"
    -- cf https://github.com/ollama/ollama/blob/main/docs/api.md#parameters
    fim = {
      enabled = true,
      prefix = "<｜fim▁begin｜>",
      suffix = "<｜fim▁hole｜>",
      middle = "<｜fim▁end｜>",
    },
    request_body = {
      -- Modelfile options for the model you use
      parameters = {
        temperature = 0.2,
        top_p = 0.95,
      },
    },
  },
}
