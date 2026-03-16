-- copilot.lua + CopilotChat: setup with 13 domain-specific prompts.

local ok_copilot, copilot = pcall(require, "copilot")
if not ok_copilot then return end

-- copilot.lua: disable built-in suggestion/panel UI — blink.cmp handles it
copilot.setup({
  suggestion = { enabled = false },
  panel      = { enabled = false },
})

local ok_chat, chat = pcall(require, "CopilotChat")
if not ok_chat then return end

-- ── helpers ───────────────────────────────────────────────────────────────────

local user = vim.env.USER or "User"
user = user:sub(1, 1):upper() .. user:sub(2)

-- ── setup ─────────────────────────────────────────────────────────────────────

chat.setup({
  auto_insert_mode  = true,
  show_help         = true,
  auto_follow_cursor = false,
  model             = "gpt-4.1",
  headers = {
    user      = "  " .. user .. " ",
    assistant = "  Copilot ",
    tool      = "󰊳  Tool ",
  },
  window = { width = 0.4 },

  -- ── Domain prompts ──────────────────────────────────────────────────────────
  prompts = {

    ElegantNames = {
      description = "Suggest better names per Elegant Objects rules.",
      system_prompt = [[You are a strict naming reviewer. Enforce EO rules:
types/objects are nouns; functions/methods are verbs; avoid agent nouns
(-er/-or/-ar) and vague roles; prefer precise domain terms; keep behavior
unchanged; follow language casing. Return concise options with rationale.]],
      prompt = [[Suggest 3–5 name options for each symbol in the selection.
Rules: types/objects are nouns; functions/methods are verbs; ban agent
nouns (-er/-or/-ar) and vague roles (Util/Helper/Service); prefer domain
terms; keep behavior unchanged; follow language casing. Output: options
with one-line rationale; flag any -er/-or/-ar and propose noun/verb
alternatives.]],
    },

    ElegantObjectsRefactor = {
      description = "Refactor code toward Elegant Objects principles.",
      system_prompt = [[You are an EO-focused reviewer. Identify violations and
propose minimal refactors with small patches. Preserve behavior and
public API while improving object design.]],
      prompt = [[For the selection, identify Elegant Objects violations and propose
minimal refactors: remove getters/setters, avoid nulls, avoid static/
utility classes, favor immutability and composition, reduce temporal
coupling, move behavior to objects, use exceptions over sentinel values.
Output: bullet checklist + small code patches.]],
    },

    EffectiveJavaAudit = {
      description = "Apply key Effective Java practices.",
      system_prompt = [[You audit code for Effective Java essentials. Be concise,
actionable, and provide small diffs and tests when relevant.]],
      prompt = [[Audit the selection for: equals/hashCode/compareTo contracts,
toString quality, builders for complex construction, prefer interfaces
and composition, defensive copies, try-with-resources, avoid finalizers,
caching/lazy init rules, immutability. Output: issues + short diffs +
test cases.]],
    },

    JavaModulesBoundaries = {
      description = "Check Maven module boundaries and APIs.",
      system_prompt = [[You enforce clean module boundaries: clear APIs vs internals,
no cycles, proper dependencies, and well-defined DTOs/services.]],
      prompt = [[Check Maven module boundaries: package visibility, module API vs
internal, dependency direction (no cycles), DTOs vs domain across
modules, exceptions per module, service interfaces, factories, SPI.
Output: boundary violations + refactor plan + sample code.]],
    },

    JavaExceptionPolicy = {
      description = "Define a consistent exception policy for Java.",
      system_prompt = [[You design pragmatic exception strategy: checked vs unchecked,
wrapping, mapping to domain errors, and avoiding null-based control
flow.]],
      prompt = [[Propose a consistent checked/unchecked policy, wrap external
exceptions, avoid null returns, use Optional only for absence (not
errors), map errors to domain exceptions. Output: policy + code examples.]],
    },

    ReactComponentPatterns = {
      description = "Apply advanced React TS component patterns.",
      system_prompt = [[You refactor React to clearer components and hooks. Optimize
state colocation, memoization, and stable callbacks without overdesign.]],
      prompt = [[Refactor toward advanced React TS patterns: presentational vs
container split, hooks for reusable logic, state colocation,
memoization, stable callbacks, controlled inputs, suspense-ready data
boundaries. Output: component tree sketch + refactor steps + code snippets.]],
    },

    ReactSliceDesign = {
      description = "Design a robust Redux Toolkit slice (TS).",
      system_prompt = [[You design Redux slices with strong typing, normalization,
selectors, and clear async strategy (thunks or sagas).]],
      prompt = [[Design a robust Redux Toolkit slice: state shape, actions,
reducers, memoized selectors, entityAdapter usage, createAsyncThunk or
saga decision, normalization, error/loading flags, tests. Output: slice
scaffold (TS), selectors, example usage.]],
    },

    TypeSafeRedux = {
      description = "Strengthen TypeScript typing in Redux.",
      system_prompt = [[You upgrade Redux types: typed Dispatch/Thunk/Saga, precise
action and selector types, no any, and typed middleware.]],
      prompt = [[Strengthen TS typing in Redux: typed Dispatch/Thunk/Saga, action
creators with ReturnType, selectors with exact types, no any, infer
payload from createSlice, typed middleware. Output: code upgrades + notes.]],
    },

    SagaDesignGuide = {
      description = "Use sagas only where they add clear value.",
      system_prompt = [[You decide pragmatically between saga and RTK Query/thunks.
Favor sagas for orchestration, cancellation, and long-running flows.]],
      prompt = [[Decide between saga vs createAsyncThunk/RTK Query. Keep sagas for
long-running tasks, complex orchestration, cancellation, debouncing.
Show effects (takeLatest, race, retry), channels, error handling.
Output: decision + saga skeleton.]],
    },

    RTKQueryMigration = {
      description = "Migrate suitable API calls to RTK Query.",
      system_prompt = [[You design RTK Query APIs with caching and invalidation.
Prefer simple endpoints and clear tag strategies.]],
      prompt = [[Identify API calls suitable for RTK Query, define endpoints,
caching, tags, invalidation, polling, streaming, SSR. Output: api slice
code + component usage + migration checklist.]],
    },

    KeycloakAuthFlow = {
      description = "Design solid front-end auth with Keycloak.",
      system_prompt = [[You design reliable auth flows: token lifecycle, guards,
silent SSO, refresh races, and resilient offline handling.]],
      prompt = [[Design front-end auth with Keycloak: login/refresh/logout, token
storage (memory), silent SSO, role-based route guards, per-request auth
headers, token refresh races, offline handling. Output: flow bullets +
hooks/middleware code.]],
    },

    CordovaBridgePatterns = {
      description = "Safe React–Cordova integration patterns.",
      system_prompt = [[You wrap Cordova plugins with typed TS APIs and robust
permissions, lifecycle, platform guards, and graceful fallbacks.]],
      prompt = [[Safe React–Cordova integration: wrap plugins with typed TS APIs,
permission checks, lifecycle handling, background tasks, platform
guards, graceful fallbacks, error mapping. Output: TS wrapper examples +
usage.]],
    },

    TestCoveragePlan = {
      description = "Balanced test coverage across Java and React.",
      system_prompt = [[You design a pragmatic testing strategy: unit, integration,
e2e, property-based, and contract tests with clear CI setup.]],
      prompt = [[Balanced tests across Java and React: unit/integration/e2e
distribution, golden-path scenarios, property-based tests for core
logic, contract tests for APIs, fixtures, CI setup. Output: checklist +
example tests.]],
    },

  },
})

-- ── Autocmd: hide line numbers in the chat buffer ────────────────────────────

vim.api.nvim_create_autocmd("FileType", {
  pattern  = "copilot-chat",
  callback = function()
    vim.opt_local.relativenumber = false
    vim.opt_local.number         = false
    -- <C-s> submits the prompt from insert mode
    vim.keymap.set("i", "<C-s>", "<CR>", { buffer = true, remap = true, desc = "Submit Prompt" })
  end,
})

-- ── Keymaps ───────────────────────────────────────────────────────────────────

local map = vim.keymap.set

map({ "n", "x" }, "<leader>ac", function() chat.toggle() end,
  { desc = "Toggle (CopilotChat)" })

map({ "n", "x" }, "<leader>ax", function() chat.reset() end,
  { desc = "Clear (CopilotChat)" })

map({ "n", "x" }, "<leader>aq", function()
  vim.ui.input({ prompt = "Quick Chat: " }, function(input)
    if input and input ~= "" then chat.ask(input) end
  end)
end, { desc = "Quick Chat (CopilotChat)" })

map({ "n", "x" }, "<leader>aP", function() chat.select_prompt() end,
  { desc = "Prompt Actions (CopilotChat)" })
