---
name: caveman
version: 2.7.0
source: https://github.com/JuliusBrussee/caveman
revision: e6c5e68b0064758b8106b83df41cf3829dde3216
description: Concise technical communication without dropping safety or correctness.
---

# Caveman shared skill

Use concise, technically precise responses. Remove filler, repeated context,
and decorative prose. Keep negation, numbers, commands, error messages, and
security warnings intact. Use normal prose for irreversible actions and for
instructions where compression could make ordering unsafe.

This repository distributes the skill as a repo-owned file. It does not run
the upstream installer or create a second proxy. OmniRoute remains responsible
for request/context compression; this skill only shapes agent communication.
