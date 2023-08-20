-- TODO disable overlay when on the message line

local M = {}

function M.setup(config)
  M.ns = vim.api.nvim_create_namespace('notmuch')
  -- TODO toggle state
  vim.api.nvim_set_hl(0, 'EmailOneLine', { fg = '#ffffff', bg = '#0000FF' })
end

-- https://stackoverflow.com/questions/4105012/convert-a-string-date-to-a-timestamp
function M.fromTimeString(s)
end

function M.queryById(msgid)
  local command = 'notmuch show --format=json --entire-thread=false id:'..msgid
  local handle = io.popen(command)
  local result = {}
  if handle
    then
      result = vim.json.decode(handle:read('*a'))
      handle:close()
    end
  return result
end

function M.openNeomutt()
  -- 1. Be over a Message-ID line
  -- 2. Execute: notmuch-mutt search id:'the-id'
  -- 3. Execute: neomutt -f ~/.cache/notmuch/mutt/results/
  -- 4. Profit ;-)
end

function M.replaceMessageId()
  local lines = vim.api.nvim_buf_get_lines(0,0,-1, false)
  for row, line in pairs(lines)
    do
      -- Uses lua patterns, careful these are not regexes
      -- https://neovim.io/doc/user/luaref.html#lua-pattern
      -- https://www.lua.org/pil/20.2.html
      local from, how, idstr, to = line:match('()%`%`(%a*)%s*Message%-ID%:%s*%<([^%>]+)%>%s*%`%`()')
      if from
      then
        local msg = M.queryById('\''..idstr..'\'')
        local msgline = ''
        local mail1 = nil
        local len = 0
        if (msg and msg[1] and msg[1][1] and msg[1][1][1])
          then
            mail1 = msg[1][1][1]
            len = math.max(0, to-from+1)
            -- Date: Tue, 18 Nov 2014 15:57:11 +0000
            local date = vim.fn.strptime('%a, %d %b %Y %T %z', mail1.headers.Date)
            local strdate = vim.fn.strftime('%F %T', date)
            msgline = string.format('%s  %s', strdate, mail1.headers.Subject)
          end
        local opts = {
          virt_text = {{string.format('%-'..len..'.'..len..'s',msgline), 'EmailOneLine'}},
          virt_text_pos = 'overlay'
        }
        local opts = {
          virt_text = { {string.format('%-'..len..'s', msgline), 'EmailOneLine'} },
          virt_text_pos = 'overlay'
        }
        -- https://jdhao.github.io/2021/09/09/nvim_use_virtual_text/
        --
        -- TODO store extmark, to allow to toggle them on or off! (Or just delete all of them in the
        -- namespace and recreate if necessary.
        vim.api.nvim_buf_set_extmark(0, M.ns, row-1, from-1, opts)
      end
    end
end

return M

