-- hooks/post_install.lua
-- Performs additional setup after installation
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#postinstall-hook

-- Helper function to escape shell arguments
local function shell_escape(arg)
    -- Escape single quotes by replacing ' with '\''
    return "'" .. arg:gsub("'", "'\\''") .. "'"
end

-- Helper function to check if a file or directory exists
local function path_exists(filepath)
    return os.execute("test -e " .. shell_escape(filepath)) == 0
end

function PLUGIN:PostInstall(ctx)
    local sdkInfo = ctx.sdkInfo[PLUGIN.name]
    local path = sdkInfo.path

    -- pgFormatter is extracted from GitHub tarball
    -- mise may extract it in different ways:
    -- 1. With wrapper directory: path/darold-pgFormatter-<sha>/pg_format
    -- 2. Without wrapper (stripped): path/pg_format
    -- We need to handle both cases

    -- First, check if files are already in the root (mise stripped the wrapper)
    local pg_format_in_root = path_exists(path .. "/pg_format")
    local lib_in_root = path_exists(path .. "/lib")

    local source_dir = path
    local needs_cleanup = false

    -- If not in root, look for the wrapper directory
    -- Both files must be missing to search for wrapper (using AND logic)
    if not pg_format_in_root and not lib_in_root then
        local find_cmd = "find " .. shell_escape(path) .. " -maxdepth 1 -type d -name 'darold-pgFormatter-*' | head -1"
        local handle = io.popen(find_cmd)
        local extracted_dir = handle:read("*l")
        handle:close()

        if extracted_dir and extracted_dir ~= "" then
            source_dir = extracted_dir
            needs_cleanup = true
        else
            -- Try to list what's actually in the directory for debugging
            local ls_handle = io.popen("ls -la " .. shell_escape(path))
            local ls_output = ls_handle:read("*a")
            ls_handle:close()
            error("Failed to find extracted pgFormatter directory. Contents of " .. path .. ":\n" .. ls_output)
        end
    end

    -- Create bin directory
    os.execute("mkdir -p " .. shell_escape(path .. "/bin"))

    -- Move or copy pg_format script to bin/
    if source_dir ~= path then
        local move_result = os.execute("mv " .. shell_escape(source_dir .. "/pg_format") .. " " .. shell_escape(path .. "/bin/pg_format"))
        if move_result ~= 0 then
            error("Failed to move pg_format script to bin")
        end

        -- Move lib directory (contains Perl modules needed by pg_format)
        local move_lib_result = os.execute("mv " .. shell_escape(source_dir .. "/lib") .. " " .. shell_escape(path .. "/lib"))
        if move_lib_result ~= 0 then
            error("Failed to move lib directory")
        end
    else
        -- Files are already in root, just move pg_format to bin/
        local move_result = os.execute("mv " .. shell_escape(path .. "/pg_format") .. " " .. shell_escape(path .. "/bin/pg_format"))
        if move_result ~= 0 then
            error("Failed to move pg_format script to bin")
        end
        -- lib is already in the right place
    end

    -- Make pg_format executable
    os.execute("chmod +x " .. shell_escape(path .. "/bin/pg_format"))

    -- Clean up the extracted directory if needed
    if needs_cleanup then
        os.execute("rm -rf " .. shell_escape(source_dir))
    end

    -- Verify installation works
    local testResult = os.execute(shell_escape(path .. "/bin/pg_format") .. " --version > /dev/null 2>&1")
    if testResult ~= 0 then
        error("pg_format installation appears to be broken")
    end
end
