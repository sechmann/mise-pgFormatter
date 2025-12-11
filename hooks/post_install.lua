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
    local version = ctx.version

    -- mise downloads the tarball but doesn't extract it automatically
    -- The downloaded file is named "v{version}" based on the GitHub API tag reference
    -- (e.g., "v5.8" for version 5.8, matching the tag format in pre_install.lua)
    local tarball_path = path .. "/v" .. version

    -- Check if the tarball file exists and extract it
    if path_exists(tarball_path) then
        -- Extract the tarball
        local extract_cmd = "tar -xzf " .. shell_escape(tarball_path) .. " -C " .. shell_escape(path)
        local extract_result = os.execute(extract_cmd)
        if extract_result ~= 0 then
            error("Failed to extract tarball: " .. tarball_path)
        end

        -- Remove the tarball after successful extraction
        local rm_result = os.execute("rm " .. shell_escape(tarball_path))
        if rm_result ~= 0 then
            error("Failed to remove tarball after extraction: " .. tarball_path)
        end
    end

    -- Now find the extracted directory
    -- GitHub tarballs extract to a directory like darold-pgFormatter-<sha>
    local find_cmd = "find " .. shell_escape(path) .. " -maxdepth 1 -type d -name 'darold-pgFormatter-*' | head -1"
    local handle = io.popen(find_cmd)
    local extracted_dir = handle:read("*l")
    handle:close()

    if not extracted_dir or extracted_dir == "" then
        -- Try to list what's actually in the directory for debugging
        local ls_handle = io.popen("ls -la " .. shell_escape(path))
        local ls_output = ls_handle:read("*a")
        ls_handle:close()
        error("Failed to find extracted pgFormatter directory. Contents of " .. path .. ":\n" .. ls_output)
    end

    local source_dir = extracted_dir

    -- Create bin directory
    os.execute("mkdir -p " .. shell_escape(path .. "/bin"))

    -- Move pg_format script to bin/
    local move_result = os.execute("mv " .. shell_escape(source_dir .. "/pg_format") .. " " .. shell_escape(path .. "/bin/pg_format"))
    if move_result ~= 0 then
        error("Failed to move pg_format script to bin")
    end

    -- Move lib directory (contains Perl modules needed by pg_format)
    local move_lib_result = os.execute("mv " .. shell_escape(source_dir .. "/lib") .. " " .. shell_escape(path .. "/lib"))
    if move_lib_result ~= 0 then
        error("Failed to move lib directory")
    end

    -- Make pg_format executable
    os.execute("chmod +x " .. shell_escape(path .. "/bin/pg_format"))

    -- Clean up the extracted directory (always needed after extraction)
    os.execute("rm -rf " .. shell_escape(source_dir))

    -- Verify installation works
    local testResult = os.execute(shell_escape(path .. "/bin/pg_format") .. " --version > /dev/null 2>&1")
    if testResult ~= 0 then
        error("pg_format installation appears to be broken")
    end
end
