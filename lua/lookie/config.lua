return {
    ---@type string|"cwd"|function(): string Data location. If set to "cwd" it will save data to current working directory ([cwd]/.lookie/[file_name])
    data_path = vim.fn.stdpath("cache") .. "/duckdm/lookie/",

    ---@type table Marker typess
    types = {
        info = {
            hl = "LookieInfo",
            icon = "",
            fg = "#00aaff",
            bg = "#003366",
        },
        danger = {
            hl = "LookieDanger",
            icon = "",
            fg = "#ff0000",
            bg = "#330000",
        },
        warning = {
            hl = "LookieWarning",
            icon = "",
            fg = "#ffaa00",
            bg = "#663300",
        },
        success = {
            hl = "LookieSuccess",
            icon = "",
            fg = "#00ff00",
            bg = "#003300",
        },
    },
}
