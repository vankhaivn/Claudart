---
name: cda-upgrade
description: Update this project's CLAUDART installation from upstream main through INTEGRATE.md, preserving project-specific content. Use only when the user asks for it, by command or in words.
---

# Upgrade CLAUDART

Read `https://raw.githubusercontent.com/vankhaivn/Claudart/main/INTEGRATE.md` and follow it to update CLAUDART in this project. That protocol owns diagnosis, the upstream source, the plan and its approval, the writes, `.claudart/VERSION` and verification; this skill adds only the following.

- Begin with the protocol's diagnosis, not `/cda-start`. The upgrade needs the installed layers and their customizations, not current work.
- Leave `.claudart/HANDOFF.md` untouched: do not read, consume or delete it.
- If upstream cannot be reached, stop and report it. Do not update from memory or from the installed files.
