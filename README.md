# mise-pgFormatter

A [mise](https://mise.jdx.dev) plugin for [pgFormatter](https://github.com/darold/pgFormatter), a PostgreSQL SQL syntax beautifier.

## About pgFormatter

pgFormatter is a PostgreSQL SQL syntax beautifier that can work as a console program or as a CGI. It beautifies and formats SQL code, making it more readable and maintainable.

## Installation

### Prerequisites

- [mise](https://mise.jdx.dev) installed
- Perl (required by pgFormatter)

### Install the plugin

```bash
mise plugin install pg-format https://github.com/sechmann/mise-pgFormatter
```

### Install pgFormatter

```bash
# Install the latest version
mise install pg-format@latest

# Install a specific version
mise install pg-format@5.8

# Set as global default
mise use -g pg-format@latest
```

## Usage

Once installed via mise, you can use `pg_format` directly:

```bash
# Format a SQL file
pg_format input.sql

# Format with output to a file
pg_format input.sql -o output.sql

# Format from stdin
echo "SELECT * FROM users WHERE id=1;" | pg_format

# Show version
pg_format --version
```

For more options and usage details, see the [pgFormatter documentation](https://github.com/darold/pgFormatter#usage).

## Development

### Local Testing

1. Clone this repository
2. Link the plugin for local development:
```bash
mise plugin link --force pg-format .
mise install pg-format@5.8
```

3. Run tests:
```bash
mise run test
```

4. Run linting:
```bash
mise run lint
```

5. Run full CI suite:
```bash
mise run ci
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Related Links

- [pgFormatter GitHub Repository](https://github.com/darold/pgFormatter)
- [mise Documentation](https://mise.jdx.dev)
- [mise Plugin Publishing Guide](https://mise.jdx.dev/plugin-publishing.html)

## License

MIT