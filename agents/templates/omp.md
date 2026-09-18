---
name: {{ harness.name }}
description: {{ description }}
thinking-level: {{ harness.effort }}
tools: {{ harness.tools | join(", ") }}
---

{{ body }}
