# Hướng dẫn quy trình CLAUDART

[English](WORKFLOW.md) · [README](../README_VI.md)

Hướng dẫn này giải thích cách làm việc với CLAUDART sau khi cài: một phiên trông như thế nào, việc nên lớn cỡ nào, bạn sẽ được nhờ review những gì và thông tin được lưu ở đâu.

Tài liệu mô tả cách hoạt động, không liệt kê mọi rule. Contract chính xác mà agent tuân theo nằm trong `.claude/rules/` và `.claude/commands/` (Claude Code) hoặc `.codex/guidelines/` và `.agents/skills/` (Codex).

## 1. Một phiên bình thường

```text
/start  →  làm việc  →  /checkpoint
              │
              └─ đang điều tra dở mà hết context?  →  /handoff
```

**Start.** `/start` (hoặc `$codex-start`) đọc trạng thái hiện tại trong `CONTEXT.md`, danh sách task và spec, mục lục knowledge, lịch sử Git gần đây và handoff đang chờ nếu có. Lệnh này cố ý nhẹ, không đọc hết mọi file. Nếu tin nhắn của bạn đã nêu task cần làm tiếp, agent vào thẳng task đó.

**Làm việc.** Cứ nhờ việc bạn cần. Agent tự chọn quy mô phù hợp (xem bên dưới).

**Checkpoint.** Tới điểm dừng tự nhiên, `/checkpoint` viết lại `CONTEXT.md`, cập nhật danh sách task và spec, chuyển trạng thái cũ vào `JOURNAL.md` và lưu những sự thật đáng giữ thành knowledge.

**Handoff.** Chỉ dùng cho một cuộc điều tra khó phải làm tiếp ở phiên mới. `/handoff` ghi giả thuyết hiện tại, bằng chứng, các hướng đã thất bại và bước tiếp theo cụ thể vào `HANDOFF.md`. Lần `/start` tiếp theo đọc rồi xóa nó. Đây không phải bản tóm tắt phiên.

Claude Code và Codex đọc ghi cùng thư mục `.claudart/`, nên bạn có thể đổi công cụ giữa các phiên. Dùng lần lượt, đừng cho hai bên cùng sửa một file một lúc.

## 2. Chọn quy mô công việc

| Chế độ         | Dùng khi                                                   | Lưu lại gì                           |
| -------------- | ---------------------------------------------------------- | ------------------------------------ |
| Nhờ thẳng      | Thay đổi nhỏ, rõ ràng, ít rủi ro                           | Không có gì thêm, chỉ lịch sử Git    |
| Task (`/plan`) | Việc cần kế hoạch giữ được qua gián đoạn, hoặc bạn yêu cầu | Một file `TASK.md`                   |
| Spec (`/spec`) | Cả một nhiệm vụ nhiều giai đoạn mà bạn duyệt một lần       | Một thư mục trong `.claudart/specs/` |

Mẹo:

- Sửa nhiều file không có nghĩa là phải lập kế hoạch.
- Cần một ảnh, file JSON hay ZIP không có nghĩa là phải viết spec.
- Trong một spec đang chạy, không tạo task riêng.

## 3. Task

`/plan <task>` tạo `.claudart/tasks/YYYY-MM-DD-NNN-<slug>/TASK.md`. File này chứa mục tiêu, các bước kèm cách kiểm tra từng bước, tiêu chí nghiệm thu, các quyết định đã đưa ra và kết quả. File phụ chỉ đặt vào `artifacts/` khi thật sự cần, ví dụ một file ZIP để tái hiện lỗi.

### Bạn sẽ thấy gì

Bạn không phải đọc `TASK.md`. Khi kế hoạch xong, agent đưa bạn một bản tóm tắt ngắn bằng ngôn ngữ của bạn:

- **Hiện tại:** vấn đề đang có.
- **Sau khi xong:** điều gì sẽ đúng.
- **Kế hoạch:** ba tới năm bước bằng lời thường.
- **Review:** ai duyệt cuối, và bạn sẽ cần xem gì.

Nếu bạn chỉ nhờ lập kế hoạch, agent chờ bạn nói "làm đi". Nếu bạn đã nói "triển khai luôn", agent bắt đầu ngay.

### Ai duyệt cuối

Mỗi task ghi rõ ai review kết quả: bạn (`user`) hay agent (`agent`).

- **Agent** tự đóng task khi mọi tiêu chí đều kiểm tra khách quan được, ví dụ "request lỗi thì nút submit bấm lại được".
- **Bạn** duyệt khi kết quả cần bạn đánh giá ("câu chữ này có tạo cảm giác yên tâm không?"), cần thiết bị hay tài khoản agent không truy cập được, hoặc khi bạn yêu cầu được duyệt cuối.

Khi bạn là người review, agent làm xong mọi thứ nó tự kiểm được, rồi dừng lại cho bạn xem kết quả thật và đúng một quyết định còn lại của bạn. Nói "ổn rồi" hoặc "đóng đi" để kết thúc, hoặc mô tả lỗi để mở lại task. Im lặng hay khen không làm task đóng.

### Vòng đời

```text
planning ──làm đi──▶ in-progress ──agent chứng minh đủ──▶ done
                         │
                         └──agent làm xong phần mình──▶ awaiting-review ──bạn xác nhận──▶ done
                                                              └──bạn báo lỗi──▶ in-progress
```

Task cũng có thể ở trạng thái `blocked` hoặc `cancelled`. Task xong được chuyển vào `tasks/done/`. Muốn làm tiếp sau này, chỉ cần nêu tên task; agent đọc `TASK.md` và chỉ những file cần cho bước kế tiếp.

## 4. Spec cho việc lớn

`/spec <mission>` phỏng vấn bạn, có thể dựng một proof of concept nhỏ, rồi viết kế hoạch đủ chi tiết để chạy mà không cần cuộc trò chuyện ban đầu. Lệnh này không viết code sản phẩm.

| File         | Chứa                                                     |
| ------------ | -------------------------------------------------------- |
| `SPEC.md`    | Mục tiêu đã duyệt, kịch bản nghiệm thu, giới hạn phạm vi |
| `ROADMAP.md` | Các giai đoạn và hạng mục, mỗi hạng mục có cách kiểm tra |
| `NOTES.md`   | Quyết định, ràng buộc, chỗ còn thiếu                     |
| `LEDGER.md`  | Nhật ký bằng chứng, chỉ ghi thêm                         |
| `artifacts/` | File proof of concept đã duyệt                           |

Bạn duyệt `SPEC.md` và `ROADMAP.md` một lần. Lần duyệt đó áp dụng cho mọi việc trong phạm vi, nhưng không cho thay đổi ngoài lề hay đổi mục tiêu; những thứ đó cần sửa spec và duyệt lại.

Sau đó `/spec-run <slug>` đi lần lượt theo roadmap: làm, kiểm tra, ghi bằng chứng, sang việc tiếp. Check thất bại chỉ được thử lại khi có gì đó thực sự thay đổi. Ở ranh giới giữa các giai đoạn, agent có thể gợi ý checkpoint hoặc mở phiên mới; bạn không trả lời thì việc vẫn chạy tiếp.

Khi mọi thứ xong, agent chạy các check nghiệm thu và dừng ở `awaiting-final-review`. Chỉ bạn mới đánh dấu spec là xong.

## 5. Thông tin nào để ở đâu

| Nơi lưu                     | Chứa                                    | Không chứa                          |
| --------------------------- | --------------------------------------- | ----------------------------------- |
| `CONTEXT.md`                | Điều đang đúng lúc này, để làm tiếp     | Lịch sử, tài liệu tham khảo         |
| `OWNER.md`                  | Cách bạn muốn làm việc với agent        | Quy ước code, secret                |
| `JOURNAL.md`                | Lịch sử đã cũ (không tự động tải)       | Chỉ dẫn                             |
| `rules/` hoặc `guidelines/` | Agent nên hành xử thế nào               | Sự thật về dự án                    |
| `knowledge/`                | Sự thật lâu dài, có bằng chứng về dự án | Kế hoạch, phỏng đoán, việc đang làm |
| `tasks/`, `specs/`          | Việc đang làm                           | Tài liệu dự án chung                |
| `HANDOFF.md`                | Mạch suy luận cho phiên kế tiếp         | Thứ gì lâu dài                      |

**Hồ sơ owner.** Khi bạn sửa agent hoặc nêu một ưu tiên lâu dài ("luôn trả lời bằng tiếng Việt", "không bao giờ push khi chưa hỏi"), agent thêm một dòng có ngày vào `OWNER.md` và báo cho bạn. Một lần cho phép duy nhất không bao giờ bị ghi thành cho phép thường trực. Chỉ dẫn hiện tại của bạn luôn thắng file này.

**Knowledge.** Một sự thật đáng đưa vào knowledge khi qua được câu hỏi:

> Nếu ngày mai task hiện tại bị hủy, điều này có còn đúng và còn hữu ích không?

Nếu code, schema hay tài liệu dự án đã sở hữu sự thật đó, knowledge chỉ trỏ tới. Agent đọc knowledge theo bản đồ: `INDEX.md` gốc trước, rồi chỉ topic và đoạn liên quan. Đọc không bao giờ làm thay đổi nó.

**Kiểm tra.** `/doctor` chạy một check cấu trúc chỉ đọc, rồi xem xét ý nghĩa và tính nhất quán. Chỉ chạy checker knowledge:

```bash
bash .claude/scripts/knowledge-check.sh --root .
```

Với Codex thì dùng `.codex/scripts/`. Checker tìm cấu trúc và liên kết hỏng, nhưng không biết một phát biểu có đúng hay không. `/refactor-memory` sắp xếp lại kho khi nó đã rối.

## 6. Git

- Agent được tạo **commit local** cho việc đã kiểm tra xong, trừ khi cấu hình global, repository hoặc bạn nói khác.
- Agent chỉ stage file nó đã sửa, không bao giờ thêm dòng ghi công AI hay đặt tên branch theo agent.
- Agent không bao giờ push, merge, rebase, tag hay đổi cấu hình Git khi chưa được bạn cho phép rõ ràng.
- Một spec có thể đặt `commits: per-task` (mặc định), `per-phase` hoặc `user` (không tự commit).

## 7. Agent chuyên biệt

Ba agent chỉ chạy khi bạn gọi đích danh:

| Agent               | Làm gì                                                                     |
| ------------------- | -------------------------------------------------------------------------- |
| Clean-code reviewer | Review chất lượng code hoặc refactor giữ nguyên hành vi, trong phạm vi hẹp |
| Security auditor    | Audit bảo mật chỉ đọc, kèm báo cáo                                         |
| UI visual critic    | Review giao diện, slide hay output hình ảnh đã render                      |

Agent chính cũng có thể chia việc cho agent phụ khi công cụ hỗ trợ. Nó vẫn chịu trách nhiệm kiểm tra và ghép kết quả của chúng.

## 8. Project Docs (tùy chọn)

Cài bằng `--project-docs`. Module thêm `/project-docs` (hoặc `$codex-project-docs`) để tạo, tiếp nhận, cập nhật, audit hoặc dọn gọn tài liệu của chính dự án bạn, kèm template và ví dụ. Nó không tự chạy và không tạo tài liệu lúc cài. Xem [trang module](../modules/project-docs/README.md).

## 9. Lệnh

| Claude Code        | Codex                    | Mục đích                                   |
| ------------------ | ------------------------ | ------------------------------------------ |
| `/start`           | `$codex-start`           | Định hướng phiên                           |
| `/plan <task>`     | `$codex-plan <task>`     | Tạo hoặc tiếp tục một task                 |
| `/spec <mission>`  | `$codex-spec <mission>`  | Tạo và duyệt spec                          |
| `/spec-run <slug>` | `$codex-spec-run <slug>` | Chạy spec đã duyệt tới bước review cuối    |
| `/checkpoint`      | `$codex-checkpoint`      | Lưu trạng thái hiện tại và sự thật lâu dài |
| `/handoff`         | `$codex-handoff`         | Tạm dừng cuộc điều tra khó cho phiên mới   |
| `/learn`           | `$codex-learn`           | Biến bài học lặp lại thành rule            |
| `/doctor`          | `$codex-doctor`          | Kiểm tra sức khỏe                          |
| `/refactor-memory` | `$codex-refactor-memory` | Sắp xếp lại kho bộ nhớ                     |
| `/project-docs`    | `$codex-project-docs`    | Quản lý tài liệu dự án (tùy chọn)          |

## 10. Cấu trúc sau khi cài

```text
CLAUDE.md          # loader của Claude Code
AGENTS.md          # loader của Codex
.claudart/         # trạng thái chung: CONTEXT, OWNER, JOURNAL, knowledge/, tasks/, specs/
.claude/           # Claude Code: commands/, rules/, agents/, references/, scripts/
.codex/            # Codex: guidelines/, agents/, references/, scripts/, config.toml
.agents/skills/    # skill của Codex
```

Bạn chỉ có những lớp đã cài. Task, spec và topic knowledge xuất hiện dần khi dự án phát triển.

Nâng cấp bản cài sẵn có thì dùng [INTEGRATE.md](../INTEGRATE.md). Muốn đóng góp cho CLAUDART, xem [CONTRIBUTING.md](../CONTRIBUTING.md).
