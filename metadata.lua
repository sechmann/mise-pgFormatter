-- metadata.lua
-- Plugin metadata and configuration
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#metadata-lua

PLUGIN = { -- luacheck: ignore
    -- Required: Tool name (lowercase, no spaces)
    name = "pg_format",

    -- Required: Plugin version (not the tool version)
    version = "1.0.0",

    -- Required: Brief description of the tool
    description = "A PostgreSQL SQL syntax beautifier that can work as a console program or as a CGI",

    -- Required: Plugin author/maintainer
    author = "sechmann",

    -- Optional: Repository URL for plugin updates
    updateUrl = "https://github.com/sechmann/mise-pgFormatter",

    -- Optional: Minimum mise runtime version required
    minRuntimeVersion = "0.2.0",

    -- Optional: Legacy version files this plugin can parse
    -- legacyFilenames = {
    --     ".pg_format-version",
    -- }
}
