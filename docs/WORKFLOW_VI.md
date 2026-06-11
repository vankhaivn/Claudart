# Quy trình CLAUDART

Đây là manual. [README tiếng Việt](../README_VI.md) là phần giới thiệu; tài liệu này giải thích cách các mảnh thật sự vận hành - hai layer, mô hình memory, lifecycle của task, từng command, và mỗi file nằm ở đâu.

## Mục lục

- [Hai layer](#hai-layer)
- [Mô hình memory - pipeline thăng cấp](#mô-hình-memory---pipeline-thăng-cấp)
- [Session handoff - sống sót qua tràn context](#session-handoff---sống-sót-qua-tràn-context)
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

CLAUDART cài thành hai layer song song. Chúng không phụ thuộc vào nhau - cài một layer, hoặc cả hai, và thứ duy nhất chúng chia sẻ là lịch sử git nơi chúng được commit.

- **Claude layer** (`.claude/`): slash command, rule, review agent, session state
- **Codex layer** (`.codex/` + `.agents/skills/`): guideline, TOML subagent, repo skill

Mỗi command của Claude đều có một Codex skill đi theo cùng protocol. Khi hai runtime thật sự khác nhau, hướng dẫn cũng khác theo. Ví dụ subagent delegation được viết hai lần có chủ đích: `.claude/rules/agent-delegation.md` nói với Agent tool của Claude, còn `.codex/guidelines/agent-delegation.md` nói với mô hình explorer/worker của Codex. Giả vờ chúng là cùng một tool thì chẳng giúp ai cả.

## Mô hình memory - pipeline thăng cấp

Project memory được chia theo thời gian những điều đó còn đúng:

```text
CONTEXT.md       JOURNAL.md          rules/ · guidelines/      knowledge/
("ngay lúc này") ("đã xảy ra gì")    ("cách hành xử")          ("dự án là gì")
```

`CONTEXT.md` nói điều đang đúng ngay lúc này. `/checkpoint` (Codex: `$codex-checkpoint`) viết lại file này ở cuối session - viết lại, không append. Khi điều gì không còn đúng, nó bị bỏ ra, và file có trần cứng 150 dòng để giữ nguyên tắc đó trung thực.

`JOURNAL.md` là kho lưu: append-only, mỗi item đã retire một dòng, và không bao giờ được load vào session. Nghe có vẻ lãng phí cho tới khi bạn thấy lợi ích: lịch sử tồn tại cho các lần audit hiếm hoi, không phải để đốt token ở mọi prompt.

`rules/` (Claude) và `guidelines/` (Codex) giữ hành vi: những pattern prescriptive kiểu "luôn làm X" đã lặp lại đủ nhiều để xứng đáng có chỗ vĩnh viễn. `/learn` là cách chúng đi vào đó.

`knowledge/` giữ fact: dự án là gì, được nối dây ra sao, các thuật ngữ nghĩa là gì. Rule quy định, knowledge mô tả - tách hai thứ này ra là cách ngăn cả hai mục ruỗng. Mỗi topic một file, và chỉ `knowledge/INDEX.md` được hiển thị lúc bắt đầu session; file chi tiết chờ tới khi task thật sự cần. Khi đã có canonical doc ở nơi khác, knowledge entry trỏ tới nó thay vì copy lại, để không stale vì bản sao.

Đường thăng cấp: một ghi chú bắt đầu đời trong `CONTEXT.md`. Nếu nó ổn định thành lịch sử, một dòng đi vào `JOURNAL.md`. Nếu hóa ra là fact bền, `/checkpoint` đưa nó vào `knowledge/`. Nếu đó là hành vi đáng lặp lại, `/learn` biến nó thành rule. Chỉ `CONTEXT.md` và rules được auto-load - mọi thứ khác chờ được hỏi tới.

Không phần nào trong hệ này sống sót nếu không được bảo trì, nên có hai command để chống mục ruỗng. `/doctor` là read-only: nó flag fact stale, link `sources:`/`related:` chết, nội dung trùng lặp và những thứ bị đặt sai tầng. `/refactor-memory` xử lý các flag đó - nó kiểm lại từng fact với code hiện tại, gom duplicate, và chuyển nội dung qua lại qua ranh giới descriptive/prescriptive theo cả hai chiều (fact trốn trong rule thì về `knowledge/`; rule lọt vào knowledge thì quay lại). Không có gì bị xóa tự động. Drift được đưa ra ánh sáng; bạn quyết định.

Một chi tiết khiến việc kiểm tra khả thi: mỗi knowledge entry mang anchor `sources:` hoặc `verify:` trỏ tới thứ nó tóm tắt, để `/doctor` có thể test claim thay vì đoán.

## Session handoff - sống sót qua tràn context

Bốn tầng ở trên lưu trạng thái _dự án_. Một session đang giữa lúc debug khó còn mang một thứ khác hẳn: working hypothesis, evidence phía sau nó, các hướng đã thử và loại trừ, bước kế tiếp chính xác. Trạng thái suy luận đó chết khi context window đầy. `/compact` gốc sẽ tóm tắt nó tại chỗ, nhưng bản tóm tắt vô hình, không review được, biến mất khi session kết thúc, và bị khóa vào một tool.

`/handoff` (Codex: `$codex-handoff`) ghi nó ra disk thay vào đó - một file, `.claude/HANDOFF.md` hoặc `.codex/HANDOFF.md`, với schema cố định: Objective, State of Play, Working Hypothesis, Evidence dạng anchor `file:line`, Dead Ends kèm lý do từng hướng bị loại, User Constraints, Next Step, Open Questions.

Ba rule giữ baton trung thực:

- Ràng buộc user đã nêu, yêu cầu gần nhất của user, và câu quote chỉ nơi công việc dừng lại được giữ nguyên văn. Mọi thứ khác được distill. Handoff không bao giờ là transcript dump.
- Bước kế tiếp đã ghi phải truy về yêu cầu mới nhất của user, có quote đi kèm, để session resume không trôi sang hướng khác.
- Nội dung bền được route ra trước - fact vào `knowledge/`, phát hiện thuộc task vào Memory Hints của task file. Baton chỉ giữ phần suy luận không có nơi bền nào để sống.

Lifecycle được cố tình giữ ngắn. Ghi baton mới sẽ ghi đè baton cũ. Lần `/start` kế tiếp hiển thị nó, kiểm chứng claim với code hiện tại, và xóa nó khi công việc đã được nhặt lên. Một file, một lượt chuyền, không bao giờ là archive - tóm tắt lặp lại sẽ mất mát lũy tiến, đó cũng là lý do `/doctor` flag baton nằm quá 7 ngày chưa được tiêu thụ.

Handoff bổ sung cho `/checkpoint` chứ không thay thế nó. Checkpoint ghi điều đang đúng về dự án; handoff ghi cuộc hội thoại đang nghĩ gì. Dùng handoff khi context window gần đầy hoặc khi bạn pause giữa một cuộc điều tra - không phải như nghi thức cuối session.

## Workflow task bền

Plan mode gốc (Shift+Tab trong Claude Code, `/plan` trong Codex CLI) giữ plan trong chat. Đóng terminal là plan biến mất; pause một ngày là codebase đã trôi khỏi bên dưới nó.

CLAUDART giữ plan trong file thay vào đó - mỗi task một markdown document dưới `.claude/tasks/` hoặc `.codex/tasks/`, được version giống mọi thứ khác:

```text
/plan <task>  →  tasks/<YYYY-MM-DD-NNN-slug>.md  →  tasks/done/<NNN-slug>.md  →  JOURNAL.md
 (tạo)            (lifecycle: planning → in-progress →    (archive sau khi     (record một dòng)
                   awaiting-review → done)                 user xác nhận)
```

### Cấu trúc task file

Task file được viết để self-contained: chỉ đọc nó thôi cũng đủ resume công việc vài ngày sau, kể cả khi đã có commit không liên quan land vào. Các section:

- **Frontmatter** - `slug`, `status`, `created`, `updated`, `agent`, `tags`
- **Purpose** - ai nhận được lợi ích gì, và làm sao thấy nó hoạt động
- **Context & Orientation** - `Related Code`, `Related Docs`, và `Memory Hints`
- **Plan of Work** - narrative bằng prose về trình tự và vì sao nó được sắp như vậy
- **Concrete Steps** - checklist có thứ tự, timestamp UTC trên item đã hoàn tất
- **Validation & Acceptance** - tiêu chí thành công quan sát được (command, manual check)
- **Decision Log** - lựa chọn không hiển nhiên, cùng các phương án đã bị loại
- **Surprises & Discoveries** - nơi thực tế lệch khỏi plan
- **Outcomes & Retrospective** - điền khi hoàn tất

Memory Hints đáng được nhắc riêng: đó là ghi chú tự do từ session này cho session sau, và chính section này giúp session tương lai không phải tái khám phá cùng constraint, cùng quirk của thư viện, cùng pitfall. Khi phân vân, hãy ghi nó vào đây.

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

Hai trạng thái trong số này là read-only lock. Ở `planning` và `awaiting-review`, agent chỉ được edit task file và không edit gì khác - không code. `planning` nghĩa là plan chưa được approve; `awaiting-review` nghĩa là agent tin rằng đã xong còn bạn chưa xác nhận.

### Cổng hoàn tất hai pha

Phần lớn agent workflow cho phép agent tự chấm bài của mình, rồi bug thật xuất hiện sau khi checkbox xanh đã nằm trong log. CLAUDART tách completion thành hai pha:

**Pha 1 - agent báo cáo** (`in-progress → awaiting-review`). Khi mọi checkbox đã tick, agent draft section Outcomes, đổi status, báo cho bạn, rồi dừng. Chưa archive, chưa có JOURNAL entry.

**Pha 2a - bạn xác nhận** (`awaiting-review → done`). Bạn verify thật: chạy app, check build, đọc diff. Nói "approved" hoặc "looks good" hoặc "ok đóng", và agent archive task - file vào `done/`, một dòng vào JOURNAL, index được update.

**Pha 2b - bạn báo vấn đề** (`awaiting-review → in-progress`). Thấy bug? Cứ nói. Report của bạn được đưa nguyên văn vào Surprises & Discoveries, các step sai được uncheck, và agent quay lại làm. Vòng Phase 1 ↔ 2b có thể lặp nhiều lần. Đó là gate đang bắt bug thật, không phải hệ thống thất bại.

### Tín hiệu phê duyệt

Agent đọc ngôn ngữ tự nhiên, không phải slash command:

| Transition                      | Bạn nói gì                                                                   |
| ------------------------------- | ---------------------------------------------------------------------------- |
| `planning → in-progress`        | "go", "approved", "implement", "do it", "ok làm đi", "start"                 |
| `awaiting-review → done`        | "approved", "confirmed", "looks good", "close it", "done", "ship", "ok đóng" |
| `awaiting-review → in-progress` | Bất kỳ báo cáo vấn đề nào - "didn't work", "broken", "missed X"              |
| `* → cancelled`                 | "cancel", "abandon", "drop this", "bỏ task"                                  |

Hào hứng không phải approval - "nice plan!" giữ task ở `planning`. Câu hỏi cũng không phải approval, và việc bạn tự sửa task file cũng vậy. Các tín hiệu trên là bắt buộc.

### Resume qua session khác

Một session mới khi resume task:

1. Đọc toàn bộ task file. File được thiết kế self-contained.
2. Kiểm tra các step đã hoàn tất vẫn đúng với code hiện tại - commit không liên quan có thể đã move file hoặc đổi API kể từ đó.
3. Ghi drift vào Surprises & Discoveries và hỏi nên adapt plan hay xem lại step cũ.
4. Chỉ sau đó mới tiếp tục từ step chưa check tiếp theo.

File là snapshot, không phải bảo đảm. Verify trước khi tiếp tục là cách giữ một plan ba ngày tuổi khỏi âm thầm chạy trên codebase đã không còn khớp.

## Subagent delegation

Cả hai layer đều có thể fan work out cho subagent - khảo sát song song, triển khai có giới hạn, review, audit. CLAUDART xem đây là parallelism đã được cho phép, không phải mặc định: "be thorough" không spawn agent; "use subagents" thì có.

Mỗi runtime có protocol viết theo mechanics riêng (`.claude/rules/agent-delegation.md` cho Agent tool của Claude, `.codex/guidelines/agent-delegation.md` cho mô hình explorer/worker của Codex). Chúng chia sẻ một xương sống:

- **Decomposition gate.** Trước khi spawn bất kỳ thứ gì, parent ghi ra critical path nó sẽ làm local, các sidecar task có giới hạn có thể chạy song song, chính xác file hoặc câu hỏi mỗi subagent sở hữu, và kết quả quay về thế nào. Nếu bước kế tiếp đang bị chặn bởi subtask, không có gì để parallelize - làm local.
- **Delegate-and-consume vs. delegate-and-continue.** Đánh giá theo cấu trúc task, không theo wording của user. Khi câu hỏi được delegate _chính là_ toàn bộ task, spawn một agent và chờ - tự chạy cùng investigation song song là trả tiền hai lần cho một câu trả lời. Chỉ fan out khi request chia được thành các unit không chồng lấn. Dấu hiệu đáng tin là overlap: nếu bước kế tiếp của bạn trả lời câu hỏi mà subagent đã own, đó là dư thừa, không phải parallelism. Redundancy có chủ đích thì được nếu đã nói rõ (independent cross-review, hedge user yêu cầu); redundancy âm thầm thì không.
- **Ownership discipline.** Explorer ở read-only. Parallel writer nhận scope tách biệt - với Claude, mỗi writer có git worktree riêng. Findings của reviewer và auditor vẫn thuộc trách nhiệm parent, parent validate trước khi integrate. Patch từ subagent không bao giờ là final nếu chưa được parent review.

Phần sống sót sau đó đi vào task document: ai authorize việc gì, role, ownership boundary, findings, validation outcome. Không bao giờ lưu transient thread id - `/checkpoint` mang active delegation blocker tiếp vào `CONTEXT.md`, và findings đã hoàn tất sống trong task file cho tới khi retire vào `JOURNAL.md`.

## Command và skill

| Claude Code          | Codex CLI                  | Tác dụng                                                                                                                                                                                          |
| -------------------- | -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/start`             | `$codex-start`             | Boot session nhẹ - đọc CONTEXT, active tasks, knowledge INDEX và 3 commit gần nhất                                                                                                                |
| `/plan <task>`       | `$codex-plan <task>`       | Tạo implementation plan bền trong `tasks/` - thay cho plan mode gốc                                                                                                                               |
| `/project-discovery` | `$codex-project-discovery` | Planning theo kiểu phỏng vấn trước - biến ý tưởng thô thành project docs trước khi code                                                                                                           |
| `/refactor-memory`   | `$codex-refactor-memory`   | Gọt CLAUDE.md/AGENTS.md thành index nhẹ; đưa durable content về đúng loại (behavior → rules/guidelines, facts → knowledge); bootstrap + kiểm chứng lại knowledge tier                             |
| `/checkpoint`        | `$codex-checkpoint`        | Rebuild CONTEXT declarative + sync `tasks/index.md` + append JOURNAL + fact bền → `knowledge/`                                                                                                    |
| `/handoff`           | `$codex-handoff`           | Baton session single-slot (`HANDOFF.md`) distill trạng thái suy luận - giả thuyết, evidence, dead ends, next step có anchor - khi context window gần đầy; được lần start kế tiếp tiêu thụ rồi xóa |
| `/learn`             | `$codex-learn`             | Retrospective - thăng cấp lesson lặp lại thành rules/guidelines với ngôn ngữ đóng loophole                                                                                                        |
| `/doctor`            | `$codex-doctor`            | Health check read-only: cấu trúc, frontmatter, token hygiene, wiring, task hygiene và knowledge hygiene                                                                                           |

Cả hai layer cũng ship hai review agent. `clean-code-reviewer` enforce scope và kỷ luật Clean Code. `security-auditor` chạy audit map theo OWASP - read-only trên code của bạn, ghi findings vào report `security-audit-<date>.md` ở project root và chỉ in summary ra chat. Claude đặt tên agent bằng Markdown kebab-case; Codex dùng giá trị TOML `name` dạng snake_case.

Config Codex được ship kèm (`.codex/config.toml`) giữ `[agents] max_depth = 1` và `max_threads = 6` - mặc định của Codex - để downstream project có parallelism hữu ích mà một request nhỏ không vô tình fan out thành cây subagent đệ quy.

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
