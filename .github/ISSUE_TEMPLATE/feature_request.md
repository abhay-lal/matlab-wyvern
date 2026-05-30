---
name: Feature request
about: Suggest something new for Wyvern
labels: enhancement
---

**What problem does this solve?**

<!-- Describe the use case. What are you trying to accomplish that Wyvern doesn't currently support? -->

**Proposed MATLAB API:**

```matlab
% What would the function call look like from MATLAB?
result = wyvern.XXX.YYY("myId", someInput, optionName=optionValue)
```

**Which layer does this touch?**

- [ ] MATLAB toolbox (`toolbox/+wyvern/`)
- [ ] Python server (`server/`)
- [ ] Both

**Does this overlap with `llms-with-matlab`?**

<!-- Wyvern intentionally avoids re-implementing features in the official MathWorks add-on.
     Please check https://github.com/matlab-deep-learning/llms-with-matlab first. -->

- [ ] I have checked and this is NOT already covered by `llms-with-matlab`

**Are you willing to implement this?**

- [ ] Yes, I can submit a PR
- [ ] No, I'm just suggesting

**Additional context:**

<!-- Links, references, or examples from LangChain/HuggingFace docs that are relevant -->
