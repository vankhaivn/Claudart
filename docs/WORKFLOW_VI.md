# Quy trình CLAUDART

Đây là manual. [README tiếng Việt](../README_VI.md) là phần giới thiệu; tài liệu này giải thích cách các mảnh thật sự vận hành - hai layer, mô hình memory, lifecycle của task, từng command, và mỗi file nằm ở đâu.

## Mục lục

- [Hai layer](#hai-layer)
- [Mô hình memory - pipeline thăng cấp](#mô-hình-memory---pipeline-thăng-cấp)
  - [Routing và capture knowledge](#routing-và-capture-knowledge)
  - [Knowledge contract và lifecycle](#knowledge-contract-và-lifecycle)
  - [Checker và đối soát project hiện hữu](#checker-và-đối-soát-project-hiện-hữu)
- [Session handoff - sống sót qua tràn context](#session-handoff---sống-sót-qua-tràn-context)
- [Workflow task bền](#workflow-task-bền)
  - [Cấu trúc task file](#cấu-trúc-task-file)
  - [State machine trạng thái](#state-machine-trạng-thái)
  - [Cổng hoàn tất hai pha](#cổng-hoàn-tất-hai-pha)
  - [Tín hiệu phê duyệt](#tín-hiệu-phê-duyệt)
  - [Resume qua session khác](#resume-qua-session-khác)
- [Spec workflow - mission trên tầng task](#spec-workflow---mission-trên-tầng-task)
- [Subagent delegation](#subagent-delegation)
- [Command và skill](#command-và-skill)
- [Layout thư mục](#layout-thư-mục)

## Hai layer

CLAUDART cài thành hai layer song song. Chúng không phụ thuộc vào nhau - cài một layer hoặc cả hai. Mỗi layer mang một bản Bash knowledge checker byte-identical, nên từng runtime vẫn tự hoạt động độc lập.

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

`knowledge/` giữ fact: dự án là gì, được nối dây ra sao, và thuật ngữ có nghĩa gì. Rule quy định; knowledge mô tả. Mỗi cụm fact có một topic owner, còn root `INDEX.md` và các `_maps/<domain>.md` tùy chọn route agent mà không load mọi topic. Reference topic trỏ tới canonical document đã tồn tại thay vì copy nó.

Checkpoint là boundary bảo trì hàng loạt, không phải cách duy nhất để ghi knowledge. User có thể nói “hãy cập nhật knowledge từ phần vừa xác minh rồi tiếp tục” bất kỳ lúc nào. Agent distill trước khi ghi: fact current, có evidence và sống lâu hơn phần việc hiện tại vào knowledge; task/WIP/proposed state ở task, spec hoặc `CONTEXT.md`; behavior lặp lại đi qua `/learn`; phần chưa chắc thành candidate hoặc hạ topic hiện hữu xuống `review-needed`.

### Routing và capture knowledge

`/start` chỉ đọc root INDEX. Các turn sau route theo từng tầng:

1. match topic id, alias, path/scope, trigger, rồi description/type;
2. load tối đa 2 domain map, 3 direct topic và 2 related topic một hop;
3. đọc frontmatter và heading outline trước body;
4. đọc section nhỏ nhất liên quan trước khi cân nhắc toàn topic hoặc canonical source.

Khi routed knowledge chưa đủ, agent có thể tìm actual evidence trong knowledge, archive task/spec, JOURNAL và Git bằng query `rg`/Git có giới hạn. Đây là fallback nội bộ, không phải command `/recall`, và không bao giờ write-on-read.

Phép thử capture không phụ thuộc bất kỳ project cụ thể nào:

> Nếu task hiện tại bị hủy ngày mai, claim đã verify này vẫn đúng và giúp một task khác không?

“Không” nghĩa là nó thuộc task/spec/session state. Fact vẫn có thể có scope thay vì global; dùng typed selector như `path:`, `component:`, `platform:`, `environment:`, `version:` hoặc `symbol:`.

Mỗi mutation patch owner hiện hữu trước khi tạo topic, cập nhật topic và route reachable trong cùng diff, rồi chạy checker của layer đó. Không workflow nào tự xóa knowledge hoặc đoán file unindexed mơ hồ là active, retired hay orphan.

### Knowledge contract và lifecycle

Mỗi topic dùng một grammar frontmatter tương thích YAML nhưng được giới hạn có chủ đích:

```yaml
---
name: example-service-contract
description: "Boundary minh họa cho một service giả lập."
type: domain
status: active
updated: YYYY-MM-DD
last_verified: YYYY-MM-DD
scope:
  - "path:examples/service/**"
sources:
  - "../../docs/example-service.md"
related:
  - "knowledge:example-adjacent-contract"
verify: "Kiểm tra lại khi contract của service giả lập thay đổi."
sensitivity: internal
---
```

Field bắt buộc là `name`, `description`, `type`, `status` và `updated`. Topic `active` còn cần `last_verified` cùng ít nhất một anchor `sources` hoặc `verify`. Field routing/lifecycle tùy chọn gồm `aliases`, `triggers`, `scope`, `sources`, `related`, `supersedes`, `verify`, `status_note` và `sensitivity`.

Free-text scalar là chuỗi double-quoted một dòng. List dùng block item thụt hai space, mỗi item double-quoted. Folded text, flow/multiline array, single quote, nested map, YAML anchor và inline comment nằm ngoài contract. Giới hạn này là cố ý: Bash checker hoặc parse field chính xác, hoặc báo lỗi; nó không giả làm general YAML parser.

Lifecycle:

- `active` - authority đã verify và reachable từ root router;
- `review-needed` - uncertainty/conflict hiển thị rõ cùng `status_note`; có thể vẫn được route nhưng không là authority trước khi verify;
- `superseded` - được thay qua typed edge `supersedes` và bỏ khỏi active routing;
- `retired` - lịch sử có chủ ý cùng `status_note`, không bao giờ là active route.

Root và domain map dùng dòng:

```text
- [Title](relative.md) — compact routing hook · <type|map> · <status>
```

Map được tạo khi store có hơn 24 active topic hoặc root vượt 1.200 visible words. Map không lồng nhau: root → map → topic. Topic trên 10 KiB thành candidate đọc outline/section trước và cân nhắc split; nó không bị tự split.

### Checker và đối soát project hiện hữu

`doctor` gọi `knowledge-check.sh` cho check deterministic - bounded frontmatter, route reachability, source/relation existence, lifecycle, source đổi sau `last_verified`, size và sensitivity budget - rồi mới audit phần ngữ nghĩa script không làm được. `refactor-memory` chạy checker trước và sau khi sửa. `start` không bao giờ chạy checker.

Checker read-only, offline, tương thích Bash 3.2 và không phụ thuộc Node, `jq`, `yq`, database, daemon hay network. Nó không quyết định claim đúng sai, merge/retire/xóa topic, fetch URL hoặc generate INDEX.

Với installation hiện hữu, `INTEGRATE.md` derive delta thực tế giữa upstream và downstream thay vì giả định bản khởi đầu. Khi knowledge contract cần đối soát, flow do upstream hiện tại khai báo giữ nguyên body topic cùng curated routing:

```text
doctor → refactor-memory → doctor
```

Bước giữa scan mọi topic và map, đối soát frontmatter đang có trên disk với contract hiện tại, đánh dấu fact đã verify là `active`, phần chưa giải quyết/conflict là `review-needed`, tạo domain map khi grouping có đủ evidence, và giữ file unindexed mơ hồ ở trạng thái chưa promote. Chạy lần hai khi source không đổi phải không tạo thêm diff.

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

- **Frontmatter** - `slug`, `status`, `created`, `updated`, `agent`, `delegation`, `tags`
- **Purpose** - mở đầu bằng yêu cầu của user được quote nguyên văn, rồi ai nhận được lợi ích gì và làm sao thấy nó hoạt động
- **Context & Orientation** - `Related Code`, `Related Docs`, và `Memory Hints`
- **Plan of Work** - narrative bằng prose về trình tự và vì sao nó được sắp như vậy
- **Concrete Steps** - checklist có thứ tự, mỗi step một check `(verify: …)`, timestamp UTC trên item đã hoàn tất
- **Validation & Acceptance** - tiêu chí thành công quan sát được (command, manual check)
- **Decision Log** - lựa chọn không hiển nhiên, cùng các phương án đã bị loại
- **Surprises & Discoveries** - nơi thực tế lệch khỏi plan
- **Outcomes & Retrospective** - điền khi hoàn tất

Memory Hints đáng được nhắc riêng: đó là ghi chú tự do từ session này cho session sau, và chính section này giúp session tương lai không phải tái khám phá cùng constraint, cùng quirk của thư viện, cùng pitfall. Khi phân vân, hãy ghi nó vào đây.

Toàn bộ file được viết ở **plan altitude**: nó chở quyết định (chọn gì, vì sao, đã loại gì), các ràng buộc không hiển nhiên, và một check verify cho mỗi step - không bao giờ chở lời giải. Không code snippet, không chỉ dẫn sửa từng dòng. Session thực thi tự suy ra _cách làm_, và `verify:` per-step bắt drift của nó ngay tại step xảy ra. Trước khi xin approval, `/plan` đọc lại file như thể cuộc hội thoại planning chưa từng tồn tại và chuyển mọi ngữ cảnh mà một step đang ngầm phụ thuộc vào Memory Hints.

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
2. Kiểm tra các step đã hoàn tất vẫn đúng với code hiện tại - chạy lại các check `verify:` của chúng khi rẻ; commit không liên quan có thể đã move file hoặc đổi API kể từ đó.
3. Ghi drift vào Surprises & Discoveries và hỏi nên adapt plan hay xem lại step cũ.
4. Chỉ sau đó mới tiếp tục từ step chưa check tiếp theo.

File là snapshot, không phải bảo đảm. Verify trước khi tiếp tục là cách giữ một plan ba ngày tuổi khỏi âm thầm chạy trên codebase đã không còn khớp.

## Spec workflow - mission trên tầng task

Một task file vừa cho một feature. Có những việc không vừa - cả một game, một hệ thống feature, một POC demo cho khách. Cho những việc đó, CLAUDART có một tầng phía trên `tasks/`: một **spec** là một mission sống trong `.claude/specs/YYYY-MM-DD-<slug>/` (Codex: `.codex/specs/YYYY-MM-DD-<slug>/`), được viết một lần bởi một session planning đắt tiền rồi được thực thi tới cổng final review qua nhiều session - thường trên model rẻ hơn - mà không cần approval từng task. Spec thay thế `/plan` trong phạm vi của nó: executor không bao giờ tạo task file, và hai tầng không bao giờ chạy chồng lên cùng một việc.

Mỗi mission là một folder:

- **`SPEC.md`** - "xong" nghĩa là gì: mission, các acceptance scenario nhị phân ("mở artifacts/poc.html → wave counter tăng", không phải "game chạy được"), và hàng rào scope Must-NOT-Have để chặn executor rẻ hơn khỏi gold-plating. Đóng băng khi approve; chỉ bạn được đổi nó.
- **`ROADMAP.md`** - các phase gồm task dạng checkbox, mỗi task có `verify:` riêng. Checkbox ghi disposition: việc pending để trống, việc hoàn tất được tick, việc superseded được tick + gạch kèm lý do, còn việc blocked để trống nhưng được đánh dấu không runnable với điều kiện gỡ chặn. Hoạt động task chỉ là inventory, không phải bằng chứng acceptance đang hội tụ.
- **`NOTES.md`** - working memory của mission: orientation, ràng buộc và bẫy, các quyết định giữa chừng, cộng thêm một Current Acceptance Delta ngắn, được key bằng scenario/gate ổn định đang fail (task chỉ là owner hiện tại). Được chăm sóc (curated) và đọc lại mỗi vòng lặp - tương đương Memory Hints + Decision Log của một task file, ở tầng spec.
- **`LEDGER.md`** - evidence và lịch sử append-only, không bao giờ được viết lại. Session mới đọc phần đuôi của nó để biết chuyện gì đã thật sự xảy ra; `task-started`/`delegated` chưa có completion, validation failure, blocker, supersession hoặc kết quả đã consume tương ứng đánh dấu việc đang dở dang khi session trước chết.
- **`artifacts/`** - POC và các reference đã đóng băng khác. Việc UI được verify với artifact đã approve, không phải với trí nhớ về một cuộc hội thoại.

`specs/INDEX.md` là registry - mỗi mission một dòng, được `/start` hiển thị. Flow như sau:

1. **`/spec <mission>`** phỏng vấn bạn và ghi ngay mỗi quyết định đã chốt vào SPEC.md - folder, chứ không phải cuộc chat, mới là thứ sống sót qua compaction. Sau đó nó chứng minh intent bằng POC artifact ở mức fidelity bạn chọn: mặc định là một trang HTML self-contained; với mission phức tạp thì là vài artifact hẹp (interaction lõi bằng placeholder thô, một reference style hình ảnh riêng) thay vì một bản high-fidelity duy nhất. Vòng review lặp tới khi bạn nói "đúng nó rồi", mỗi lượt cập nhật SPEC và POC cùng nhau. Artifact đã approve được đóng băng làm reference, rồi một roadmap **decision-complete** được viết ra: path chính xác, cách tiếp cận đã chọn kèm các phương án đã loại, một `verify:` cho mỗi task. Chuẩn là một session không có chút ngữ cảnh phỏng vấn nào vẫn thực thi được - nếu một task khiến phải hỏi "ý user là gì?", roadmap bị lỗi.
2. **Bạn approve một lần.** Nói "go" với SPEC + ROADMAP là một _standing approval_ phủ mọi task và phase - ngoại lệ tường minh so với các cổng per-task của workflow task. Từ đây executor không xin phép theo từng task hay từng phase. Blocker hoặc câu hỏi về scope chặn phần việc bị ảnh hưởng kèm điều kiện gỡ chặn chính xác, còn việc độc lập vẫn có thể tiếp tục; cả loop chỉ dừng khi không còn gì runnable. Approve cũng chốt luôn commit policy (`commits:` trong frontmatter SPEC): mặc định loop không bao giờ chạy `git commit`; chọn per-task hoặc per-phase nếu bạn muốn có điểm khôi phục git trong một run dài - push thì không bao giờ được cấp, bất kể policy nào.
3. **`/spec-run <slug>`** - tốt nhất chạy trong session mới - dẫn dắt loop: định hướng lại từ file (không bao giờ từ trí nhớ session), chọn task pending đầu tiên còn runnable, thực thi, verify trên bề mặt thật, ghi disposition và evidence vào LEDGER. Một acceptance fail chỉ được retry khi hypothesis, implementation hoặc verifier thay đổi đáng kể. Nếu không còn đường mới có cơ sở, task phụ trách được đánh dấu blocked và bỏ qua để làm việc độc lập khác; nếu không còn gì runnable, SPEC chuyển `blocked` kèm điều kiện gỡ chặn chính xác. Một check về sau đi qua acceptance trực tiếp hơn có thể vô hiệu kết quả false-green trước đó.
4. **Rotation, không phải compaction.** Ở mỗi ranh giới phase, executor báo phase hiện tại, inventory task và acceptance delta chưa giải quyết nếu có, rồi đề nghị checkpoint và rotate - bạn mở session mới, `/start`, rồi `/spec-run <slug>` lần nữa. SPEC + ROADMAP + NOTES + LEDGER _chính là_ baton; spec work không bao giờ ghi `HANDOFF.md`. Bạn cũng có thể ngắt session bất cứ lúc nào - một cú ngắt không khác gì crash, và bước re-orientation xử lý được.
5. **Cổng cuối.** Khi mọi task đã hoàn tất hoặc được supersede tường minh và không còn blocker, cổng cuối đầu tiên thiết lập một baseline fresh đầy đủ: mọi acceptance scenario phải có evidence mới, bằng tập lệnh nhỏ nhất không trùng lặp nhưng cùng nhau bao phủ tất cả scenario. Một lệnh tổng hợp chỉ được thay cho các leaf check khi evidence cho thấy các check đó đã chạy và failure của chúng được propagate. Chỉ khi toàn bộ tập scenario có evidence PASS thì acceptance delta mới được xoá và spec chuyển sang `awaiting-final-review`; executor dừng để bạn - không phải agent - xác nhận `done`. Nếu feedback trong final review mở lại mission sau baseline đó, gate tiếp theo được scope theo ảnh hưởng thay vì mặc định chạy full: executor ghi lại bề mặt thay đổi thực tế, map ảnh hưởng trực tiếp, lan truyền và dùng chung của nó tới các scenario và gate bị tác động, chạy mới tập đó, và chỉ reuse evidence baseline cho những scenario có bề mặt liên quan cùng dependency không đổi. Một cumulative pass nghĩa là mọi scenario vẫn có evidence hợp lệ, không phải mọi lệnh đều vừa được chạy lại. Nếu không thể bảo vệ ranh giới ảnh hưởng hoặc evidence trước đó có thể không còn hợp lệ, executor quay về cổng fresh đầy đủ. Gate fail hoặc defect user báo có anchor trong SPEC/POC đã approve sẽ mở lại implementation work hiện đang phụ trách; các defect được gom thành một batch trước một cumulative gate, không sinh cặp task fix/replay cơ học. Một review patch tường minh, có giới hạn và vẫn phù hợp với intent đã approve chỉ mở lại lượng việc hoàn chỉnh nhỏ nhất cần thiết; nó không cho phép tự kéo thêm hardening, tài liệu, refactor, tooling hoặc validation machinery lân cận trừ khi request hoặc contract đã approve yêu cầu. Feedback đổi intent, xung đột với hàng rào scope hoặc đòi hỏi một quyết định thiết kế đáng kể phải quay lại sửa SPEC và approve lại, không âm thầm nới standing approval. Đóng mission cũng quét NOTES: các phát hiện vượt qua knowledge capture gate, kể cả fact được scope chính xác, sẽ graduate lên `knowledge/`; bài học lặp lại thành đề xuất `/learn` - không có gì bền vững chết kẹt trong folder mission.

Mỗi scoped gate thành công ghi lại revision kết quả hoặc fingerprint có giới hạn của worktree, rồi trở thành baseline evidence tích luỹ cho thay đổi review kế tiếp; chuỗi baseline vẫn phải truy ngược được về một full baseline xác định. Nhờ vậy patch nhỏ thứ hai không vô tình reuse evidence có từ trước patch nhỏ thứ nhất.

Contract chuẩn - schema folder, state machine trạng thái, circuit breaker, rotation - nằm trong [`.claude/rules/spec-workflow.md`](../.claude/rules/spec-workflow.md) và [`.codex/guidelines/spec-workflow.md`](../.codex/guidelines/spec-workflow.md).

## Subagent delegation

Cả hai layer đều có thể fan work out cho subagent - khảo sát song song, triển khai có giới hạn, review, audit - và **cả hai giao quyết định _có nên_ delegate cho active harness cùng project/skill instruction phù hợp.** CLAUDART ghi strategy và ownership nhưng không hardcode model tier hoặc biến strategy thành permission switch. Protocol được ship xử lý mechanics của từng runtime: parent Claude có thể tiếp tục lane thật sự độc lập trong lúc agent chạy, còn protocol Codex mặc định spawn → chờ → consolidate cho phần việc đã delegate.

Mỗi runtime có protocol viết theo mechanics riêng (`.claude/rules/agent-delegation.md` cho Agent tool của Claude, `.codex/guidelines/agent-delegation.md` cho mô hình explorer/worker của Codex). Một khi delegation _đang_ diễn ra, chúng chia sẻ một xương sống:

- **Decompose trước khi fan out.** Trước khi spawn bất kỳ thứ gì, parent ghi ra critical path nó sẽ làm local, các sidecar task có giới hạn có thể chạy song song, chính xác file hoặc câu hỏi mỗi subagent sở hữu, và kết quả quay về thế nào. Đây là hướng dẫn chiến lược, không phải permission gate. Nếu bước kế tiếp đang bị chặn bởi subtask, không có gì để parallelize - làm local.
- **Delegate-and-consume vs. delegate-and-continue.** Đánh giá theo cấu trúc task, không theo wording của user. Khi câu hỏi được delegate _chính là_ toàn bộ task, spawn một agent và chờ - tự chạy cùng investigation song song là trả tiền hai lần cho một câu trả lời. Chỉ fan out khi request chia được thành các unit không chồng lấn. Dấu hiệu đáng tin là overlap: nếu bước kế tiếp của bạn trả lời câu hỏi mà subagent đã own, đó là dư thừa, không phải parallelism. Redundancy có chủ đích thì được nếu đã nói rõ (independent cross-review, hedge user yêu cầu); redundancy âm thầm thì không.
- **Ownership discipline.** Explorer ở read-only. Parallel writer nhận scope tách biệt - với Claude, mỗi writer có git worktree riêng. Findings của reviewer và auditor vẫn thuộc trách nhiệm parent, parent validate trước khi integrate. Patch từ subagent không bao giờ là final nếu chưa được parent review.
- **Kết quả quay về từng cái một.** Patch trả về được integrate theo thứ tự phụ thuộc, validate sau mỗi lần merge - gộp N patch rồi test một lần khiến lỗi không quy được trách nhiệm. Worker trả kết quả sai được retry đúng một lần với prompt đã siết lại; sau đó parent kéo unit về tự làm local.

Phần sống sót sau đó đi vào task document: delegation strategy, role, ownership boundary, findings, validation outcome - và bản thân delegation được ghi vào đó ngay lúc spawn, nên compaction hay handoff không bao giờ làm mồ côi một subagent đang chạy. Không bao giờ lưu transient thread id - `/checkpoint` mang active delegation blocker tiếp vào `CONTEXT.md`, và findings đã hoàn tất sống trong task file cho tới khi retire vào `JOURNAL.md`.

## Command và skill

| Claude Code          | Codex CLI                  | Tác dụng                                                                                                                                                                                          |
| -------------------- | -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/start`             | `$codex-start`             | Boot session nhẹ - đọc CONTEXT, active tasks, root knowledge router (không đọc hết topic) và 3 commit gần nhất                                                                                    |
| `/plan <task>`       | `$codex-plan <task>`       | Tạo implementation plan bền trong `tasks/` - thay cho plan mode gốc                                                                                                                               |
| `/spec <mission>`    | `$codex-spec <mission>`    | Planning quy mô mission - phỏng vấn → POC artifact lặp cùng bạn → SPEC + ROADMAP decision-complete trong `specs/`, approve một lần như standing approval                                          |
| `/spec-run <slug>`   | `$codex-spec-run <slug>`   | Thực thi spec đã approve tự chủ tới cổng final review - verify acceptance, ghi disposition ROADMAP và evidence, chặn loop fail không đổi, đề nghị rotation ở ranh giới phase                      |
| `/project-discovery` | `$codex-project-discovery` | Planning theo kiểu phỏng vấn trước - biến ý tưởng thô thành project docs trước khi code                                                                                                           |
| `/refactor-memory`   | `$codex-refactor-memory`   | Chuẩn hóa in-place, idempotent: gọt root index, phân loại durable content, curate map, chạy knowledge checker trước và sau                                                                        |
| `/checkpoint`        | `$codex-checkpoint`        | Rebuild CONTEXT declarative + sync index task/spec + append JOURNAL + bulk-distill các fact bền còn lại; không phải knowledge write boundary duy nhất                                             |
| `/handoff`           | `$codex-handoff`           | Baton session single-slot (`HANDOFF.md`) distill trạng thái suy luận - giả thuyết, evidence, dead ends, next step có anchor - khi context window gần đầy; được lần start kế tiếp tiêu thụ rồi xóa |
| `/learn`             | `$codex-learn`             | Retrospective về behavior - thăng cấp cách làm việc lặp lại thành rules/guidelines; fact dự án ở lại knowledge                                                                                    |
| `/doctor`            | `$codex-doctor`            | Health check read-only: Bash checker deterministic trước, rồi audit drift ngữ nghĩa, phân loại, wiring, task và token hygiene                                                                     |

Cả hai layer cũng ship ba review agent, mỗi cái **chỉ được gọi đích danh theo yêu cầu rõ ràng - không bao giờ tự động, kể cả bên trong một task hay spec loop**. `clean-code-reviewer` enforce scope và kỷ luật Clean Code. `security-auditor` chạy audit map theo OWASP - read-only trên code của bạn, ghi findings vào report `security-audit-<date>.md` ở project root và chỉ in summary ra chat. `ui-visual-critic` là bản review thiết kế kiểu "con mắt người" đối kháng cho UI hoặc visual đã render (nặng về thị giác và tốn quota, nên nó luôn chỉ chạy on-demand). Claude đặt tên agent bằng Markdown kebab-case; Codex dùng giá trị TOML `name` dạng snake_case.

Config Codex được ship kèm (`.codex/config.toml`) giới hạn `[agents] max_concurrent_threads_per_session` ở 6 để downstream project có parallelism hữu ích mà một request nhỏ không vô tình fan out thành cây subagent tốn kém. Delegation giữ ở một cấp theo protocol trừ khi user yêu cầu đệ quy rõ ràng.

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
│   │   ├── security-auditor.toml
│   │   └── ui-visual-critic.toml
│   ├── config.toml                 # Codex project defaults
│   ├── guidelines/                 # Codex-native semantic guidance
│   │   ├── ai-behavior.md
│   │   ├── agent-delegation.md
│   │   ├── knowledge-management.md
│   │   ├── spec-workflow.md
│   │   └── task-management.md
│   ├── knowledge/                  # Fact mô tả bền + external-doc pointers
│   │   ├── INDEX.md                # Root router hiển thị bởi $codex-start; topic files đọc khi cần
│   │   └── _maps/                  # Domain map tùy chọn cho knowledge store lớn
│   ├── scripts/
│   │   └── knowledge-check.sh      # Checker cấu trúc read-only, không dependency
│   ├── specs/                      # Workspace spec quy mô mission (SPEC + ROADMAP + NOTES + LEDGER + artifacts/ mỗi mission)
│   │   └── INDEX.md                # Registry hiển thị bởi $codex-start; mỗi mission một dòng
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
    │   ├── security-auditor.md
    │   └── ui-visual-critic.md
    ├── commands/                   # Slash command protocols
    ├── knowledge/                  # Fact mô tả bền + external-doc pointers
    │   ├── INDEX.md                # Root router hiển thị bởi /start; topic files đọc khi cần
    │   └── _maps/                  # Domain map tùy chọn cho knowledge store lớn
    ├── rules/
    │   ├── agent-delegation.md
    │   ├── ai-behavior.md
    │   ├── knowledge-management.md
    │   ├── spec-workflow.md
    │   └── task-management.md
    ├── scripts/
    │   └── knowledge-check.sh      # Checker cấu trúc read-only, không dependency
    ├── specs/                      # Workspace spec quy mô mission (SPEC + ROADMAP + NOTES + LEDGER + artifacts/ mỗi mission)
    │   └── INDEX.md                # Registry hiển thị bởi /start; mỗi mission một dòng
    └── tasks/                      # Implementation plan bền (mỗi task một file)
        ├── index.md                # Dashboard active + recently-done, ≤ 100 dòng
        └── done/                   # Task completed/cancelled đã archive
```
