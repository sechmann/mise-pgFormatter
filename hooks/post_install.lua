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
