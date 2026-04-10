local M = {}

---@param path1 string
---@param path2 string
---@return integer
local function common_prefix_score(path1, path2)
  -- Normalize and split paths
  local function split(path)
    local out = {}
    for seg in string.gmatch(path, "[^/]+") do
      table.insert(out, seg)
    end
    return out
  end

  local segments1 = split(path1)
  local segments2 = split(path2)
  local score = 0
  for i = 1, math.min(#segments1, #segments2) do
    if segments1[i] == segments2[i] then
      score = score + 1
    else
      break
    end
  end
  return score
end

local REMOTE_SERVER = {}

---Connect to a remote `opencode` server by prompting for host and port.
---@return Promise<opencode.server.Server>
function M.connect_remote()
  local Promise = require("opencode.promise")

  return Promise.new(function(resolve, reject)
    vim.ui.input({
      prompt = "Host (e.g. 192.168.1.100): ",
      default = "localhost",
    }, function(host)
      if not host or host == "" then
        reject("Cancelled")
        return
      end

      vim.ui.input({
        prompt = "Port: ",
      }, function(port_str)
        if not port_str or port_str == "" then
          reject("Cancelled")
          return
        end

        local port = tonumber(port_str)
        if not port then
          reject("Invalid port: " .. port_str)
          return
        end

        require("opencode.server")
          .new(host, port)
          :next(function(server)
            require("opencode.events").connect(server)
            resolve(server)
          end)
          :catch(reject)
      end)
    end)
  end)
end

---Select an `opencode` server from a given list.
---
---@param servers opencode.server.Server[]
---@return Promise<opencode.server.Server>
function M.select_server(servers)
  local Promise = require("opencode.promise")
  local nvim_cwd = vim.fn.getcwd()

  -- Sort servers by common prefix overlap with Neovim's CWD
  table.sort(servers, function(a, b)
    local score_a = common_prefix_score(nvim_cwd, a.cwd)
    local score_b = common_prefix_score(nvim_cwd, b.cwd)
    if score_a == score_b then
      return a.cwd < b.cwd -- fallback: alphabetical
    end
    return score_a > score_b
  end)

  local items = vim.list_extend(servers, { REMOTE_SERVER })

  local picker_opts = {
    prompt = "Select an `opencode` server:",
    format_item = function(item) ---@param item opencode.server.Server|typeof(REMOTE_SERVER)
      if item == REMOTE_SERVER then
        return "Connect to remote server..."
      end
      return string.format(
        "%s | %s:%d",
        item.title or "<No sessions>",
        item.host == "localhost" and item.cwd or item.host .. ":" .. item.port,
        item.port
      )
    end,
    snacks = {
      layout = {
        hidden = { "preview" },
      },
    },
  }
  picker_opts = vim.tbl_deep_extend("keep", picker_opts, require("opencode.config").opts.select or {})

  return Promise.select(items, picker_opts):next(function(item)
    if item == REMOTE_SERVER then
      return connect_remote()
    end
    return item
  end)
end

return M
