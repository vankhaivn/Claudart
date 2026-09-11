# Hướng dẫn quy trình CLAUDART

[English](WORKFLOW.md) · [README tiếng Việt](../README_VI.md)

Tài liệu này hướng dẫn cách sử dụng CLAUDART sau khi cài đặt. Nội dung tập trung vào quy trình vận hành: phiên làm việc bắt đầu ra sao, thông tin nên được lưu ở đâu, khi nào cần tạo task hoặc spec, và cách tiếp tục công việc qua nhiều phiên.

Các hợp đồng chi tiết dành cho máy vẫn nằm trong chính các file runtime:

- Claude Code: `.claude/commands/` và `.claude/rules/`
- Codex CLI: `.agents/skills/` và `.codex/guidelines/`

Khi schema hoặc lifecycle của một command thay đổi, các file đó là nguồn chuẩn.

## 1. Chọn lớp runtime

CLAUDART cung cấp hai lớp độc lập.

| Runtime     | File được cài                                           | Dạng command                        | File nạp chính      |
| ----------- | ------------------------------------------------------- | ----------------------------------- | ------------------- |
| Claude Code | `.claude/`                                              | `/start`, `/plan`, v.v.             | `.claude/CLAUDE.md` |
| Codex CLI   | `.codex/`, `.agents/skills/`, `AGENTS.md` ở thư mục gốc | `$codex-start`, `$codex-plan`, v.v. | `AGENTS.md`         |

Bạn có thể cài một lớp hoặc cả hai. Hai lớp có cùng mục tiêu, nhưng command và quy tắc delegation được viết theo cách vận hành riêng của từng công cụ.

Cả hai lớp đều có cùng một knowledge checker viết bằng Bash, không cần dependency ngoài. CLAUDART không cần cơ sở dữ liệu hay tiến trình chạy nền.

## 2. Cài đặt hoặc tích hợp

### Dự án mới

```bash
# Claude Code, lựa chọn mặc định
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash

# Codex CLI
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --codex

# Cả hai runtime
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --both
```

Trình cài đặt sao chép file còn thiếu và bỏ qua file đã tồn tại, trừ khi bạn truyền `--force`. Cách này phù hợp với bản cài mới, không phù hợp để hợp nhất một cấu hình đã tùy chỉnh.

Với bản cài Codex mới, trình cài đặt sao chép file mẫu `.codex/AGENTS.md` thành `AGENTS.md` ở thư mục gốc rồi xóa bản mẫu trùng lặp.

### Dự án đã có cấu hình hoặc cần nâng cấp

Dùng [INTEGRATE.md](../INTEGRATE.md). Quy trình tích hợp yêu cầu agent:

1. so sánh dự án hiện tại với repository upstream hiện tại;
2. phân biệt file không đổi, template CLAUDART đã cũ và nội dung riêng do dự án viết;
3. trình bày rõ file nào sẽ được thêm, thay thế, hợp nhất, di chuyển hoặc loại bỏ;
4. chờ phê duyệt trước khi ghi;
5. giữ nguyên trạng thái đang dùng, workspace task và file đính kèm, spec và knowledge của dự án;
6. chạy chuỗi đối soát hiện hành sau khi áp dụng thay đổi đã được duyệt.

Prompt gợi ý:

> Đọc https://raw.githubusercontent.com/vankhaivn/Claudart/main/INTEGRATE.md và làm theo để tích hợp hoặc cập nhật CLAUDART trong dự án này. Giữ nguyên nội dung riêng của dự án và trình bày các thay đổi dự kiến trước khi ghi file.

### Đối soát ban đầu

Sau khi cài hoặc nâng cấp, chạy một lần chuỗi sau:

```text
Claude: /doctor → /refactor-memory → /doctor
Codex:  $codex-doctor → $codex-refactor-memory → $codex-doctor
```

`doctor` kiểm tra cấu trúc và tính nhất quán về ngữ nghĩa. `refactor-memory` chuẩn hóa bộ nhớ ngay tại chỗ. Lần `doctor` thứ hai xác nhận trạng thái sau chuẩn hóa.

## 3. Một phiên làm việc thông thường

Một phiên thường có dạng:

```text
start
  ↓
chọn làm trực tiếp, tạo task plan hoặc tạo spec
  ↓
triển khai và kiểm tra
  ↓
handoff chỉ khi cần tiếp tục phần điều tra trong phiên mới
  ↓
checkpoint tại một điểm dừng có ý nghĩa
  ↓
user review và đóng công việc
```

### Bắt đầu bằng bước định hướng

Chạy `/start` hoặc `$codex-start`.

Command start đọc:

- trạng thái hiện tại trong `CONTEXT.md`;
- index của task và spec;
- root knowledge index, không đọc toàn bộ topic;
- một phần nhỏ lịch sử Git gần nhất;
- `HANDOFF.md` còn tồn tại, nếu có.

Start không chạy knowledge checker. Mục tiêu của nó là khởi động nhẹ và nhanh.

### Chọn đúng chế độ làm việc

| Chế độ        | Dùng khi                                                                             | Nơi lưu                               |
| ------------- | ------------------------------------------------------------------------------------ | ------------------------------------- |
| Làm trực tiếp | Thay đổi nhỏ, rõ ràng, ít rủi ro và không cần kế hoạch bền vững                      | Cuộc trò chuyện và lịch sử repository |
| Task plan     | Triển khai cần kế hoạch bền vững, quyết định đáng lưu hoặc user yêu cầu plan rõ ràng          | `tasks/<task-id>/TASK.md`               |
| Spec          | Công việc cấp mission cần ý định được duyệt chung và roadmap thực thi nhiều phase | Một thư mục trong `specs/`            |

Số lượng file không tự tạo ra nhu cầu lập plan. Cần JSON, ảnh hay archive không đồng nghĩa với cần spec. Khi user yêu cầu plan cho việc nhỏ, giữ plan ngắn và chỉ có `TASK.md` trừ khi thực sự cần file hỗ trợ.

Trong phạm vi đã được phê duyệt, spec thay thế task plan. Không tạo task file cho công việc đã thuộc một spec đang hoạt động.

### Kết thúc hoặc tạm dừng đúng cách

Dùng `/checkpoint` hoặc `$codex-checkpoint` tại một điểm dừng phù hợp. Checkpoint xây dựng lại trạng thái hiện tại, đồng bộ các index, ghi lịch sử đã kết thúc và chắt lọc những fact đủ điều kiện để lưu lâu dài.

Chỉ dùng `/handoff` hoặc `$codex-handoff` khi một phần điều tra khó cần được tiếp tục trong phiên mới. Handoff ghi giả thuyết hiện tại, bằng chứng, các hướng đã loại, ràng buộc và bước tiếp theo chính xác. Nó không phải bản tóm tắt chung cho mọi phiên.

## 4. Bộ nhớ và knowledge

CLAUDART tách thông tin theo mục đích và thời gian tồn tại.

| Nơi lưu                     | Chứa                                                     | Không chứa                                               |
| --------------------------- | -------------------------------------------------------- | -------------------------------------------------------- |
| `CONTEXT.md`                | Các fact hiện tại cần để tiếp tục công việc ngay         | Lịch sử dài hoặc tài liệu tham chiếu ổn định             |
| `JOURNAL.md`                | Lịch sử ngắn gọn của trạng thái đã kết thúc              | Chỉ dẫn cần nạp ở mọi phiên                              |
| `rules/` hoặc `guidelines/` | Hành vi mang tính quy định: agent nên làm việc thế nào   | Fact mô tả dự án                                         |
| `knowledge/`                | Fact bền vững, có bằng chứng về dự án                    | Kế hoạch tạm thời, đề xuất hoặc phỏng đoán chưa xác minh |
| `tasks/`                    | Trạng thái và quyết định của một task triển khai         | Tài liệu chung của dự án                                 |
| `specs/`                    | Ý định đã duyệt và bằng chứng thực thi của công việc lớn | Task không liên quan                                     |
| `HANDOFF.md`                | Suy luận cần thiết cho phiên kế tiếp                     | Lịch sử lâu dài                                          |

### Trạng thái hiện tại

`CONTEXT.md` mang tính khai báo: nó mô tả điều đang đúng lúc này. Checkpoint viết lại file thay vì nối thêm mãi. Quy tắc đi kèm giới hạn file ở tối đa 150 dòng.

`JOURNAL.md` chỉ được nối thêm và không tự động nạp. File này phục vụ audit hoặc tra cứu lịch sử mà không làm tốn context của phiên thông thường.

### Knowledge bền vững

Knowledge store mang tính mô tả. Nội dung phù hợp thường gồm kiến trúc, thuật ngữ, quy tắc nghiệp vụ, hợp đồng với hệ thống ngoài và liên kết tới tài liệu chuẩn.

Một claim nên vào knowledge khi nó:

1. có bằng chứng từ repository hoặc do user cung cấp;
2. đang đúng;
3. vẫn hữu ích sau khi task hiện tại kết thúc;
4. được đặt vào topic đang sở hữu nhóm fact đó, nếu owner đã tồn tại.

Công việc đang làm, thiết kế đề xuất và phát hiện chỉ liên quan đến một task nên ở lại task, spec hoặc `CONTEXT.md` cho tới khi chúng thật sự trở thành kiến thức bền vững.

Phép thử đơn giản:

> Nếu task hiện tại bị hủy vào ngày mai, điều này vẫn đúng và vẫn hữu ích không?

### Truy xuất knowledge

Quy trình truy xuất bắt đầu từ map và có giới hạn:

1. đọc root `INDEX.md`;
2. chỉ đi theo domain map hoặc topic liên quan;
3. xem metadata và heading của topic;
4. đọc section nhỏ nhất đủ trả lời câu hỏi;
5. chỉ dùng tìm kiếm có giới hạn trong repository hoặc Git khi knowledge đã route chưa đủ.

Việc đọc knowledge không bao giờ tự thay đổi knowledge.

### Hợp đồng và lifecycle của topic

Knowledge topic dùng front matter tương thích YAML nhưng có grammar giới hạn. Các field bắt buộc gồm:

```yaml
---
name: example-topic
description: "Topic này sở hữu nội dung gì."
type: domain
status: active
updated: YYYY-MM-DD
last_verified: YYYY-MM-DD
sources:
  - "../../docs/example.md"
---
```

Các trạng thái được hỗ trợ:

- `active`: nguồn chuẩn hiện tại, đã được xác minh;
- `review-needed`: có điểm chưa chắc hoặc xung đột, phải kiểm tra trước khi dùng như authority;
- `superseded`: đã được topic khác thay thế;
- `retired`: nội dung lịch sử được giữ lại có chủ đích.

Grammar field đầy đủ, giới hạn routing, ngưỡng tạo map và quy tắc mutation nằm trong rule hoặc guideline `knowledge-management` của runtime tương ứng.

### Kiểm tra

Checker đi kèm kiểm tra cấu trúc, route, reference, lifecycle, mốc freshness và các giới hạn về kích thước hoặc sensitivity. Nó không quyết định một câu mô tả có đúng hay không.

Chỉ cần chạy checker trực tiếp khi đang bảo trì knowledge store:

```bash
bash .claude/scripts/knowledge-check.sh --root .
bash .codex/scripts/knowledge-check.sh --root .
```

Trong quy trình bình thường, `/doctor` và `/refactor-memory` tự gọi checker phù hợp.

## 5. Quy trình task bền vững

Dùng `/plan <task>` hoặc `$codex-plan <task>` khi công việc cần tồn tại lâu hơn cuộc trò chuyện hiện tại.

Command tạo `YYYY-MM-DD-NNN-<slug>/TASK.md` dưới `.claude/tasks/` hoặc `.codex/tasks/`, dùng ngày tạo UTC và số thứ tự trong ngày. `TASK.md` là file bắt buộc duy nhất và nguồn chuẩn cho scope, trạng thái, các bước, quyết định và nghiệm thu. Một task hữu ích cần ghi:

- yêu cầu của user và mục tiêu có thể quan sát;
- code, tài liệu và knowledge liên quan;
- kế hoạch có thứ tự và một checkpoint kiểm tra cho mỗi bước;
- tiêu chí nghiệm thu;
- quyết định quan trọng cùng các phương án đã loại;
- phát hiện làm thay đổi kế hoạch;
- kết quả và phần nhìn lại sau khi hoàn tất.

Đọc `TASK.md` phải đủ để hiểu trạng thái, quyết định và hành động tiếp theo mà không cần cuộc chat ban đầu. Giữ nội dung tương xứng với công việc: phát hiện ngắn ở ngay trong file; section không có gì liên quan có thể ghi `None.`.

### Chỉ tạo file hỗ trợ khi cần

Workspace mặc định đã đầy đủ với:

```text
tasks/YYYY-MM-DD-NNN-<slug>/
└── TASK.md
```

Chỉ tạo `artifacts/` khi cần input/output ở định dạng riêng, bằng chứng phục vụ kiểm tra hoặc tiếp tục công việc mà tóm tắt ngắn không giữ được, hoặc nghiên cứu chi tiết của task sẽ làm khó đọc kế hoạch hành động. Liên kết các file có ý nghĩa trong section tùy chọn `### Workspace Files`, ghi mục đích và đường dẫn tương đối trong workspace. Quyết định và kết luận vẫn nằm trong `TASK.md`.

Sửa vài nút không mặc định cần bộ mockup. Chỉnh API không cần báo cáo JSON chỉ vì API trả về JSON. ZIP do user cung cấp để tái hiện lỗi import, hoặc số liệu cần so sánh hiệu năng, có thể là lý do hợp lệ để giữ file. Liên kết file chuẩn đã có thay vì sao chép; source, tài liệu, asset và regression fixture lâu dài vẫn ở vị trí thông thường trong dự án.

Workspace thay đổi cách lưu, không thay đổi mô hình thực thi của task: không bắt buộc POC, vòng phỏng vấn, roadmap hay ledger riêng, review lặp lại hoặc đổi phiên. Chạy tập kiểm tra nhỏ nhất đủ chứng minh kết quả cùng các check bắt buộc của repository; làm thêm phải có lỗi quan sát được, thay đổi liên quan, tiêu chí chưa đạt hoặc feedback của user.

Artifact tuân theo chính sách riêng tư, lưu trữ và Git của dự án downstream; lưu file không đồng nghĩa với được phép commit. Ghi rõ dependency chỉ có ở máy hiện tại và cách lấy lại hoặc tái tạo input cần thiết. Không tự giải nén hay thực thi archive, nạp hàng loạt file đính kèm hoặc xóa bằng chứng khi hoàn tất.

Định dạng thư mục là hợp đồng task hiện hành duy nhất. Khi nâng cấp, downstream phải chủ động điều chỉnh công việc đã có; không có nhánh tương thích task file phẳng hay migration tự động.

### State machine

```text
planning ── user phê duyệt ──▶ in-progress
in-progress ── agent hoàn tất ──▶ awaiting-review
awaiting-review ── user xác nhận ──▶ done
awaiting-review ── user báo lỗi ──▶ in-progress
in-progress ── gặp blocker ──▶ blocked
blocked ── blocker được gỡ ──▶ in-progress
bất kỳ trạng thái nào ── user hủy ──▶ cancelled
```

`planning` và `awaiting-review` là hai trạng thái khóa việc sửa source:

- Ở `planning`, agent có thể chỉnh `TASK.md` và giữ ghi chú, input được cung cấp hoặc bằng chứng chỉ đọc cần thiết. Không được triển khai, kể cả bên trong `artifacts/`.
- Ở `awaiting-review`, agent giữ nguyên implementation và bằng chứng đang được review trong lúc chờ user.
- Khi user báo vấn đề, task được mở lại và quay về `in-progress`.

### Phê duyệt và hoàn tất

Việc phê duyệt dùng ngôn ngữ tự nhiên. Các câu rõ ràng như “go”, “implement”, “approved” hoặc “làm đi” có thể bắt đầu một plan đã duyệt. Các câu như “looks good”, “confirmed”, “đóng task” hoặc “xong” cho phép archive task.

Lời khen, câu hỏi hoặc việc user tự sửa task file không được coi là phê duyệt.

Completion có hai bước riêng:

1. **Agent hoàn tất:** triển khai và validation xong; trạng thái chuyển thành `awaiting-review`.
2. **User xác nhận:** user review kết quả; task chuyển sang `done`, toàn bộ thư mục chuyển vào `tasks/done/<task-id>/`, và journal nhận một dòng lịch sử ngắn. Hủy task cũng giữ nguyên cả workspace. Không ghi đè đích archive; các liên kết tương đối tới artifact vẫn hoạt động sau khi di chuyển.

### Tiếp tục ở phiên sau

Startup chỉ đọc metadata của task. Khi tiếp tục, đọc `TASK.md`, rồi chỉ đọc code và file hỗ trợ cần cho hành động tiếp theo. Đối chiếu bằng chứng với code hiện tại, kiểm tra claim bị ảnh hưởng khi cần và ghi drift; không chạy lại mọi check đã hoàn tất chỉ vì đổi phiên. Báo thiếu input bắt buộc thay vì bịa kết quả tái hiện thành công.

Task file là kế hoạch có thể tiếp tục, không phải bằng chứng rằng repository vẫn giữ nguyên.

## 6. Quy trình spec

Dùng `/spec <mission>` hoặc `$codex-spec <mission>` cho phạm vi cấp mission cần ý định được duyệt chung và roadmap thực thi nhiều phase—không phải chỉ vì task cần thêm file.

Workspace của spec nằm tại:

```text
.claude/specs/YYYY-MM-DD-<slug>/
.codex/specs/YYYY-MM-DD-<slug>/
```

Mỗi workspace gồm:

| File         | Mục đích                                                                              |
| ------------ | ------------------------------------------------------------------------------------- |
| `SPEC.md`    | Ý định đã duyệt, acceptance scenario, giới hạn scope và commit policy                 |
| `ROADMAP.md` | Các phase, work item có thể thực thi và checkpoint kiểm tra cho từng item             |
| `NOTES.md`   | Knowledge làm việc đã được chọn lọc, quyết định, ràng buộc và acceptance gap hiện tại |
| `LEDGER.md`  | Bằng chứng thực thi và validation dạng append-only                                    |
| `artifacts/` | Bản thử nghiệm hoặc tài liệu tham chiếu đã được phê duyệt                             |

### Lập kế hoạch và phê duyệt

Command spec phỏng vấn user, ghi quyết định vào workspace và có thể tạo artifact thử nghiệm. Sau đó nó chuẩn bị roadmap đủ rõ để một phiên khác thực thi mà không cần biết cuộc phỏng vấn ban đầu.

User phê duyệt `SPEC.md` và `ROADMAP.md` một lần. Phê duyệt này áp dụng cho phần việc nằm trong scope đã duyệt. Nó không cho phép refactor không liên quan hoặc tự thay đổi product intent.

Spec đã duyệt cũng ghi commit policy. Mặc định agent không tự commit; việc push không bao giờ được ngầm cho phép.

### Thực thi

Khi phù hợp, chạy `/spec-run <slug>` hoặc `$codex-spec-run <slug>` trong một phiên mới.

Mỗi vòng lặp:

1. định hướng lại từ các file spec;
2. chọn work item pending đầu tiên còn thực thi được;
3. triển khai và kiểm tra trên bề mặt thực phù hợp;
4. cập nhật trạng thái item trong roadmap;
5. nối bằng chứng vào ledger;
6. ghi blocker kèm điều kiện cụ thể để tiếp tục.

Một check thất bại chỉ được thử lại khi giả thuyết, implementation hoặc verifier đã thay đổi đáng kể. Lặp lại cùng một lần thử thất bại không phải là tiến triển.

Tại ranh giới giữa các phase, có thể chuyển sang phiên mới khi hữu ích. Workspace spec chính là phần bàn giao; quá trình chạy spec không dùng `HANDOFF.md`.

### Review cuối

Khi mọi work item đã hoàn tất hoặc được supersede rõ ràng và không còn blocker, executor chạy một acceptance gate mới. Mọi acceptance scenario phải có bằng chứng hiện tại trước khi spec chuyển sang `awaiting-final-review`.

User, không phải agent, xác nhận spec đã hoàn tất.

Nếu feedback chỉ thay đổi một phần implementation có giới hạn, hãy chạy lại các acceptance scenario bị ảnh hưởng và dependency dùng chung. Nếu không thể bảo vệ ranh giới ảnh hưởng, chạy lại toàn bộ gate. Feedback làm thay đổi intent hoặc vượt scope đã duyệt phải quay lại sửa spec và xin phê duyệt mới.

## 7. Delegation và agent chuyên biệt

Delegation là tùy chọn. Tool đang dùng và chỉ dẫn của repository quyết định nó có hữu ích hay không.

Khi giao việc cho subagent:

- chia request thành các phần không chồng lấn trước;
- giao cho mỗi worker một câu hỏi hoặc phạm vi file rõ ràng;
- giữ explorer ở chế độ chỉ đọc;
- các writer chạy song song phải sở hữu phạm vi tách biệt;
- tránh tự làm lại cùng investigation mà worker đã nhận, trừ khi chủ đích là kiểm tra độc lập;
- tích hợp kết quả theo thứ tự phụ thuộc và validate từng phần;
- agent cha chịu trách nhiệm cuối cùng.

Project có ba agent chuyên biệt chỉ chạy khi được gọi rõ ràng:

| Agent               | Hành vi                                                                                                                                                        |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Clean-code reviewer | Có thể thực hiện cải thiện chất lượng mã trong phạm vi rõ ràng, giữ nguyên hành vi và chạy các check liên quan. Chế độ review-only được dùng khi user yêu cầu. |
| Security auditor    | Đọc code, thực hiện audit dựa trên bằng chứng và ghi báo cáo theo ngày.                                                                                        |
| UI visual critic    | Đánh giá đầu ra trực quan đã render và báo các vấn đề thiết kế có thể hành động.                                                                               |

Không agent nào tự chạy, kể cả trong quá trình thực thi task hoặc spec.

Cấu hình Codex đi kèm giới hạn tối đa sáu thread subagent trong một phiên. Delegation mặc định chỉ sâu một cấp, trừ khi user yêu cầu recursion rõ ràng.

## 8. Tham chiếu command

| Claude Code          | Codex CLI                  | Mục đích                                                                                  |
| -------------------- | -------------------------- | ----------------------------------------------------------------------------------------- |
| `/start`             | `$codex-start`             | Định hướng phiên từ trạng thái hiện tại, index, knowledge routing và lịch sử Git gần nhất |
| `/plan <task>`       | `$codex-plan <task>`       | Tạo task triển khai bền vững                                                              |
| `/spec <mission>`    | `$codex-spec <mission>`    | Tạo và phê duyệt spec nhiều phase                                                         |
| `/spec-run <slug>`   | `$codex-spec-run <slug>`   | Thực thi spec đã duyệt tới cổng final review                                              |
| `/project-discovery` | `$codex-project-discovery` | Biến ý tưởng dự án còn thô thành tài liệu có cấu trúc                                     |
| `/checkpoint`        | `$codex-checkpoint`        | Xây dựng lại trạng thái hiện tại, đồng bộ index và chắt lọc thông tin bền vững            |
| `/handoff`           | `$codex-handoff`           | Lưu phần điều tra đang dở cho phiên kế tiếp                                               |
| `/learn`             | `$codex-learn`             | Đưa hành vi lặp lại vào rule hoặc guideline                                               |
| `/doctor`            | `$codex-doctor`            | Chạy kiểm tra cấu trúc và ngữ nghĩa                                                       |
| `/refactor-memory`   | `$codex-refactor-memory`   | Chuẩn hóa và sắp xếp lại cấu trúc bộ nhớ ngay tại chỗ                                     |

## 9. Cấu trúc sau khi cài

Một bản cài Claude tập trung trong:

```text
.claude/
├── CLAUDE.md
├── CONTEXT.md
├── JOURNAL.md
├── commands/
├── agents/
├── rules/
├── knowledge/
│   └── INDEX.md
├── scripts/
├── tasks/
│   ├── index.md
│   └── done/
└── specs/
    └── INDEX.md
```

`HANDOFF.md` chỉ xuất hiện trong khoảng từ lúc handoff đến lần start kế tiếp. Workspace task, workspace spec, knowledge topic và map được tạo thêm khi dự án phát triển. Seed task trong bộ cài không chứa task đang làm hay artifact ví dụ.

Một bản cài Codex tập trung trong:

```text
AGENTS.md
.agents/
└── skills/
.codex/
├── CONTEXT.md
├── JOURNAL.md
├── config.toml
├── agents/
├── guidelines/
├── knowledge/
│   └── INDEX.md
├── scripts/
├── tasks/
│   ├── index.md
│   └── done/
└── specs/
    └── INDEX.md
```

Trong repository nguồn CLAUDART, `.codex/AGENTS.md` là template dùng để tạo `AGENTS.md` ở thư mục gốc khi cài mới.

## 10. Bảo trì chính CLAUDART

Contributor cần giữ hành vi tương đương giữa Claude và Codex khi một concept áp dụng cho cả hai runtime. Khi command công khai, hợp đồng file hoặc workflow thay đổi, hãy cập nhật cả tài liệu tiếng Anh và tiếng Việt.

Chạy toàn bộ check của repository trước khi mở pull request:

```bash
npm ci
npm run check
```

Xem [CONTRIBUTING.md](../CONTRIBUTING.md) để biết quy tắc đóng góp và [INTEGRATE.md](../INTEGRATE.md) để nâng cấp CLAUDART trong dự án downstream.
