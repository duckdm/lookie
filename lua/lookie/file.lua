local File = {}

if type(_LookieConfig.data_path) == "function" then
    File.data_path = _LookieConfig.data_path()
elseif _LookieConfig.data_path == "cwd" then
    File.data_path = vim.fn.getcwd() .. "/.lookie/"
else
    File.data_path = _LookieConfig.data_path
end

File.empty = function(file_name)

    local cache_path = File.data_path
    local full_path = cache_path .. file_name

    if not vim.fn.isdirectory(cache_path) then
        return
    end

    if tonumber(vim.fn.filereadable(full_path)) ~= 0 then
        vim.fn.delete(full_path)
    end

end

File.write = function(marks, file_name)

    local file_data = {}

    for _, data in ipairs(marks) do
        if not data.file_name then
            return
        end

        if data.file_name == file_name then

            local cache_path = File.data_path
            local full_path = cache_path .. file_name:gsub("/", "_")

            vim.fn.system(table.concat({ "mkdir -p", cache_path, }, " "))
            vim.fn.system(table.concat({ "touch", full_path, }, " "))

            local csv_line = data.line_no .. "," ..
                data.type .. "," ..
                data.text .. "," ..
                data.pos .. "," ..
                data._file_name
            table.insert(file_data, csv_line)

            vim.fn.writefile(file_data, full_path, "s")

        end
    end
end

function File.read(file_name)

    local cache_path = File.data_path
    local full_path = cache_path .. file_name

    if not vim.fn.isdirectory(cache_path) then
        return nil
    end

    if tonumber(vim.fn.filereadable(full_path)) ~= 0 then
        return vim.fn.readfile(full_path)
    end

    return nil

end

return File
