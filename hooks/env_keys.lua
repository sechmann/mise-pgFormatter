-- hooks/env_keys.lua
-- Configures environment variables for the installed tool
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#envkeys-hook

function PLUGIN:EnvKeys(ctx)
    local mainPath = ctx.path

    -- pgFormatter is a Perl script that needs access to its lib/ directory
    -- We need to add both the bin/ to PATH and lib/ to PERL5LIB
    return {
        {
            key = "PATH",
            value = mainPath .. "/bin",
        },
        {
            key = "PERL5LIB",
            value = mainPath .. "/lib",
        },
    }
end
