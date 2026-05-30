---
name: Bug report
about: Something isn't working as expected
labels: bug
---

**MATLAB version:** R20XXx  
**Python version:** 3.XX  
**OS:** [Windows / macOS / Linux]  
**Wyvern version:** vX.X.X (`wyvern.version()` in MATLAB)

---

**What happened:**

<!-- Clear description of the bug. What did you expect? What did you get? -->

**Steps to reproduce:**

```matlab
% Paste the minimal MATLAB code that triggers the bug
wyvern.setup()
wyvern.agent.create("test", model="gpt-4o")
response = wyvern.agent.run("test", "hello")
```

**Expected behaviour:**

<!-- What should have happened instead? -->

**Error message:**

```
% Paste the full error from the MATLAB command window here
```

**Server log (last 20 lines):**

```
% Run wyvern.status() and paste the output here
```

---

**Additional context:**

<!-- Any other information that might help — e.g. proxy, VPN, corporate firewall, GPU/CPU -->
