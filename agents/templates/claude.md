---
name: {{ harness.name }}
description: {{ description }}
model: {{ harness.model }}
effort: {{ harness.effort }}
tools: {{ harness.tools | join(", ") }}
---

{{ body }}
