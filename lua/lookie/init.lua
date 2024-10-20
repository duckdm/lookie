local config = require('lookie.config')
local File = require('lookie.file')

local M = {}
LookieData = {}

function M.extmark_exists(extmark_data)

    for _, v in ipairs(LookieData) do
        if v.file_name == extmark_data.file_name and v.line_no == extmark_data.line_no then
            return true
        end
    end

    return false
end

function M.load_data(buf)

    local file_name = vim.api.nvim_buf_get_name(buf):gsub("/", "_")
    local file_data = File.read(file_name)

    if file_data then
        for _, mark in ipairs(file_data) do
            local parts = vim.fn.split(mark, ",")
            local extmark_data = {
                line_no = tonumber(parts[1]),
                type = parts[2],
                text = parts[3],
                pos = parts[4],
                file_name = file_name,
            }
            if not M.extmark_exists(extmark_data) then
                M.create_extmark(extmark_data)
            end
        end
    end
end

vim.api.nvim_create_autocmd("BufReadPost", {
    group = vim.api.nvim_create_augroup('lookie-buf-read-post', { clear = true }),
    callback = function(args)
        M.load_data(args.buf)
    end,
})

-- Handle buffers when entering them (covers some cases not caught by BufReadPost)
vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup('lookie-buf-win-enter', { clear = true }),
    callback = function(args)
        M.load_data(args.buf)
    end,
})

-- Handle buffers restored from a session when Neovim starts
vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup('lookie-vim-enter', { clear = true }),
    callback = function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) then
                M.load_data(buf)
            end
        end
    end,
})

vim.api.nvim_create_autocmd("SessionLoadPost", {
    group = vim.api.nvim_create_augroup('lookie-session-load-post', { clear = true }),
    callback = function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) then
                M.load_data(buf)
            end
        end
    end,
})

function M.setup()

    for _, v in pairs(config.types) do
        vim.cmd("highlight " .. v.hl .. " guifg=" .. v.fg .. " guibg=" .. v.bg)
    end

    vim.keymap.set("n", "<leader>M", function()

        local buf = vim.api.nvim_create_buf(false, true)
        local lines = {}

        for _, v in ipairs(LookieData) do
            table.insert(lines, v.file_name:gsub(vim.fn.getcwd(), "") .. ": " .. v.line_no .. " " .. v.text)
        end

        local width = 100
        local height = 20

        vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)

        local opts = {
            relative = 'win',
            width = width,
            height = height,
            col = vim.api.nvim_win_get_width(0) / 2 - (width / 2),
            row = vim.api.nvim_win_get_height(0) / 2 - (height / 2),
            anchor = 'NW',
            style = 'minimal',
            border = 'single',
        }
        vim.api.nvim_open_win(buf, true, opts)

        vim.keymap.set("n", "q", function() vim.cmd(":q") end, { buffer = buf, noremap = true })
        vim.keymap.set("n", "<CR>", function()
            local parts = vim.fn.split(vim.api.nvim_get_current_line(), ":")
            local line_no = tonumber(parts[1])
            vim.cmd(":q")
            vim.api.nvim_win_set_cursor(0, { line_no, 0 })
        end, { buffer = buf, noremap = true })

    end, { noremap = true })

    vim.keymap.set("n", "<leader>m", function()

        local extmarks = M.get_extmark()
        local cur_win = vim.api.nvim_get_current_win()
        local cur_buf = vim.api.nvim_get_current_buf()

        if extmarks then

            M.remove_extmarks(extmarks)

        else

            vim.ui.input({
                prompt = "Add a bookmark",
                cancelreturn = nil,
            }, function(input)
                if input then

                    local file_name = vim.api.nvim_buf_get_name(cur_buf)
                    local extmark_data = {
                        text = input,
                        line_no = vim.api.nvim_win_get_cursor(cur_win)[1],
                        type = "info",
                        pos = "eol",
                        file_name = file_name:gsub("/", "_"),
                    }

                    if input:sub(1, 1) == ">" then
                        extmark_data.text = input:sub(2)
                        extmark_data.pos = "right"
                    end

                    if input:sub(1, 1) == "<" then
                        extmark_data.text = input:sub(2)
                        extmark_data.pos = "overlay"
                    end

                    if input:find(":") then
                        local parts = vim.fn.split(input, ":")
                        extmark_data.text = parts[2]
                        extmark_data.type = parts[1]
                    end

                    M.create_extmark(extmark_data)
                    File.write(LookieData, file_name:gsub("/", "_"))
                end
            end)

        end

    end, { noremap = true })

end

function M.get_extmark()

    local cur_win = vim.api.nvim_get_current_win()
    local cur_buf = vim.api.nvim_get_current_buf()
    local line_no = vim.api.nvim_win_get_cursor(cur_win)[1] - 1
    local ns_id = vim.api.nvim_create_namespace("lookie")
    local win_width = vim.api.nvim_win_get_width(0)
    local extmarks = vim.api.nvim_buf_get_extmarks(cur_buf, ns_id, { line_no, 0 }, { line_no, win_width }, { details = true })

    if #extmarks > 0 then
        return extmarks
    end

    return nil
end

function M.remove_extmarks(extmarks)

    local cur_buf = vim.api.nvim_get_current_buf()
    local file_name = vim.api.nvim_buf_get_name(cur_buf):gsub("/", "_")

    for _, extmark in ipairs(extmarks) do

        local details = extmark[4]
        vim.api.nvim_buf_del_extmark(cur_buf, details.ns_id, extmark[1])

        for i, v in ipairs(LookieData) do
            if tonumber(v.line_no) - 1 == extmark[2] and file_name == v.file_name then
                table.remove(LookieData, i)
            end
        end
    end

    local data_count = 0

    for _, v in ipairs(LookieData) do
        if v.file_name == file_name then
            data_count = data_count + 1
        end
    end

    if data_count == 0 then
        File.empty(file_name)
        return nil
    end

    File.write(LookieData, file_name:gsub("/", "_"))
end

function M.create_extmark(extmark_data)

    local type = extmark_data.type and config.types[extmark_data.type] or config.types.info
    local cur_buf = vim.api.nvim_get_current_buf()
    local line_no = extmark_data.line_no - 1
    local text = extmark_data.text
    local hl_group = type.hl
    local icon = type.icon
    local default_text_post = extmark_data.pos or "eol"
    local ns_id = vim.api.nvim_create_namespace("lookie")
    local col_num = extmark_data.col or 0

    if extmark_data.pos and extmark_data.pos == "right" then
        default_text_post = "right_align"
    end

    local opts = {
        end_line = (line_no + 1),
        virt_text_pos = default_text_post,
        virt_text = { { " " .. icon .. " " .. text .. " ", hl_group } },
    }

    vim.api.nvim_buf_set_extmark(cur_buf, ns_id, line_no, col_num, opts)

    table.insert(LookieData, extmark_data)
end

return M
