local plugname = 'nvim-winpolicy'
-- wrap autocmd augroup crap that must be done every time in order to use autocmds.
local augroup = vim.api.nvim_create_augroup(plugname, { clear = true })
local autocmd = function(event, opts)
    if opts == nil then opts = {} end
    opts.group = augroup
    return vim.api.nvim_create_autocmd(event, opts)
end

----------------

local left_pad_config_default = {
    buffer = vim.api.nvim_create_buf(false, true),
    focusable = false, -- seems to do nothing
    minimum = 12,
    opts = {
        -- wrap = false,
        winfixwidth = true,
        winfixbuf = true,
    },
}

local leftpad_winid = nil
local leftpad_init = function(width, lpconfig)
    lpconfig = lpconfig or left_pad_config_default
    leftpad_winid = vim.api.nvim_open_win(
        lpconfig.buffer,
        false,        -- don't autofocus
        {
            win = -1, -- toplevel split
            vertical = true,
            split = 'left',
            width = width,
            style = 'minimal',
            focusable = lpconfig.focusable,
        })
    for k, v in pairs(lpconfig.opts) do
        vim.api.nvim_set_option_value(k, v, { scope = 'local', win = leftpad_winid })
    end
end
local leftpad_set_width = function(width)
    -- deal with the world changing beyond our awareness:
    if leftpad_winid ~= nil and not vim.api.nvim_win_is_valid(leftpad_winid) then
        leftpad_winid = nil
    end

    if width ~= nil and width > 0 then
        if leftpad_winid ~= nil then
            vim.api.nvim_win_set_width(leftpad_winid, width)
        else
            leftpad_init(width)
        end
    else
        if leftpad_winid ~= nil then
            vim.api.nvim_win_close(leftpad_winid, false)
            leftpad_winid = nil
        else
            -- not shown + no desire to be shown == nop
        end
    end
end



local PLEASANT_WIDTH = 80
-- TODO local MIN_WINDOW_WIDTH
local tick = function()
    local screen_width = vim.o.columns
    local leftpad_width = math.floor((screen_width - PLEASANT_WIDTH) / 2)
    if leftpad_width < left_pad_config_default.minimum then leftpad_width = nil end
    local ok, err = pcall(leftpad_set_width, leftpad_width)
    if not ok then
        -- without the schedule, error during window resize => rendering explodes.
        vim.schedule(function() vim.notify_once(plugname .. ': ' .. err, vim.log.levels.WARN) end)
    end
end

autocmd("VimResized", { callback = tick })
-- autocmds don't fire on startup:
vim.schedule(tick) -- lack of schedule => main window is in a weird state and
-- random options will appear broken.

-- if pad window is only window, then quit. *extremely annoying* without this.
-- vim doc says QuitPre or "kinda maybe ExitPre" (paraphrased) is exactly for
-- this usecase.
autocmd("QuitPre", {
    callback = function()
        if leftpad_winid == nil then return end
        -- list_wins() will also include the win that's in the process of
        -- quitting...and these are ordered lists and every simple data thing
        -- in lua is obnoxious.
        local wids = vim.api.nvim_list_wins()
        -- can only check # entries while it's an ordered list.
        if #wids == 2 then
            -- ASSuming the second entry is the currently quitting window id.
            local dumb = false
            for _, v in ipairs(wids) do
                dumb = dumb or v == leftpad_winid
            end
            if dumb then
                vim.api.nvim_win_close(leftpad_winid, true)
                leftpad_winid = nil
            end
        end
    end
})
