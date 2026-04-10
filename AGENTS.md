# AGENTS.md

## Dev Commands

```bash
# Format check (CI also runs this)
stylua --check .

# Type/diagnostic check
lua-language-server --configpath .luarc.ci.json --check=.
```

No test suite — CI only runs linting (stylua + lua-ls).

## Style

- Column width: 120
- Indent: 2 spaces
- Quote style: `AutoPreferDouble`
- No call parentheses required
- LuaJIT runtime (Neovim)
- See `.stylua.toml`

## Architecture

- Single Lua package under `lua/opencode/`
- Key modules: `config`, `server`, `events`, `terminal`, `context`, `promise`
- `api/`: prompt, command, operator
- `ui/`: ask, select, select_session, select_server
- `server/process/`: platform-specific process discovery (unix/windows)
- `integrations/pickers/`: snacks.nvim picker integration

## Config Pattern

Plugin options go in `vim.g.opencode_opts` (global, not local). See `lua/opencode/config.lua` for all options and defaults.

`vim.o.autoread = true` required when `opts.events.reload = true`.

## Dependencies

- **Optional**: snacks.nvim (enhances `ask()` and `select()`)
- **Optional**: blink.cmp (completion in `ask()` input)
- **Runtime required**: `opencode` binary in `$PATH`, `curl`
- **Process discovery (Unix)**: `pgrep`, `lsof` (or set `server.port` explicitly)

## CI

- stylua check on push/PR to main
- lua-ls diagnostics on push/PR to main
- Release-please for versioning (simple type, minor bump pre-major)

## Health Check

Run `:checkhealth opencode` in Neovim to verify setup.
