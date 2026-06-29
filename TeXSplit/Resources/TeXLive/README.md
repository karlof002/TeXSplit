Place an embedded TeX Live runtime here for distributor builds.

Supported layouts:

- `TeXLive/bin/universal-darwin/pdflatex`
- `TeXLive/2026basic/bin/universal-darwin/pdflatex`
- `TeXLive/2026/bin/universal-darwin/pdflatex`

TeXSplit checks these bundled paths before looking for a system-wide TeX
installation. Do not commit a full TeX distribution unless the repository is
intended to carry large binary/runtime assets and the license obligations are
handled.
