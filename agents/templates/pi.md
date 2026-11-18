---
name: {{ harness.name }}
description: {{ description }}
model: {{ harness.model }}
{% if harness.inheritProjectContext is defined %}
inheritProjectContext: {{ harness.inheritProjectContext | lower }}
{% endif %}
tools: {{ harness.tools | join(", ") }}
extensions: {% for name in harness.extensions %}~/.pi/agent/extensions/{{ name }}{{ ", " if not loop.last }}{% endfor %}

---

{{ body }}
