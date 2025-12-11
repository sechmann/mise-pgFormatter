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

-- Helper function to find the extracted pgFormatter directory
local function find_extracted_dir(path)
    local find_cmd = "find " .. shell_escape(path) .. " -maxdepth 1 -type d -name 'darold-pgFormatter-*' | head -1"
    local handle = io.popen(find_cmd)
    local extracted_dir = handle:read("*l")
    handle:close()
    
    if extracted_dir and extracted_dir ~= "" then
        return extracted_dir
    end
    return nil
end

function PLUGIN:PostInstall(ctx)
    local sdkInfo = ctx.sdkInfo[PLUGIN.name]
    local path = sdkInfo.path
    local version = sdkInfo.version

    -- Despite mise saying "Extracting...", it only moves the tarball file to the install directory
    -- We need to manually extract it here
    local tarball_path = path .. "/v" .. version

    -- Check if tarball file exists (it should)
    if not path_exists(tarball_path) then
        -- Maybe it's already been extracted? Check for extracted directory
        local extracted_dir = find_extracted_dir(path)
        
        if not extracted_dir then
            local ls_handle = io.popen("ls -la " .. shell_escape(path))
            local ls_output = ls_handle:read("*a")
            ls_handle:close()
            error("Neither tarball nor extracted directory found. Contents of " .. path .. ":\n" .. ls_output)
        end
    else
        -- Extract the tarball
        local extract_result = os.execute("tar -xzf " .. shell_escape(tarball_path) .. " -C " .. shell_escape(path))
        if extract_result ~= 0 then
            error("Failed to extract tarball: " .. tarball_path)
        end

        -- Remove the tarball after extraction (best effort, not critical if it fails)
        os.execute("rm " .. shell_escape(tarball_path))
    end

    -- Now find the extracted directory (darold-pgFormatter-*)
    local extracted_dir = find_extracted_dir(path)

    if not extracted_dir then
        local ls_handle = io.popen("ls -la " .. shell_escape(path))
        local ls_output = ls_handle:read("*a")
        ls_handle:close()
        error("Failed to find extracted pgFormatter directory after extraction. Contents of " .. path .. ":\n" .. ls_output)
    end

    local source_dir = extracted_dir

    -- Create bin directory
    os.execute("mkdir -p " .. shell_escape(path .. "/bin"))

    -- Move pg_format script to bin/ with a different name
    local move_result = os.execute("mv " .. shell_escape(source_dir .. "/pg_format") .. " " .. shell_escape(path .. "/bin/pg_format.pl"))
    if move_result ~= 0 then
        error("Failed to move pg_format script to bin")
    end

    -- Move lib directory (contains Perl modules needed by pg_format)
    local move_lib_result = os.execute("mv " .. shell_escape(source_dir .. "/lib") .. " " .. shell_escape(path .. "/lib"))
    if move_lib_result ~= 0 then
        error("Failed to move lib directory")
    end

    -- Create a wrapper script that sets PERL5LIB before running pg_format
    local wrapper_content = [[#!/bin/sh
# Wrapper script for pg_format that sets up the Perl library path
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
export PERL5LIB="$SCRIPT_DIR/lib:$PERL5LIB"
exec "$SCRIPT_DIR/bin/pg_format.pl" "$@"
]]
    local wrapper_file = io.open(path .. "/bin/pg_format", "w")
    if not wrapper_file then
        error("Failed to create wrapper script")
    end
    wrapper_file:write(wrapper_content)
    wrapper_file:close()

    -- Make both scripts executable
    os.execute("chmod +x " .. shell_escape(path .. "/bin/pg_format.pl"))
    os.execute("chmod +x " .. shell_escape(path .. "/bin/pg_format"))

    -- Clean up the extracted directory (always needed after extraction)
    os.execute("rm -rf " .. shell_escape(source_dir))

    -- Verify installation works
    local test_handle = io.popen(shell_escape(path .. "/bin/pg_format") .. " --version 2>&1")
    local test_output = test_handle:read("*a")
    local success = test_handle:close()
    
    if not success then
        error("pg_format installation appears to be broken. Test output:\n" .. test_output)
    end
end
