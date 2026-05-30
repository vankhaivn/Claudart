<div align="center">
  <h1>CLAUDART</h1>
  <p><strong>Lớp vận hành bằng markdown cho Claude Code &amp; Codex CLI — memory, kế hoạch và review, tất cả nằm trong git.</strong></p>

  <p>
    <a href="https://github.com/vankhaivn/Claudart/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/vankhaivn/Claudart?style=for-the-badge&color=orange"></a>
    <img alt="Pure Markdown" src="https://img.shields.io/badge/memory-pure_markdown-blue?style=for-the-badge">
    <img alt="Offline-friendly" src="https://img.shields.io/badge/works-offline-green?style=for-the-badge">
    <a href="https://github.com/vankhaivn/Claudart/issues"><img alt="Issues" src="https://img.shields.io/github/issues/vankhaivn/Claudart?style=for-the-badge&color=blue"></a>
  </p>
</div>

---

> **Vấn đề.** Khi làm việc với coding agent, trạng thái dự án bị rò rỉ khắp nơi: mỗi session mới bắt đầu trong mù mờ, kế hoạch chết trong chat, cùng một quyết định bị tái khám phá hết tuần này sang tuần khác, còn `CLAUDE.md` / `AGENTS.md` thì phình ra thành một bồn đốt token mà không ai còn tin.

CLAUDART là một bộ nhỏ gồm slash command và mô hình memory nhiều tầng bằng markdown, biến cách dùng agent rời rạc thành một workflow có thể lặp lại. Mọi thứ là markdown thuần trong `.claude/` và `.codex/` — version bằng git, review được trong PR, đọc được offline. Không vector DB. Không daemon. Không cloud account.

## Cài đặt

```bash
# Claude Code layer (mặc định)
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --claude
```

```bash
# Codex layer
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --codex
```

```bash
# Cả hai layer
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --both
```

```bash
# Ghi đè file đang có
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --force
```

### Hoặc cài bằng chính agent của bạn

`install.sh` copy mới toàn bộ — rất hợp với project sạch, nhưng có thể ghi đè setup hiện có và không cho bạn biết upstream đã thay đổi gì khi upgrade. Nếu bạn **đã có agent/workflow riêng**, hoặc đang **nâng cấp từ một bản CLAUDART cũ**, hãy paste prompt này vào Claude Code hoặc Codex session. Agent sẽ đọc repo, diff với project của bạn, rồi merge có kiểm soát — hỏi trước khi đụng tới bất kỳ thứ gì bạn đã custom:

> Read https://raw.githubusercontent.com/vankhaivn/Claudart/main/INTEGRATE.md and follow it to integrate CLAUDART into this project. Ask me before touching anything I've customized.

## CLAUDART giải quyết gì

| Nỗi đau khi làm việc với coding agent                          | Cách CLAUDART xử lý                                                                                                                      |
| -------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Session nào cũng bắt đầu mù mờ                                 | `/start` đọc `CONTEXT.md` + task đang active + 3 commit gần nhất — có định hướng ngay                                                    |
| Kế hoạch mất khi đóng session                                  | `/plan <task>` ghi một task doc bền trong `tasks/`, pause bao lâu cũng resume được                                                       |
| Cùng một quyết định bị tái khám phá liên tục                   | `/learn` thăng cấp pattern lặp lại thành `rules/` bền, tự load theo path phù hợp                                                         |
| Fact bền của dự án không có chỗ đúng để sống                   | `knowledge/` giữ fact mô tả — domain, architecture, glossary, link tới docs chuẩn; `/start` surfacing index để fact sống qua mọi session |
| `CLAUDE.md` / `AGENTS.md` phình to và đốt token                | `/refactor-memory` tách tri thức ra rule có scope                                                                                        |
| Codex subagent bị dùng thiếu nhất quán hoặc quá rộng           | `agent-delegation.md` khiến parallel work của Codex trở nên rõ ràng, có giới hạn và luôn được parent review                              |
| Agent drift khỏi scope mà không ai bắt                         | `clean-code-reviewer` + `security-auditor` chạy khi có yêu cầu review/audit rõ ràng hoặc khi delegation đã được authorize                |
| Memory drift âm thầm, không có cách kiểm tra                   | `/doctor` validate cấu trúc, frontmatter, token hygiene và độ mới của knowledge từ đầu đến cuối                                          |
| Ý tưởng còn thô, chưa có skeleton dự án                        | `/project-discovery` phỏng vấn bạn thành tài liệu dự án có cấu trúc trước khi viết code                                                  |
| Framework memory khác cần vector DB, Docker hoặc cloud account | Markdown thuần. Chạy offline. Review được bằng PR.                                                                                       |

## Mô hình memory

```text
SESSION STATE (dễ bay hơi)          DURABLE REFERENCE (sống qua session)

CONTEXT.md       JOURNAL.md         rules/ · guidelines/   knowledge/
điều đang đúng   điều đã xảy ra     cách agent hành xử     dự án là gì
(declarative)    (history log)      (prescriptive)         (descriptive facts)

luôn được load    không auto-load   auto-load theo         INDEX trên /start,
vào context       (chỉ audit)       path phù hợp           detail đọc khi cần
```

`/checkpoint` rebuild `CONTEXT.md` theo kiểu declarative (trần cứng 150 dòng), đẩy item đã nghỉ sang `JOURNAL.md`, và ghi **fact** bền (domain, architecture, link tới external docs) vào topic file trong `knowledge/`. `/learn` thăng cấp **hành vi** lặp lại thành rule file có scope theo path. Journal là audit history, được giữ ngoài working context để tiết kiệm token. Knowledge có vòng bảo trì riêng — `/doctor` phát hiện drift (fact cũ, link chết, trùng lặp), còn `/refactor-memory` gom lại và kiểm chứng từng fact với code hiện tại.

## Bắt đầu nhanh

```bash
# Trong project đã cài CLAUDART
/start                          # định hướng session
/plan add JWT middleware        # ghi task doc bền — agent chờ bạn approve trước khi code
/checkpoint                     # rebuild CONTEXT.md và sync state cuối session
/learn                          # thăng cấp quyết định lặp lại thành rule bền
/doctor                         # health check khi setup có vẻ lệch
```

Codex CLI: cùng flow, đổi `/` thành `$codex-` (ví dụ `$codex-start`, `$codex-plan`).

Codex subagents được hỗ trợ như một workflow opt-in. Hãy nói rõ với Codex rằng bạn muốn dùng subagents, delegation hoặc parallel agents; CLAUDART sẽ hướng dẫn nó tách critical-path work khỏi sidecar explorers/workers, gán ownership không chồng lấn, và lưu kết quả bền trong task files.

## Tài liệu

**[docs/WORKFLOW_VI.md](docs/WORKFLOW_VI.md)** — kiến trúc, mô hình memory, lifecycle đầy đủ của task, toàn bộ command/skill và layout thư mục. README là phần giới thiệu; `WORKFLOW_VI.md` là manual.

Bản tiếng Anh: **[README.md](README.md)** và **[docs/WORKFLOW.md](docs/WORKFLOW.md)**.

## So sánh

|                                |                 CLAUDART                 |              Mem0               |          Zep          |        LangMem        |              Understand-Anything               |                     MemPalace                      |
| ------------------------------ | :--------------------------------------: | :-----------------------------: | :-------------------: | :-------------------: | :--------------------------------------------: | :------------------------------------------------: |
| **Setup**                      |              `curl \| bash`              | vector DB + Docker + OpenAI key | Neo4j + managed cloud | PostgreSQL + pgvector |           `curl \| bash` hoặc plugin           |            `pip install` + model 300 MB            |
| **Con người đọc được**         |                    ✅                    |               ❌                |          ❌           |          ❌           |              ⚠️ JSON + dashboard               |           ⚠️ text nguyên văn, binary DB            |
| **Chạy offline / air-gapped**  |                    ✅                    |               ❌                |          ❌           |          ❌           |                   ❌ cần LLM                   |                         ✅                         |
| **Memory review được bằng PR** |                    ✅                    |               ❌                |          ❌           |          ❌           |             ✅ JSON commit vào git             |            ❌ ChromaDB + SQLite binary             |
| **Tool hỗ trợ**                | Claude Code, Codex CLI, Cursor, Windsurf |             chỉ API             |        chỉ API        |     chỉ LangGraph     | Claude, Codex, Cursor, Copilot, Gemini + 6 nữa | Claude Code, Codex CLI, Gemini CLI, MCP-compatible |

Các coding tool lớn đều đã hội tụ về markdown thuần trong repo — `AGENTS.md` đã xuất hiện trong khoảng 20k public GitHub repo. CLAUDART làm convention đó có cấu trúc hơn và bổ sung các mảnh workflow xung quanh: orientation, planning, learning, hygiene check và code-review safety net.

## License

MIT. Xem [`LICENSE`](LICENSE). Hoan nghênh đóng góp — xem [`CONTRIBUTING.md`](CONTRIBUTING.md).

---

<div align="center">
  <i>Built for the future of AI-assisted development.</i>
</div>
