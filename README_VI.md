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

Coding agent hay quên. Đóng terminal là kế hoạch biến mất. Session kế tiếp bắt đầu trong mù mờ, đọc lại nửa repo, rồi tranh luận lại một quyết định bạn đã chốt từ thứ Ba tuần trước. Trong lúc đó `CLAUDE.md` cứ phình to, vì chẳng ai đủ tin nó để xóa bất kỳ thứ gì.

CLAUDART xử lý chuyện này bằng file. Một nhóm slash command nhỏ duy trì một bộ tài liệu markdown dưới `.claude/` và `.codex/`: điều đang đúng ngay lúc này, kế hoạch cho từng task, các fact và rule đáng giữ lại. Tất cả đều được commit vào git, review được trong PR, và đọc được mà không cần tooling nào. Không có vector database, không daemon. Không cần host, không cần trông coi.

## Cài đặt

```bash
# Flag sau `bash -s --`:  --claude (mặc định) · --codex · --both · --force (ghi đè)
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --claude
```

`install.sh` copy mới toàn bộ, và đó không phải cách đúng cho một project đã có setup riêng. Trong trường hợp đó, hãy dán đoạn này vào agent của bạn. Nó sẽ đọc repo, diff với project, và chỉ merge những gì bạn phê duyệt:

> Đọc https://raw.githubusercontent.com/vankhaivn/Claudart/main/INTEGRATE.md và làm theo để tích hợp CLAUDART vào project này. Hỏi tôi trước khi đụng tới bất kỳ thứ gì tôi đã custom.

## CLAUDART giải quyết gì

| Nỗi đau                                      | Cách CLAUDART xử lý                                                                                   |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Session nào cũng bắt đầu mù mờ               | `/start` đọc trạng thái hiện tại, task đang mở và các commit gần đây trước khi đụng vào bất kỳ thứ gì |
| Kế hoạch mất khi session đóng                | `/plan` ghi kế hoạch vào task file để session sau có thể tiếp tục đúng chỗ bạn dừng                   |
| Session hiệu quả chạm trần context           | `/handoff` lưu suy luận của session - giả thuyết, evidence, dead ends - cho lần `/start` kế tiếp      |
| Cùng quyết định bị tái khám phá hằng tuần    | `/learn` biến các chỉnh sửa lặp lại thành rule có scope theo path                                     |
| Fact bền của dự án không có chỗ đúng để sống | `knowledge/` giữ chúng; index được hiển thị mỗi session, chi tiết được đọc khi cần                    |
| `CLAUDE.md` phình thành bồn đốt token        | `/refactor-memory` gọt nó lại thành một index và đưa nội dung về đúng nơi                             |
| Memory âm thầm mục ruỗng                     | `/doctor` là health check read-only để flag drift, link chết và nội dung đặt sai tầng                 |

Hai review agent được ship kèm các command - `clean-code-reviewer` và `security-auditor` - cùng một delegation protocol để giữ việc subagent song song có biên rõ ràng thay vì lan rộng mất kiểm soát.

## Mô hình memory

Bốn loại memory, bốn vòng đời khác nhau:

```text
SESSION STATE (dễ bay hơi)           DURABLE REFERENCE (sống qua session)

CONTEXT.md       JOURNAL.md          rules/ · guidelines/   knowledge/
điều đang đúng   điều đã xảy ra      cách hành xử           dự án là gì
(declarative)    (history log)       (prescriptive)         (descriptive facts)

luôn được load   không được load     auto-load theo         INDEX trên /start,
vào context      (chỉ audit)         path phù hợp           chi tiết đọc khi cần
```

`/checkpoint` rebuild `CONTEXT.md` ở cuối session và retire lịch sử sang `JOURNAL.md`, file không bao giờ được load vào context - nó tồn tại để audit, không phải để gợi nhớ. Fact nào hóa ra bền thì được thăng cấp vào `knowledge/`; hành vi nào cứ lặp lại thì được thăng cấp vào `rules/` qua `/learn`. Khi có gì đó trông stale, `/doctor` flag nó, và `/refactor-memory` kiểm lại từng fact với code thật trước khi giữ.

## Bắt đầu nhanh

```bash
# Trong project đã cài CLAUDART
/start                          # định hướng session
/plan add JWT middleware        # ghi task file; agent chờ bạn approve trước khi code
/handoff                        # context gần đầy? lưu suy luận, resume fresh bằng /start
/checkpoint                     # rebuild CONTEXT.md cuối session
/learn                          # thăng cấp quyết định lặp lại thành rule
/doctor                         # health check khi setup có vẻ lệch
```

Codex CLI chạy cùng flow với `$codex-` thay cho `/` (ví dụ `$codex-start`).

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

Markdown thuần trong repo đã thắng lập luận này: `AGENTS.md` giờ là một tiêu chuẩn của Linux Foundation, được dùng trong hơn 60.000 public repository. CLAUDART dựa trên convention đó và xây workflow còn thiếu ở phía trên - orientation, planning, learning, hygiene và review.

## License

MIT, xem [`LICENSE`](LICENSE). Hoan nghênh đóng góp; [`CONTRIBUTING.md`](CONTRIBUTING.md) có các nguyên tắc cơ bản.
