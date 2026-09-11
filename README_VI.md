# CLAUDART

[English](README.md) · [Hướng dẫn quy trình](docs/WORKFLOW_VI.md)

CLAUDART là một bộ quy trình đặt ngay trong repository dành cho Claude Code và Codex CLI. Trạng thái phiên làm việc, kế hoạch triển khai, kiến thức dự án và chỉ dẫn cho agent đều được lưu bằng Markdown và quản lý cùng mã nguồn.

Hai lớp Claude và Codex hoạt động độc lập. Bạn có thể cài một lớp hoặc cả hai. CLAUDART không cần cơ sở dữ liệu, daemon hay dịch vụ chạy nền.

## CLAUDART bổ sung những gì

- **Định hướng phiên làm việc:** bắt đầu phiên mới từ trạng thái hiện tại, công việc đang mở, kiến thức dự án và lịch sử Git gần nhất.
- **Kế hoạch bền vững:** lưu `TASK.md` có thể tiếp tục trong workspace gọn nhẹ, chỉ thêm file hỗ trợ khi thực sự cần.
- **Đặc tả cho công việc lớn:** mô tả và thực thi công việc kéo dài qua nhiều tác vụ hoặc nhiều phiên dưới một đặc tả đã được phê duyệt.
- **Kiến thức dự án:** tách các sự thật bền vững khỏi quy tắc hành vi và trạng thái tạm thời.
- **Bàn giao phiên:** giữ lại phần điều tra đang dở khi cửa sổ ngữ cảnh gần đầy.
- **Công cụ bảo trì:** kiểm tra và chuẩn hóa cấu trúc bộ nhớ mà không cần thêm dịch vụ riêng.
- **Agent chuyên biệt theo yêu cầu:** dùng agent cho chất lượng mã, bảo mật và đánh giá giao diện chỉ khi bạn gọi rõ ràng.

## Cài đặt

### Dự án mới

Mặc định, lệnh sau cài lớp Claude Code:

```bash
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash
```

Chọn lớp cần cài khi cần thiết:

```bash
# Claude Code
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --claude

# Codex CLI
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --codex

# Cả hai
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --both
```

Trình cài đặt sao chép các file còn thiếu và bỏ qua file đã tồn tại. Tùy chọn `--force` sẽ ghi đè file hiện có, vì vậy chỉ dùng khi bạn thực sự muốn thay thế chúng.

Với một bản cài Codex mới, trình cài đặt thêm `.codex/`, `.agents/skills/` và `AGENTS.md` ở thư mục gốc. Trong repository CLAUDART, file mẫu nguồn nằm tại `.codex/AGENTS.md`.

### Dự án đã có cấu hình hoặc đã cài CLAUDART

Không dùng trình cài đặt như một công cụ hợp nhất. Nó có thể sao chép hoặc ghi đè file, nhưng không đối soát được chỉ dẫn tùy chỉnh, trạng thái đang dùng, tác vụ, đặc tả hay kiến thức riêng của dự án.

Hãy yêu cầu coding agent làm theo quy trình tích hợp:

> Đọc https://raw.githubusercontent.com/vankhaivn/Claudart/main/INTEGRATE.md và làm theo để tích hợp hoặc cập nhật CLAUDART trong dự án này. Giữ nguyên nội dung riêng của dự án và trình bày các thay đổi dự kiến trước khi ghi file.

Quy trình này so sánh dự án hiện tại với nhánh `main` mới nhất, đồng thời phân biệt file CLAUDART đã cũ với nội dung do dự án tự viết.

### Lần chạy đầu tiên

Sau khi cài hoặc đối soát, chạy một lần chuỗi kiểm tra và chuẩn hóa:

| Claude Code        | Codex CLI                |
| ------------------ | ------------------------ |
| `/doctor`          | `$codex-doctor`          |
| `/refactor-memory` | `$codex-refactor-memory` |
| `/doctor`          | `$codex-doctor`          |

Sau đó bắt đầu phiên làm việc bình thường bằng `/start` hoặc `$codex-start`.

## Quy trình hằng ngày

| Mục đích                                               | Claude Code        | Codex CLI                |
| ------------------------------------------------------ | ------------------ | ------------------------ |
| Định hướng phiên                                       | `/start`           | `$codex-start`           |
| Tạo kế hoạch triển khai bền vững                       | `/plan <task>`     | `$codex-plan <task>`     |
| Mô tả công việc lớn, kéo dài nhiều phiên               | `/spec <mission>`  | `$codex-spec <mission>`  |
| Thực thi đặc tả đã được phê duyệt                      | `/spec-run <slug>` | `$codex-spec-run <slug>` |
| Lưu phần điều tra đang dở                              | `/handoff`         | `$codex-handoff`         |
| Xây dựng lại trạng thái hiện tại tại điểm dừng phù hợp | `/checkpoint`      | `$codex-checkpoint`      |
| Biến cách làm lặp lại thành quy tắc                    | `/learn`           | `$codex-learn`           |
| Kiểm tra bản cài đặt                                   | `/doctor`          | `$codex-doctor`          |

Dùng task plan khi quyết định quan trọng, phối hợp, gián đoạn hoặc review cần được lưu bền vững, hay khi user yêu cầu rõ ràng. Thay đổi nhỏ, rõ ràng không cần workspace; số lượng file không phải điều kiện tự động. Dùng spec cho phạm vi cấp mission cần ý định được duyệt chung và roadmap nhiều phase—không phải chỉ vì task cần ảnh, JSON hay archive.

Task bắt đầu bằng `tasks/YYYY-MM-DD-NNN-<slug>/TASK.md` trong runtime đã chọn. `TASK.md` là file bắt buộc duy nhất. Chỉ tạo `artifacts/` cho input/output ở định dạng riêng, bằng chứng cần giữ hoặc nghiên cứu chi tiết của task; phát hiện ngắn nằm ngay trong plan. Không bắt buộc POC, ledger, vòng review lặp lại hay đổi phiên. Khi user xác nhận đóng, archive toàn bộ thư mục. Hợp đồng hiện hành không hỗ trợ task file phẳng; downstream chủ động điều chỉnh công việc đã có khi nâng cấp.

## Cách tổ chức trạng thái

| Vị trí                      | Mục đích                                         | Cách nạp                                            |
| --------------------------- | ------------------------------------------------ | --------------------------------------------------- |
| `CONTEXT.md`                | Trạng thái hiện tại của dự án và công việc       | Đọc khi bắt đầu phiên; được checkpoint viết lại     |
| `JOURNAL.md`                | Lịch sử đã kết thúc                              | Chỉ nối thêm; không tự động nạp                     |
| `rules/` hoặc `guidelines/` | Chỉ dẫn mang tính quy định cho hành vi của agent | Nạp khi phù hợp                                     |
| `knowledge/`                | Các sự thật bền vững mô tả dự án                 | Định tuyến qua `INDEX.md`; chỉ đọc chi tiết khi cần |
| `tasks/`                    | Kế hoạch triển khai bền vững                     | Metadata lúc start; `TASK.md` đã chọn và file cần thiết khi tiếp tục    |
| `specs/`                    | Đặc tả công việc lớn và lịch sử thực thi         | Đọc khi đặc tả đang hoạt động                       |
| `HANDOFF.md`                | Bàn giao suy luận cho một phiên kế tiếp          | Phiên `/start` kế tiếp tiếp nhận rồi xóa            |

Ranh giới quan trọng nhất: **quy tắc nói agent nên làm việc như thế nào; knowledge ghi điều gì đang đúng về dự án; task và spec ghi công việc đang được thực hiện.**

## Agent chuyên biệt

Các agent này không bao giờ tự chạy.

| Agent               | Vai trò                                                                                                                                       |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Clean-code reviewer | Cải thiện chất lượng mã trong phạm vi rõ ràng, giữ nguyên hành vi dự kiến và chạy kiểm tra. Yêu cầu chỉ review sẽ giữ agent ở chế độ chỉ đọc. |
| Security auditor    | Thực hiện audit bảo mật chỉ đọc dựa trên bằng chứng và ghi báo cáo.                                                                           |
| UI visual critic    | Đánh giá giao diện hoặc đầu ra trực quan đã render khi được yêu cầu rõ ràng.                                                                  |

Agent cha vẫn chịu trách nhiệm về phạm vi, tích hợp và kiểm tra kết quả của công việc được giao cho subagent.

## Phát triển CLAUDART

Repository này dùng Prettier cho Markdown và các kiểm tra Bash cho trình cài đặt, hợp đồng knowledge, workspace task và quy trình spec.

```bash
npm ci
npm run check
```

Để dùng pre-commit hook của repository:

```bash
npm run hooks:install
```

## Tài liệu

- [Hướng dẫn quy trình](docs/WORKFLOW_VI.md)
- [Workflow guide bằng tiếng Anh](docs/WORKFLOW.md)
- [Quy trình tích hợp và nâng cấp](INTEGRATE.md)
- [Hướng dẫn đóng góp](CONTRIBUTING.md)

## Giấy phép

CLAUDART được phát hành theo [giấy phép MIT](LICENSE).
