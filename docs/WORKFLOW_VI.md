# Quy trình CLAUDART

Bản đi sâu của [README tiếng Việt](../README_VI.md). Tài liệu này mô tả kiến trúc, mô hình memory, lifecycle của task, command, skill và layout thư mục.

## Mục lục

- [Hai layer](#hai-layer)
- [Mô hình memory — pipeline thăng cấp](#mô-hình-memory--pipeline-thăng-cấp)
- [Workflow task bền](#workflow-task-bền)
  - [Cấu trúc task file](#cấu-trúc-task-file)
  - [State machine trạng thái](#state-machine-trạng-thái)
  - [Cổng hoàn tất hai pha](#cổng-hoàn-tất-hai-pha)
  - [Tín hiệu approve](#tín-hiệu-approve)
  - [Resume qua session khác](#resume-qua-session-khác)
- [Codex subagent delegation](#codex-subagent-delegation)
- [Command và skill](#command-và-skill)
- [Layout thư mục](#layout-thư-mục)

## Hai layer

CLAUDART cài vào project dưới dạng hai layer song song. Bạn có thể chạy riêng từng layer hoặc chạy cạnh nhau; cả hai đều ghi vào cùng lịch sử git.

- **Claude layer** (`.claude/`) — slash command, rule, review agent, session state
- **Codex layer** (`.codex/` + `.agents/skills/`) — guideline, TOML subagent, repo skill

Mỗi Claude command có một Codex skill tương ứng. Core protocol về memory và lifecycle task là giống nhau; những khả năng riêng của từng runtime, ví dụ Codex subagents, sẽ có guideline bổ sung.

## Mô hình memory — pipeline thăng cấp

CLAUDART chia project memory thành các tầng rõ ràng, với bước thăng cấp tường minh giữa chúng:

```text
CONTEXT.md       JOURNAL.md          rules/ · guidelines/      knowledge/
("ngay lúc này") ("đã xảy ra gì")    ("cách hành xử")          ("dự án là gì")
```

- **`CONTEXT.md`** — state declarative, điều đang đúng _ngay lúc này_. Được cập nhật bằng `/checkpoint` (Claude) hoặc `$codex-checkpoint` (Codex). Trần cứng: 150 dòng.
- **`JOURNAL.md`** — audit log append-only. Mỗi dòng là một item đã nghỉ. **Không bao giờ auto-load vào session context** — file này dành cho review có chủ đích, không phải active recall.
- **`rules/`** (Claude) và **`guidelines/`** (Codex) — rule **hành vi** bền, có scope theo path (prescriptive — "phải hành xử thế nào"). Được tạo khi một pattern lặp lại đủ nhiều để `/learn` hoặc `$codex-learn` thăng cấp.
- **`knowledge/`** — **fact mô tả** bền của dự án (domain, architecture, glossary) và pointer tới docs chuẩn ở thư mục khác. Đây là trục đối lập với rules: rules quy định hành vi, knowledge mô tả sự thật. Mỗi topic là một file; chỉ `knowledge/INDEX.md` được surfaced bởi `/start` hoặc `$codex-start`, còn file detail được đọc khi cần. Ưu tiên reference external docs thay vì copy lại, để tránh stale-by-copy.

Một ghi chú đi vào từ `CONTEXT.md`. Khi nó ổn định, một dòng được thăng cấp sang `JOURNAL.md`. `/checkpoint` đưa **fact** bền vào một topic file trong `knowledge/` và đăng ký trong `INDEX.md`; khi một pattern hành vi lặp lại, `/learn` thăng cấp nó thành rule file. Chỉ rules và `CONTEXT.md` được auto-load; knowledge được surfaced như một bản đồ và kéo detail khi cần — phần còn lại đứng ngoài working set trừ khi được gọi rõ ràng.

Knowledge được **bảo trì, không chỉ tích lũy**. `/doctor` là read-only và phát hiện drift — fact cũ, `sources:` / `related:` link chết, trùng lặp giữa các tầng, hoặc nội dung nằm sai tầng. `/refactor-memory` xử lý các flag đó: kiểm chứng từng fact với code hiện tại, gom duplicate, và chuyển nội dung qua lại giữa ranh giới descriptive ↔ prescriptive **cả hai chiều** (fact bị đặt nhầm trong rule → `knowledge/`; rule bị rò vào knowledge → đưa lại về rule). Không có gì bị auto-delete — drift được surfaced để bạn xác nhận.

## Workflow task bền

Plan mode gốc (Shift+Tab trong Claude Code, `/plan` trong Codex CLI) giữ kế hoạch trong chat. Đóng terminal là mất plan; pause một ngày là context trôi khi commit khác đã land.

CLAUDART thay bằng **task document bền** — mỗi task là một markdown file trong `.claude/tasks/` hoặc `.codex/tasks/`, được version bằng git.

```text
/plan <task>  →  tasks/<YYYY-MM-DD-NNN-slug>.md  →  tasks/done/<NNN-slug>.md  →  JOURNAL.md
 (tạo)            (lifecycle: planning → in-progress →    (archive sau khi     (record một dòng)
                   awaiting-review → done)                 user xác nhận)
```

### Cấu trúc task file

Mỗi task file phải **self-contained** — chỉ cần đọc file đó là đủ để resume trong session mới, kể cả nhiều ngày sau, kể cả khi commit không liên quan đã thay đổi code. Các section bắt buộc:

- **Frontmatter** — `slug`, `status`, `created`, `updated`, `agent`, `tags`
- **Purpose** — ai nhận được lợi ích gì, kiểm chứng hoạt động ra sao
- **Context & Orientation** — `Related Code`, `Related Docs`, và **`Memory Hints`** (ghi chú tự do từ session này cho session sau — sợi dây cứu sinh chống mất context)
- **Plan of Work** — prose mô tả trình tự và lý do
- **Concrete Steps** — checklist có thứ tự, mỗi item hoàn tất có timestamp UTC
- **Validation & Acceptance** — tiêu chí thành công quan sát được (command, manual check)
- **Decision Log** — lựa chọn không hiển nhiên và rationale
- **Surprises & Discoveries** — nơi thực tế lệch khỏi plan
- **Outcomes & Retrospective** — điền khi hoàn tất

Schema và protocol chuẩn nằm trong [`.claude/rules/task-management.md`](../.claude/rules/task-management.md) và [`.codex/guidelines/task-management.md`](../.codex/guidelines/task-management.md).

### State machine trạng thái

```text
planning ──(user approves)──▶ in-progress
in-progress ──(agent finishes)──▶ awaiting-review
awaiting-review ──(user confirms)──▶ done
awaiting-review ──(user reports problem)──▶ in-progress     ← back-edge
in-progress ──(blocker)──▶ blocked
blocked ──(cleared)──▶ in-progress
{any} ──(user cancels)──▶ cancelled
```

Hai trạng thái là **read-only lock** — agent chỉ được đụng task file, không đụng code:

- `planning` — đang draft hoặc chờ approve để bắt đầu
- `awaiting-review` — agent đã báo hoàn tất; user chưa verify

### Cổng hoàn tất hai pha

Phần lớn agent workflow cho phép agent tự đánh dấu task là done — rồi bạn phát hiện bug thật sau khi checkbox xanh đã nằm trong JOURNAL. CLAUDART tách completion thành hai pha:

**Pha 1 — Agent báo cáo** (`in-progress → awaiting-review`)

Khi mọi checkbox đã tick, agent điền draft Outcomes, đổi status sang `awaiting-review`, báo cho bạn, rồi **dừng**. Chưa archive, chưa ghi JOURNAL.

**Pha 2a — Bạn xác nhận** (`awaiting-review → done`)

Bạn verify công việc thật sự — chạy app, check build, inspect diff. Nói "approved" / "looks good" / "ok đóng" — agent chạy archive flow: move file vào `done/`, append một dòng JOURNAL, update index.

**Pha 2b — Bạn báo lỗi** (`awaiting-review → in-progress`)

Thấy bug? Chỉ cần nói. Agent append nguyên văn báo cáo của bạn vào Surprises, uncheck step sai, đổi lại `in-progress`, rồi sửa. Vòng Phase 1 ↔ 2b có thể lặp lại — đó là hệ thống đang bắt bug thật, không phải thất bại.

### Tín hiệu approve

Agent theo dõi cue ngôn ngữ tự nhiên, không cần slash command:

| Transition                      | Bạn nói gì                                                                    |
| ------------------------------- | ----------------------------------------------------------------------------- |
| `planning → in-progress`        | "go", "approved", "implement", "do it", "ok làm đi", "start"                  |
| `awaiting-review → done`        | "approved", "confirmed", "looks good", "close it", "done", "ship", "ok đóng"  |
| `awaiting-review → in-progress` | Bất kỳ báo cáo lỗi nào — "didn't work", "broken", "missed X", "chưa đúng chỗ" |
| `* → cancelled`                 | "cancel", "abandon", "drop this", "bỏ task"                                   |

Hào hứng ("great!", "nice plan") **không phải** approve. Việc bạn sửa task file **không phải** approve. Signal phải rõ ràng và là bắt buộc.

## Resume qua session khác

Một session mới khi resume task sẽ:

1. Đọc toàn bộ task file (vì file được thiết kế self-contained).
2. Verify các step đã hoàn tất vẫn đúng với code **hiện tại** — commit không liên quan có thể đã move file hoặc đổi API.
3. Ghi drift vào Surprises và hỏi bạn nên adapt plan hay xem lại step cũ.
4. Tiếp tục từ step chưa check tiếp theo.

Memory Hints từ session trước là sợi dây cứu sinh. Hãy điền rộng rãi khi planning — mọi constraint không hiển nhiên, library quirk hoặc pitfall đã phát hiện đều nên nằm ở đó.

## Codex subagent delegation

Codex có thể chạy subagent cho parallel exploration, implementation có giới hạn, review và audit. CLAUDART xem khả năng này là **parallelism được authorize rõ ràng**, không phải phản ứng tự động với task lớn.

Codex layer bổ sung `.codex/guidelines/agent-delegation.md` làm protocol bền. Protocol này yêu cầu parent Codex session tách rõ:

- **Critical path** — việc parent agent nên làm local ngay bây giờ
- **Sidecar tasks** — task nhỏ, có giới hạn, có thể chạy song song mà không block parent
- **Ownership** — câu hỏi read-only hoặc write scope cụ thể giao cho từng subagent
- **Merge plan** — findings, patch và validation result quay về parent như thế nào

Dùng subagents khi user nói rõ kiểu "use subagents", "delegate this", hoặc "parallelize with agents". Không suy diễn authorization từ "be thorough" hoặc "research deeply". Explorer nên read-only, worker cần write scope không chồng lấn, reviewer/security auditor chỉ tạo findings để parent tiếp tục sở hữu và validate.

Task document lưu phần bền của delegation — authorization status, role, ownership boundary, findings, decision và validation outcome. Không lưu transient subagent thread id. `$codex-checkpoint` có thể carry forward active delegation blocker hoặc next step trong `CONTEXT.md`, nhưng findings đã hoàn tất nên sống trong task file và về sau là `JOURNAL.md`.

## Command và skill

| Claude Code          | Codex CLI                  | Tác dụng                                                                                                        |
| -------------------- | -------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `/start`             | `$codex-start`             | Boot session nhẹ — đọc CONTEXT, active tasks và 3 commit gần nhất                                               |
| `/plan <task>`       | `$codex-plan <task>`       | Tạo implementation plan bền trong `tasks/` — thay cho plan mode chỉ sống trong session                          |
| `/project-discovery` | `$codex-project-discovery` | Planning theo kiểu phỏng vấn trước — biến ý tưởng thô thành project docs trước khi code                         |
| `/refactor-memory`   | `$codex-refactor-memory`   | Gọt CLAUDE.md/AGENTS.md thành index nhẹ; tách durable guidance vào rules/guidelines; consolidate knowledge tier |
| `/checkpoint`        | `$codex-checkpoint`        | Rebuild CONTEXT declarative + sync `tasks/index.md` + append JOURNAL + fact bền → `knowledge/`                  |
| `/learn`             | `$codex-learn`             | Retrospective — thăng cấp lesson lặp lại thành rules/guidelines với ngôn ngữ đóng loophole                      |
| `/doctor`            | `$codex-doctor`            | Health check read-only: cấu trúc, frontmatter, token hygiene, wiring, task hygiene và knowledge hygiene         |

Review agent có ở cả hai layer: `clean-code-reviewer` (scope + Clean Code discipline) và `security-auditor` (OWASP audit — read-only trên code của bạn, nhưng ghi findings vào report `security-audit-<date>.md` ở project root và chỉ in summary ra chat). Claude dùng tên agent dạng kebab-case Markdown; Codex dùng giá trị `name` snake_case trong TOML.

Codex subagent delegation được quản bởi `.codex/guidelines/agent-delegation.md`. Config Codex được ship giữ `[agents] max_depth = 1` và `max_threads` mặc định thận trọng để downstream project có parallelism hữu ích mà không bị recursive fan-out.

## Layout thư mục

```text
your-project/
├── AGENTS.md                       # Codex root loader (copy từ .codex/AGENTS.md khi install)
├── .agents/
│   └── skills/                     # Codex repo skills (codex-start, codex-plan, codex-checkpoint, ...)
├── .codex/
│   ├── AGENTS.md                   # Codex source template; được copy ra root AGENTS.md
│   ├── CONTEXT.md                  # Live state, declarative, ≤ 150 dòng
│   ├── JOURNAL.md                  # Append-only audit log — không auto-load
│   ├── agents/                     # Codex TOML subagents
│   │   ├── clean-code-reviewer.toml
│   │   └── security-auditor.toml
│   ├── config.toml                 # Codex project defaults
│   ├── guidelines/                 # Codex-native semantic guidance
│   │   ├── ai-behavior.md
│   │   ├── agent-delegation.md
│   │   └── task-management.md
│   ├── knowledge/                  # Fact mô tả bền + external-doc pointers
│   │   └── INDEX.md                # Map surfaced bởi $codex-start; topic files đọc khi cần
│   └── tasks/                      # Implementation plan bền (mỗi task một file)
│       ├── index.md                # Dashboard active + recently-done, ≤ 100 dòng
│       └── done/                   # Task completed/cancelled đã archive
└── .claude/
    ├── CLAUDE.md                   # Lightweight index (< 100 dòng)
    ├── CONTEXT.md                  # Live state, declarative, ≤ 150 dòng
    ├── JOURNAL.md                  # Append-only audit log — không auto-load
    ├── agents/
    │   ├── clean-code-reviewer.md
    │   └── security-auditor.md
    ├── commands/                   # Slash command protocols
    ├── knowledge/                  # Fact mô tả bền + external-doc pointers
    │   └── INDEX.md                # Map surfaced bởi /start; topic files đọc khi cần
    ├── rules/
    │   ├── ai-behavior.md
    │   └── task-management.md
    └── tasks/                      # Implementation plan bền (mỗi task một file)
        ├── index.md                # Dashboard active + recently-done, ≤ 100 dòng
        └── done/                   # Task completed/cancelled đã archive
```
