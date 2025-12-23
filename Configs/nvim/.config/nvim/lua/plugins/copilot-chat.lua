return {
  "CopilotC-Nvim/CopilotChat.nvim",
  branch = "main",
  cmd = "CopilotChat",
  lazy = true,
  opts = function()
    local user = vim.env.USER or "User"
    user = user:sub(1, 1):upper() .. user:sub(2)
    return {
      auto_insert_mode = true,
      show_help = true,
      headers = {
        user = "  " .. user .. " ",
        assistant = "  Copilot ",
        tool = "󰊳  Tool ",
      },
      window = {
        width = 0.4,
      },
      auto_follow_cursor = false,
      model = "gpt-5",
    }
  end,
  keys = {
    { "<c-s>", "<CR>", ft = "copilot-chat", desc = "Submit Prompt", remap = true },
    -- { "<leader>a", "", desc = "+ai", mode = { "n", "x" } },
    {
      "<leader>ac",
      function()
        return require("CopilotChat").toggle()
      end,
      desc = "Toggle (CopilotChat)",
      mode = { "n", "x" },
    },
    {
      "<leader>ax",
      function()
        return require("CopilotChat").reset()
      end,
      desc = "Clear (CopilotChat)",
      mode = { "n", "x" },
    },
    {
      "<leader>aq",
      function()
        vim.ui.input({
          prompt = "Quick Chat: ",
        }, function(input)
          if input ~= "" then
            require("CopilotChat").ask(input)
          end
        end)
      end,
      desc = "Quick Chat (CopilotChat)",
      mode = { "n", "x" },
    },
    {
      "<leader>aP",
      function()
        require("CopilotChat").select_prompt()
      end,
      desc = "Prompt Actions (CopilotChat)",
      mode = { "n", "x" },
    },
  },
  config = function(_, opts)
    local chat = require("CopilotChat")

    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "copilot-chat",
      callback = function()
        vim.opt_local.relativenumber = false
        vim.opt_local.number = false
      end,
    })
    opts.prompts = {
      ElegantNames = {
        system_prompt = 'You are a naming advisor following "Elegant Objects".',
        prompt = [[ For the selected code, propose better names.
Rules:
- Types/objects: nouns.
- Functions/methods: verbs.
- Ban -er/-or/-ar agent nouns (Manager, Parser, Handler, Reader, Writer,
  Controller, Actor) and vague roles (Util, Helper, Service, Processor,
  Data, Info, Thing, Object, Stuff).
- Prefer precise domain terms; follow language casing.
- Keep behavior; only naming suggestions.

Output:
- For each symbol: 3–5 options with one-line rationale.
- If name ends with -er/-or/-ar, flag it and propose noun/verb alternatives.]],
        description = "Elegant Objects naming suggestions",
      },
    }

    chat.setup(opts)
  end,
}
