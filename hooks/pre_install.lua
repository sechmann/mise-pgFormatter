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

    return {
        version = version,
        url = url,
        note = "Downloading pgFormatter " .. version,
    }
end
