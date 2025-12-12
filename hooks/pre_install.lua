-- hooks/pre_install.lua
-- Returns download information for a specific version
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#preinstall-hook

function PLUGIN:PreInstall(ctx)
    local version = ctx.version

    -- pgFormatter is distributed as source code from GitHub
    -- We use the tarball API to get the source code for the specific version
    -- The version in ctx.version comes without 'v' prefix (e.g., "5.8")
    -- We need to add 'v' prefix for the tag reference
    local url = "https://api.github.com/repos/darold/pgFormatter/tarball/v" .. version

    -- Check for GITHUB_TOKEN to avoid rate limiting
    -- When authenticated, GitHub API allows 5000 requests/hour vs 60 unauthenticated
    local github_token = os.getenv("GITHUB_TOKEN")
    local headers = {}
    
    if github_token and github_token ~= "" then
        -- Use token authentication for higher rate limits
        headers["Authorization"] = "Bearer " .. github_token
    end

    return {
        version = version,
        url = url,
        headers = headers,
        note = "Downloading pgFormatter " .. version,
    }
end
