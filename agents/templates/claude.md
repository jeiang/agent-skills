---
name: {{ harness.name }}
description: {{ description }}
model: {{ harness.model }}
effort: {{ harness.effort }}
tools: {{ harness.tools | join(", ") }}
{% if harness.get("omit_claude_md") %}
omitClaudeMd: true
{% endif %}
---

{{ body }}
