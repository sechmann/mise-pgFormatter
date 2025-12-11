-- hooks/post_install.lua
-- Performs additional setup after installation
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#postinstall-hook

-- Helper function to escape shell arguments
local function shell_escape(arg)
    -- Escape single quotes by replacing ' with '\''
    return "'" .. arg:gsub("'", "'\\''") .. "'"
end

function PLUGIN:PostInstall(ctx)
    local sdkInfo = ctx.sdkInfo[PLUGIN.name]
    local path = sdkInfo.path

    -- pgFormatter is extracted from GitHub tarball
    -- The tarball extracts to a directory like darold-pgFormatter-<sha>/
    -- We need to find this directory and set up the structure

    -- Create bin directory
    os.execute("mkdir -p " .. shell_escape(path .. "/bin"))

    -- Find the extracted directory (will be darold-pgFormatter-*)
    local find_cmd = "find " .. shell_escape(path) .. " -maxdepth 1 -type d -name 'darold-pgFormatter-*' | head -1"
    local handle = io.popen(find_cmd)
    local extracted_dir = handle:read("*l")
    handle:close()

    if not extracted_dir or extracted_dir == "" then
        error("Failed to find extracted pgFormatter directory")
    end

    -- Move pg_format script to bin/
    local move_result = os.execute("mv " .. shell_escape(extracted_dir .. "/pg_format") .. " " .. shell_escape(path .. "/bin/pg_format"))
    if move_result ~= 0 then
        error("Failed to move pg_format script")
    end

    -- Make pg_format executable
    os.execute("chmod +x " .. shell_escape(path .. "/bin/pg_format"))

    -- Move lib directory (contains Perl modules needed by pg_format)
    local move_lib_result = os.execute("mv " .. shell_escape(extracted_dir .. "/lib") .. " " .. shell_escape(path .. "/lib"))
    if move_lib_result ~= 0 then
        error("Failed to move lib directory")
    end

    -- Clean up the extracted directory
    os.execute("rm -rf " .. shell_escape(extracted_dir))

    -- Verify installation works
    local testResult = os.execute(shell_escape(path .. "/bin/pg_format") .. " --version > /dev/null 2>&1")
    if testResult ~= 0 then
        error("pg_format installation appears to be broken")
    end
end
