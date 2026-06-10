<div align="center">
  <h1>CLAUDART</h1>
  <p><strong>Lớp vận hành bằng markdown cho Claude Code &amp; Codex CLI - memory, kế hoạch và review, tất cả nằm trong git.</strong></p>

  <p>
    <a href="https://github.com/vankhaivn/Claudart/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/vankhaivn/Claudart?style=for-the-badge&color=orange"></a>
    <img alt="Pure Markdown" src="https://img.shields.io/badge/memory-pure_markdown-blue?style=for-the-badge">
    <img alt="Offline-friendly" src="https://img.shields.io/badge/works-offline-green?style=for-the-badge">
    <a href="https://github.com/vankhaivn/Claudart/issues"><img alt="Issues" src="https://img.shields.io/github/issues/vankhaivn/Claudart?style=for-the-badge&color=blue"></a>
  </p>
</div>

---

> **Vấn đề.** AI coding agent làm rò trạng thái: mỗi session bắt đầu trong mù mờ, kế hoạch chết trong chat, quyết định cũ bị tái khám phá hằng tuần, còn `CLAUDE.md` / `AGENTS.md` phình thành bồn đốt token mà không ai còn tin.

CLAUDART xử lý chuyện đó bằng một nhóm slash command nhỏ trên mô hình memory nhiều tầng bằng markdown - các file thuần nằm trong `.claude/` và `.codex/`, được version bằng git, review được trong PR, đọc được offline. Không vector DB, không daemon, không cloud.

## Cài đặt

```bash
# Flag sau `bash -s --`:  --claude (mặc định) · --codex · --both · --force (ghi đè)
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --claude
```

**Bạn đã có setup riêng, hoặc đang nâng cấp?** `install.sh` copy mới và sẽ ghi đè phần bạn đã tùy chỉnh. Thay vào đó, hãy dán đoạn này vào agent của bạn - nó sẽ đọc repo, diff với project của bạn, và chỉ merge những gì bạn phê duyệt:

> Đọc https://raw.githubusercontent.com/vankhaivn/Claudart/main/INTEGRATE.md và làm theo để tích hợp CLAUDART vào project này. Hỏi tôi trước khi đụng tới bất kỳ thứ gì tôi đã custom.

## CLAUDART giải quyết gì

| Nỗi đau                                      | Cách CLAUDART xử lý                                                                                                 |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Session nào cũng bắt đầu mù mờ               | `/start` - đọc trạng thái hiện tại, task active, knowledge index và commit gần đây                                  |
| Kế hoạch mất khi session đóng                | `/plan` - task doc bền, sống qua mọi lần pause                                                                      |
| Session hiệu quả chạm trần context           | `/handoff` - baton single-slot giữ trạng thái suy luận của session; lần `/start` kế tiếp resume từ đó               |
| Cùng quyết định bị tái khám phá hằng tuần    | `/learn` - thăng cấp pattern lặp lại thành `rules/` có scope theo path                                              |
| Fact bền của dự án không có chỗ đúng để sống | `knowledge/` - fact mô tả (domain, architecture, glossary), được hiển thị mỗi session                               |
| `CLAUDE.md` phình to và đốt token            | `/refactor-memory` - gọt còn index gọn; behavior -> rules, facts -> knowledge                                       |
| Memory drift âm thầm; agent đi lệch scope    | `/doctor` báo dấu hiệu xuống cấp; `clean-code-reviewer`, `security-auditor` và `agent-delegation` giữ scope rõ ràng |

## Mô hình memory

```text
SESSION STATE (dễ bay hơi)          DURABLE REFERENCE (sống qua session)

CONTEXT.md       JOURNAL.md         rules/ · guidelines/   knowledge/
điều đang đúng   điều đã xảy ra     cách hành xử           dự án là gì
(declarative)    (history log)      (prescriptive)         (descriptive facts)

luôn được load   không được load    auto-load theo         INDEX trên /start,
vào context      (chỉ audit)        path phù hợp           detail đọc khi cần
```

`/checkpoint` rebuild `CONTEXT.md`, đưa lịch sử đã nghỉ sang `JOURNAL.md` (chỉ audit, không bao giờ load), và ghi fact bền vào `knowledge/`. `/learn` thăng cấp hành vi lặp lại thành `rules/`. `/doctor` và `/refactor-memory` giữ knowledge trung thực - flag drift và kiểm lại từng fact với code.

## Bắt đầu nhanh

```bash
# Trong project đã cài CLAUDART
/start                          # định hướng session
/plan add JWT middleware        # task doc bền - agent chờ bạn approve trước khi code
/handoff                        # context window sắp đầy - distill trạng thái suy luận, resume bằng /start
/checkpoint                     # rebuild CONTEXT.md + sync state cuối session
/learn                          # thăng cấp quyết định lặp lại thành rule
/doctor                         # health check khi setup có vẻ lệch
```

Codex CLI: cùng flow, đổi `/` thành `$codex-` (ví dụ `$codex-start`).

## Tài liệu

**[docs/WORKFLOW_VI.md](docs/WORKFLOW_VI.md)** là manual - kiến trúc, lifecycle đầy đủ của task, toàn bộ command và layout thư mục. README này chỉ là phần giới thiệu.

Bản tiếng Anh: **[README.md](README.md)** và **[docs/WORKFLOW.md](docs/WORKFLOW.md)**.

## So sánh

|                                |        CLAUDART        |              Mem0               |          Zep          |        LangMem        |              Understand-Anything               |                     MemPalace                      |
| ------------------------------ | :--------------------: | :-----------------------------: | :-------------------: | :-------------------: | :--------------------------------------------: | :------------------------------------------------: |
| **Setup**                      |     `curl \| bash`     | vector DB + Docker + OpenAI key | Neo4j + managed cloud | PostgreSQL + pgvector |           `curl \| bash` hoặc plugin           |            `pip install` + model 300 MB            |
| **Con người đọc được**         |           ✅           |               ❌                |          ❌           |          ❌           |              ⚠️ JSON + dashboard               |           ⚠️ text nguyên văn, binary DB            |
| **Chạy offline / air-gapped**  |           ✅           |               ❌                |          ❌           |          ❌           |                   ❌ cần LLM                   |                         ✅                         |
| **Memory review được bằng PR** |           ✅           |               ❌                |          ❌           |          ❌           |             ✅ JSON commit vào git             |            ❌ ChromaDB + SQLite binary             |
| **Tool hỗ trợ**                | Claude Code, Codex CLI |             chỉ API             |        chỉ API        |     chỉ LangGraph     | Claude, Codex, Cursor, Copilot, Gemini + 6 nữa | Claude Code, Codex CLI, Gemini CLI, MCP-compatible |

Markdown nằm trong repo đã thắng thế - `AGENTS.md` đã xuất hiện trong khoảng 20k public repo. CLAUDART làm convention đó có cấu trúc hơn và bổ sung workflow xung quanh nó: orientation, planning, learning, hygiene và review.

## License

MIT. Xem [`LICENSE`](LICENSE). Hoan nghênh đóng góp - xem [`CONTRIBUTING.md`](CONTRIBUTING.md).

---

<div align="center">
  <i>Được xây cho tương lai của phát triển phần mềm với AI hỗ trợ.</i>
</div>
