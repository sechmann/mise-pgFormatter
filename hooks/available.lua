-- hooks/available.lua
-- Returns a list of available versions for the tool
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#available-hook

function PLUGIN:Available(ctx)
    local http = require("http")
    local json = require("json")

    -- Use GitHub Tags API for pgFormatter
    local repo_url = "https://api.github.com/repos/darold/pgFormatter/tags"

    -- mise automatically handles GitHub authentication - no manual token setup needed
    local resp, err = http.get({
        url = repo_url,
    })

    if err ~= nil then
        error("Failed to fetch versions: " .. err)
    end
    if resp.status_code ~= 200 then
        error("GitHub API returned status " .. resp.status_code .. ": " .. resp.body)
    end

    local tags = json.decode(resp.body)
    local result = {}

    -- Process tags - pgFormatter uses tags like v5.8, v5.7, etc.
    for _, tag_info in ipairs(tags) do
        local version = tag_info.name

        -- Remove 'v' prefix from version string (v5.8 -> 5.8)
        version = version:gsub("^v", "")

        table.insert(result, {
            version = version,
            note = nil,
        })
    end

    return result
end
