---
description: {{ description }}
model: [{{ defaults.model | map("tojson") | join(", ") }}]
tools: [{{ harness.tools | join(", ") }}]
agents: []
---

{{ body }}
