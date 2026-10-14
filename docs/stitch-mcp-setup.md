# Google Stitch MCP

DealFinder's project-scoped Codex configuration is in `.codex/config.toml`.
It connects directly to Google's remote server at
`https://stitch.googleapis.com/mcp`; no npm proxy is required.

Authentication uses the `X-Goog-Api-Key` header, populated from the
`STITCH_API_KEY` environment variable. The API key is stored in the current
developer's Windows user environment, outside this repository. Do not put
the key in source files or commit it.

## Start using it

1. Fully close and reopen Codex or your IDE so it inherits the updated Windows
   user environment.
2. Open this trusted DealFinder workspace and start a new session.
3. Check the MCP server list for `stitch` (or run `codex mcp get stitch`).
4. Ask Codex to list your Stitch projects and select the existing DealFinder
   project before retrieving or changing designs.

For another developer, set `STITCH_API_KEY` using their own Stitch API key,
then restart the application. The configuration contains only the variable
name, not a credential.

## Verification

Setup verified authenticated MCP initialization and `tools/list` successfully,
returning 15 tools. No projects or screens were created or modified by this
verification. Availability inside Codex must be checked in a fresh session
after restarting the application.

The MCP integration is a development tool; it does not add a Stitch dependency
to the Flutter app, website, or backend.

References:
- [Google Stitch MCP setup](https://stitch.withgoogle.com/docs/mcp/setup)
- [Google's Stitch extension configuration](https://github.com/gemini-cli-extensions/stitch/blob/main/gemini-extension.json)
- [Codex MCP configuration](https://developers.openai.com/codex/mcp)
