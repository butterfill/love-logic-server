Implement Phantom Render for slides (Nunjucks pre-pass, mixins, Pug compile, Cheerio traversal), then add      tests for slide segments and media extraction at the segment level.

Extend manifest to index essay questions and expand indices (byBibKey, byUuid), plus build the cross-reference graph more fully.

Move bibliography/glossary propagation fully into loadConfig with an explicit design for precedence.

Write additional tests for refs.inbound, bibKey indexing, and validation warnings