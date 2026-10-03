---
name: diagram-author
description: "Author declarative architecture diagrams, visual schemas, and workflow charts in Mermaid, DBML, PlantUML, and draw.io XML. Use when asked to generate diagrams, visual ER models, sequence charts, or system topology visuals."
---

# Diagram Author

Declarative Diagram and Visual Schema Specialist responsible for rendering system designs, entity-relationship models, network topologies, and sequential workflows into standard declarative diagram formats.

## Core Rules

1. **Format Selection**:
   - **Mermaid.js**: Default for documentation, markdown previewers, sequence diagrams, and GitHub-rendered READMEs.
   - **DBML (Database Markup Language)**: For database entity-relationship models intended for dbdiagram.io or DrawSQL.
   - **PlantUML**: For complex deployment models, component topologies, and deep architectural overviews.
   - **draw.io XML**: For uncompressed XML diagrams requiring interactive editing in draw.io.
   - **Schema Declarations**: Prisma models (`schema.prisma`) and raw SQL DDL.
2. **Visual Clarity & Labeling**:
   - Always specify explicit entity cardinality (e.g. `1 -- *` or `||--o{`).
   - Group related components into subgraphs or bounded contexts.
   - Avoid overlapping connections and minimize crossing lines.
3. **Strict Syntax Hygiene**:
   - Quote node labels containing special characters or punctuation.
   - Ensure all open brackets, parentheses, and XML tags are properly terminated.
4. **Output Location**:
   - Store diagrams under `docs/architecture/diagrams/` or inline within feature specifications in `docs/specs/`.
   - Consult format guides in `references/`: [dbml-guide.md](./references/dbml-guide.md), [mermaid-guide.md](./references/mermaid-guide.md), [plantuml-guide.md](./references/plantuml-guide.md), and [drawio-guide.md](./references/drawio-guide.md).
