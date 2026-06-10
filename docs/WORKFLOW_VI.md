# Quy trình CLAUDART

Bản đi sâu đồng hành với [README tiếng Việt](../README_VI.md). Tài liệu này bao quát kiến trúc, mô hình memory, lifecycle của task, command và layout thư mục.

## Mục lục

- [Hai layer](#hai-layer)
- [Mô hình memory: pipeline thăng cấp](#mô-hình-memory-pipeline-thăng-cấp)
- [Session handoff: sống sót qua tràn context](#session-handoff-sống-sót-qua-tràn-context)
- [Workflow task bền](#workflow-task-bền)
  - [Cấu trúc task file](#cấu-trúc-task-file)
  - [State machine trạng thái](#state-machine-trạng-thái)
  - [Cổng hoàn tất hai pha](#cổng-hoàn-tất-hai-pha)
  - [Tín hiệu phê duyệt](#tín-hiệu-phê-duyệt)
  - [Resume qua session khác](#resume-qua-session-khác)
- [Subagent delegation](#subagent-delegation)
- [Command và skill](#command-và-skill)
- [Layout thư mục](#layout-thư-mục)

## Hai layer

CLAUDART cài vào project dưới dạng hai layer song song. Bạn có thể chạy riêng từng layer hoặc chạy cạnh nhau; cả hai đều ghi vào cùng lịch sử git.

- **Claude layer** (`.claude/`) - slash command, rule, review agent, session state
- **Codex layer** (`.codex/` + `.agents/skills/`) - guideline, TOML subagent, repo skill

Mỗi Claude command có một Codex skill tương ứng, và core protocol về memory lẫn lifecycle task là giống nhau. Khi runtime khác nhau, hướng dẫn sẽ thích nghi theo từng runtime: ví dụ subagent delegation được ship ở cả hai layer - `.claude/rules/agent-delegation.md` cho Agent tool của Claude và `.codex/guidelines/agent-delegation.md` cho mô hình explorer/worker của Codex.

## Mô hình memory: pipeline thăng cấp

CLAUDART chia project memory thành các tầng rõ ràng, với bước thăng cấp tường minh giữa chúng:

```text
CONTEXT.md       JOURNAL.md          rules/ · guidelines/      knowledge/
("ngay lúc này") ("đã xảy ra gì")    ("cách hành xử")          ("dự án là gì")
```

- **`CONTEXT.md`** - state declarative, điều đang đúng _ngay lúc này_. Được cập nhật bằng `/checkpoint` (Claude) hoặc `$codex-checkpoint` (Codex). Trần cứng: 150 dòng.
- **`JOURNAL.md`** - audit log append-only. Mỗi dòng là một item đã nghỉ. **Không bao giờ auto-load vào session context** - file này dành cho review có chủ đích, không phải gợi nhớ chủ động.
- **`rules/`** (Claude) và **`guidelines/`** (Codex) - rule **hành vi** bền, có scope theo path (prescriptive - "phải hành xử thế nào"). Được tạo khi một pattern lặp lại đủ nhiều để `/learn` hoặc `$codex-learn` thăng cấp.
- **`knowledge/`** - **fact mô tả** bền của dự án (domain, architecture, glossary) và pointer tới docs chuẩn ở thư mục khác. Đây là trục đối lập với rules: rules quy định, knowledge mô tả. Mỗi topic là một file; chỉ `knowledge/INDEX.md` được hiển thị bởi `/start` hoặc `$codex-start`, còn file detail được đọc khi cần (bản đồ, không phải bách khoa toàn thư). Ưu tiên reference docs bên ngoài thay vì copy lại, để chúng không lỗi thời vì copy.

Một ghi chú đi vào từ `CONTEXT.md`. Khi nó ổn định, một dòng được thăng cấp sang `JOURNAL.md`. `/checkpoint` thăng cấp **fact** bền vào một topic file trong `knowledge/` và đăng ký trong `INDEX.md`; khi một pattern hành vi lặp lại, `/learn` thăng cấp nó thành rule file. Chỉ rules và `CONTEXT.md` được auto-load; knowledge được hiển thị như một bản đồ và kéo detail khi cần - phần còn lại đứng ngoài bộ context đang làm việc trừ khi được gọi rõ ràng.

Knowledge được **bảo trì, không chỉ tích lũy**. `/doctor` là read-only và phát hiện drift - fact cũ, `sources:`/`related:` link chết, trùng lặp giữa các tầng, hoặc nội dung nằm sai tầng. `/refactor-memory` xử lý các flag đó: kiểm chứng từng fact với code hiện tại, gom duplicate, và chuyển nội dung qua lại giữa ranh giới descriptive↔prescriptive **cả hai chiều** (fact bị đặt nhầm trong rule → `knowledge/`; rule bị rò vào knowledge → đưa lại về rule). Không có gì bị auto-delete - drift được hiển thị để bạn xác nhận.

Trên toàn bộ command, knowledge có lifecycle rõ ràng: `/start` **hiển thị** INDEX, `/checkpoint` **ghi** fact mới (bao gồm fact cấp project được cứu từ Memory Hints của task đã archive), và `/refactor-memory` **khởi tạo** một tầng rỗng từ docs hiện có rồi phân loại nội dung trích ra theo loại - behavior → rules, facts → knowledge. Mỗi entry mang anchor `sources:`/`verify:` tới file mà nó tóm tắt, để `/doctor` có thể kiểm tra thay vì đoán.

## Session handoff: sống sót qua tràn context

Bốn tầng memory đều lưu trạng thái **dự án**. Nhưng một phiên làm việc hiệu quả còn mang theo **trạng thái suy luận** - giả thuyết đang theo, evidence đã gom, các hướng đã thử và loại trừ, bước kế tiếp chính xác - và trạng thái đó chết khi context window đầy. `/compact` gốc tóm tắt tại chỗ, nhưng kết quả là volatile: không nhìn thấy được, không review được, mất theo session, khóa vào một tool.

`/handoff` (Codex: `$codex-handoff`) ghi trạng thái suy luận đó ra một **baton single-slot** - `.claude/HANDOFF.md` hoặc `.codex/HANDOFF.md` - thiết kế dựa trên cách compaction thật vận hành (bài học rút từ pipeline compact của Claude Code và checkpoint compaction của Codex CLI):

- **Schema cố định, không freeform**: Objective, State of Play, Working Hypothesis, Evidence (anchor `file:line`), Dead Ends kèm lý do, User Constraints, Next Step, Open Questions.
- **Tầng verbatim**: ràng buộc user đã nêu, yêu cầu gần nhất của user, và câu quote neo chỗ dừng việc được giữ nguyên văn - phần còn lại mới được distill. Không bao giờ dump transcript.
- **Next step có neo**: hành động kế tiếp phải truy về yêu cầu tường minh gần nhất của user, kèm quote nguyên văn - để session resume không trôi sang việc khác.
- **Nội dung bền route ra trước**: fact đi vào `knowledge/`, phát hiện thuộc task đi vào Memory Hints của task file - baton chỉ giữ phần residue thuần hội thoại không có chỗ bền nào để sống.

Lifecycle: ghi một lần (đè baton cũ nếu có), được `/start` / `$codex-start` kế tiếp hiển thị, kiểm chứng với code hiện tại, rồi **xóa khi tiêu thụ**. Một file, một bước chuyền - không bao giờ là archive. Tóm tắt lặp nhiều lần là lossy lũy tiến, nên baton cố tình consumed-once; `/doctor` sẽ flag baton nằm quá 7 ngày chưa được tiêu thụ.

Handoff bổ sung cho `/checkpoint`, không thay thế: checkpoint ghi điều đang đúng về _dự án_; handoff ghi điều _cuộc hội thoại này_ đang nghĩ. Chạy handoff khi context window sắp đầy hoặc khi pause giữa chừng một cuộc điều tra - không phải nghi thức cuối session.

## Workflow task bền

Plan mode gốc (Shift+Tab trong Claude Code, `/plan` trong Codex CLI) giữ kế hoạch trong chat. Đóng terminal là mất plan; pause một ngày là context trôi khi commit khác đã land.

CLAUDART thay bằng **task document bền** - mỗi task là một markdown file trong `.claude/tasks/` hoặc `.codex/tasks/`, được version bằng git.

```text
/plan <task>  →  tasks/<YYYY-MM-DD-NNN-slug>.md  →  tasks/done/<NNN-slug>.md  →  JOURNAL.md
 (tạo)            (lifecycle: planning → in-progress →    (archive sau khi     (record một dòng)
                   awaiting-review → done)                 user xác nhận)
```

### Cấu trúc task file

Mỗi task file phải **self-contained** - chỉ cần đọc file đó là đủ để resume trong session mới, kể cả nhiều ngày sau, kể cả khi commit không liên quan đã thay đổi code. Các section bắt buộc:

- **Frontmatter** - `slug`, `status`, `created`, `updated`, `agent`, `tags`
- **Purpose** - ai nhận được lợi ích gì, kiểm chứng hoạt động ra sao
- **Context & Orientation** - `Related Code`, `Related Docs`, và **`Memory Hints`** (ghi chú tự do từ session này cho session sau - sợi dây cứu sinh chống mất context)
- **Plan of Work** - prose mô tả trình tự và lý do
- **Concrete Steps** - checklist có thứ tự, mỗi item hoàn tất có timestamp UTC
- **Validation & Acceptance** - tiêu chí thành công quan sát được (command, manual check)
- **Decision Log** - lựa chọn không hiển nhiên và rationale
- **Surprises & Discoveries** - nơi thực tế lệch khỏi plan
- **Outcomes & Retrospective** - điền khi hoàn tất

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

Hai trạng thái là **read-only lock** - agent chỉ được đụng task file, không đụng code:

- `planning` - đang draft hoặc chờ approve để bắt đầu
- `awaiting-review` - agent đã báo hoàn tất; user chưa kiểm chứng

### Cổng hoàn tất hai pha

Phần lớn agent workflow cho phép agent tự đánh dấu task là done - rồi bạn phát hiện bug thật sau khi checkbox xanh đã nằm trong JOURNAL. CLAUDART tách completion thành hai pha:

**Pha 1 - Agent báo cáo** (`in-progress → awaiting-review`)

Khi mọi checkbox đã tick, agent điền draft Outcomes, đổi status sang `awaiting-review`, báo cho bạn, rồi **dừng**. Chưa archive, chưa ghi JOURNAL.

**Pha 2a - Bạn xác nhận** (`awaiting-review → done`)

Bạn verify công việc thật sự - chạy app, check build, inspect diff. Nói "approved" / "looks good" / "ok đóng" - agent chạy archive flow: move file vào `done/`, append một dòng JOURNAL, update index.

**Pha 2b - Bạn báo lỗi** (`awaiting-review → in-progress`)

Thấy bug? Chỉ cần nói. Agent append nguyên văn báo cáo của bạn vào Surprises, uncheck step sai, đổi lại `in-progress`, rồi sửa. Vòng Phase 1 ↔ 2b có thể lặp lại - đó là hệ thống đang bắt bug thật, không phải thất bại.

### Tín hiệu phê duyệt

Agent theo dõi cue ngôn ngữ tự nhiên, không cần slash command:

| Transition                      | Bạn nói gì                                                                   |
| ------------------------------- | ---------------------------------------------------------------------------- |
| `planning → in-progress`        | "go", "approved", "implement", "do it", "ok làm đi", "start"                 |
| `awaiting-review → done`        | "approved", "confirmed", "looks good", "close it", "done", "ship", "ok đóng" |
| `awaiting-review → in-progress` | Bất kỳ báo cáo lỗi nào - "didn't work", "broken", "missed X"                 |
| `* → cancelled`                 | "cancel", "abandon", "drop this", "bỏ task"                                  |

Hào hứng ("great!", "nice plan") **không phải** phê duyệt. Việc bạn sửa task file **không phải** phê duyệt. Tín hiệu phải rõ ràng và là bắt buộc.

## Resume qua session khác

Một session mới khi resume task sẽ:

1. Đọc toàn bộ task file (vì file được thiết kế self-contained).
2. Verify các step đã hoàn tất vẫn đúng với code **hiện tại** - commit không liên quan có thể đã move file hoặc đổi API.
3. Ghi drift vào Surprises và hỏi bạn nên adapt plan hay xem lại step cũ.
4. Tiếp tục từ step chưa check tiếp theo.

Memory Hints từ session trước là sợi dây cứu sinh. Hãy điền rộng rãi khi planning - mọi constraint không hiển nhiên, library quirk hoặc pitfall đã phát hiện đều nên nằm ở đó.

## Subagent delegation

Cả hai layer đều có thể chạy subagent cho khảo sát song song, triển khai có giới hạn, review và audit. CLAUDART xem khả năng này là **chạy song song được cho phép rõ ràng**, không phải phản ứng tự động với task lớn - "be thorough" hoặc "research deeply" không phải authorization; "use subagents", "delegate this", hoặc "parallelize with agents" thì có.

Mỗi runtime có protocol viết theo mechanics riêng - `.claude/rules/agent-delegation.md` (Agent tool của Claude) và `.codex/guidelines/agent-delegation.md` (mô hình explorer/worker của Codex) - nhưng cùng chia sẻ một xương sống:

- **Decomposition gate** - trước khi tạo subagent, parent tách rõ **critical path** (việc cần làm local ngay), **sidecar tasks** (task nhỏ, có giới hạn, an toàn để chạy song song), **ownership** (câu hỏi read-only hoặc write scope chính xác cho từng subagent), và **merge plan** (findings quay về như thế nào). Nếu bước tiếp theo đang bị block bởi subtask, đừng tạo subagent - làm local.
- **Delegate-and-consume vs. delegate-and-continue** - quyết định theo cấu trúc task, không theo wording. Nếu câu hỏi được delegate _chính là_ toàn bộ task, tạo subagent và **chờ** - đừng âm thầm làm cùng việc song song. Chỉ tách ra nhiều agent song song khi request chia được thành các unit không chồng lấn; dấu hiệu cần nhìn là **chồng lấn của cùng sub-question** (nếu bước tiếp theo của bạn trả lời đúng thứ subagent đã own, đó là việc trùng lặp, không phải parallelism). Trùng lặp có chủ đích và được nói rõ thì ổn - independent review, hoặc phương án phòng hờ bạn đã authorize - nhưng không bao giờ phòng hờ âm thầm chỉ vì tool có vẻ rủi ro.
- **Ownership discipline** - explorer ở read-only; worker cần write scope tách biệt (Claude cô lập parallel writer trong git worktree riêng); reviewer và security auditor tạo findings mà parent vẫn sở hữu và validate. Patch từ subagent không bao giờ là kết quả final nếu chưa được parent review.

Task document lưu phần bền của delegation - authorization status, role, ownership boundary, findings, decision và validation outcome - không lưu transient thread id. `/checkpoint` hoặc `$codex-checkpoint` mang active delegation blocker tiếp vào `CONTEXT.md`, nhưng findings đã hoàn tất sống trong task file và cuối cùng đi vào `JOURNAL.md`.

## Command và skill

| Claude Code          | Codex CLI                  | Tác dụng                                                                                                                                                                                       |
| -------------------- | -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/start`             | `$codex-start`             | Boot session nhẹ - đọc CONTEXT, active tasks, knowledge INDEX và 3 commit gần nhất                                                                                                             |
| `/plan <task>`       | `$codex-plan <task>`       | Tạo implementation plan bền trong `tasks/` - thay cho plan mode gốc                                                                                                                            |
| `/project-discovery` | `$codex-project-discovery` | Planning theo kiểu phỏng vấn trước - biến ý tưởng thô thành project docs trước khi code                                                                                                        |
| `/refactor-memory`   | `$codex-refactor-memory`   | Gọt CLAUDE.md/AGENTS.md thành index nhẹ; phân loại durable content theo loại (behavior → rules/guidelines, facts → knowledge); bootstrap + re-verify knowledge tier                            |
| `/checkpoint`        | `$codex-checkpoint`        | Rebuild CONTEXT declarative + sync `tasks/index.md` + append JOURNAL + fact bền → `knowledge/`                                                                                                 |
| `/handoff`           | `$codex-handoff`           | Baton session single-slot (`HANDOFF.md`) distill trạng thái suy luận - giả thuyết, evidence, dead ends, next step có neo - khi context window sắp đầy; được lần start kế tiếp tiêu thụ rồi xóa |
| `/learn`             | `$codex-learn`             | Retrospective - thăng cấp lesson lặp lại thành rules/guidelines với ngôn ngữ đóng loophole                                                                                                     |
| `/doctor`            | `$codex-doctor`            | Health check read-only: cấu trúc, frontmatter, token hygiene, wiring, task hygiene và knowledge hygiene                                                                                        |

Review agent được cài kèm ở cả hai layer: `clean-code-reviewer` (scope + Clean Code discipline) và `security-auditor` (OWASP audit - read-only trên code của bạn, nhưng ghi findings vào report `security-audit-<date>.md` ở project root và chỉ in summary ra chat). Claude dùng tên agent Markdown dạng kebab-case; Codex dùng giá trị `name` snake_case trong TOML.

Subagent delegation được quản bởi `.claude/rules/agent-delegation.md` (Claude) và `.codex/guidelines/agent-delegation.md` (Codex). Config Codex được cài kèm (`.codex/config.toml`) giữ `[agents] max_depth = 1` và `max_threads = 6` (mặc định của Codex), để downstream project có parallelism hữu ích mà không bị recursive fan-out.

## Layout thư mục

```text
your-project/
├── AGENTS.md                       # Codex root loader (copy từ .codex/AGENTS.md khi install)
├── .agents/
│   └── skills/                     # Codex repo skills (codex-start, codex-plan, codex-checkpoint, ...)
├── .codex/
│   ├── AGENTS.md                   # Codex source template; được copy ra root AGENTS.md
│   ├── CONTEXT.md                  # Live state, declarative, ≤ 150 dòng
│   ├── HANDOFF.md                  # Baton session transient - chỉ tồn tại giữa $codex-handoff và lần $codex-start kế tiếp
│   ├── JOURNAL.md                  # Append-only audit log - không auto-load
│   ├── agents/                     # Codex TOML subagents
│   │   ├── clean-code-reviewer.toml
│   │   └── security-auditor.toml
│   ├── config.toml                 # Codex project defaults
│   ├── guidelines/                 # Codex-native semantic guidance
│   │   ├── ai-behavior.md
│   │   ├── agent-delegation.md
│   │   └── task-management.md
│   ├── knowledge/                  # Fact mô tả bền + external-doc pointers
│   │   └── INDEX.md                # Map hiển thị bởi $codex-start; topic files đọc khi cần
│   └── tasks/                      # Implementation plan bền (mỗi task một file)
│       ├── index.md                # Dashboard active + recently-done, ≤ 100 dòng
│       └── done/                   # Task completed/cancelled đã archive
└── .claude/
    ├── CLAUDE.md                   # Lightweight index (< 100 dòng)
    ├── CONTEXT.md                  # Live state, declarative, ≤ 150 dòng
    ├── HANDOFF.md                  # Baton session transient - chỉ tồn tại giữa /handoff và lần /start kế tiếp
    ├── JOURNAL.md                  # Append-only audit log - không auto-load
    ├── agents/
    │   ├── clean-code-reviewer.md
    │   └── security-auditor.md
    ├── commands/                   # Slash command protocols
    ├── knowledge/                  # Fact mô tả bền + external-doc pointers
    │   └── INDEX.md                # Map hiển thị bởi /start; topic files đọc khi cần
    ├── rules/
    │   ├── agent-delegation.md
    │   ├── ai-behavior.md
    │   └── task-management.md
    └── tasks/                      # Implementation plan bền (mỗi task một file)
        ├── index.md                # Dashboard active + recently-done, ≤ 100 dòng
        └── done/                   # Task completed/cancelled đã archive
```
