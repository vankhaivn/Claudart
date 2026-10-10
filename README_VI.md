# CLAUDART

[English](README.md) · [Hướng dẫn quy trình](docs/WORKFLOW_VI.md)

CLAUDART cho Claude Code và Codex một bộ nhớ nằm ngay trong repository. Trạng thái hiện tại, kế hoạch, kiến thức dự án và chỉ dẫn cho agent đều là file Markdown, được quản lý phiên bản cùng mã nguồn. Phiên mới tiếp tục đúng chỗ phiên trước dừng lại.

Dùng được với Claude Code, Codex hoặc cả hai. Hai công cụ dùng chung một thư mục trạng thái là `.claudart/`. Không cần cơ sở dữ liệu, daemon hay dịch vụ chạy nền.

## Bạn có gì

- **Bắt đầu phiên:** `/cda-start` đưa cho agent trạng thái hiện tại, việc đang mở và lịch sử Git gần đây.
- **Kế hoạch không bị mất:** mỗi task giữ kế hoạch và quyết định trong một file `TASK.md`, mai làm tiếp được.
- **Spec cho việc lớn:** duyệt một lần cho cả nhiệm vụ nhiều giai đoạn, rồi để agent chạy tới bước review cuối.
- **Kiến thức dự án:** các sự thật lâu dài về dự án, tách khỏi rule và khỏi việc tạm thời.
- **Hồ sơ owner:** cách bạn muốn làm việc, được ghi lại khi bạn sửa agent.
- **Kiểm tra sức khỏe:** checker chỉ đọc cho cấu trúc bộ nhớ.

## Cài đặt

Dự án mới, lớp Claude Code (mặc định):

```bash
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash
```

Thêm flag sau `bash -s --` để chọn thứ cần cài:

| Flag             | Cài gì                                                         |
| ---------------- | -------------------------------------------------------------- |
| `--claude`       | Lớp Claude Code (mặc định)                                     |
| `--codex`        | Lớp Codex                                                      |
| `--both`         | Cả hai lớp                                                     |
| `--project-docs` | Module tùy chọn [Project Docs](modules/project-docs/README.md) |

```bash
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --both
```

Installer chỉ thêm file còn thiếu và không bao giờ đụng vào trạng thái dự án đã có.

**Đã có CLAUDART hoặc chỉ dẫn agent riêng?** Đừng chạy installer đè lên. Hãy nhờ agent:

> Read https://raw.githubusercontent.com/vankhaivn/Claudart/main/INTEGRATE.md and follow it to integrate or update CLAUDART in this project. Preserve project-specific content and show me the proposed changes before writing them.

Agent sẽ đưa bạn xem kế hoạch và chờ bạn duyệt rồi mới ghi file.

Các workflow CLAUDART dùng chung tên `cda-` trên cả hai công cụ: gọi `/cda-task` trong Claude Code hoặc `$cda-task` trong Codex. Ký tự đầu là cú pháp riêng của runtime, không phải phần tên workflow.

## Dùng hằng ngày

| Bạn muốn                         | Claude Code            | Codex                  |
| -------------------------------- | ---------------------- | ---------------------- |
| Bắt đầu phiên                    | `/cda-start`           | `$cda-start`           |
| Lập kế hoạch cần giữ lại         | `/cda-task <task>`     | `$cda-task <task>`     |
| Định nghĩa việc lớn, nhiều phiên | `/cda-spec <mission>`  | `$cda-spec <mission>`  |
| Chạy spec đã duyệt               | `/cda-spec-run <slug>` | `$cda-spec-run <slug>` |
| Lưu trạng thái khi tới điểm dừng | `/cda-checkpoint`      | `$cda-checkpoint`      |
| Tạm dừng một cuộc điều tra khó   | `/cda-handoff`         | `$cda-handoff`         |
| Biến bài học lặp lại thành rule  | `/cda-learn`           | `$cda-learn`           |
| Kiểm tra bản cài                 | `/cda-doctor`          | `$cda-doctor`          |

Sửa nhỏ và rõ ràng thì không cần lệnh nào, cứ nhờ thẳng. Xem [hướng dẫn quy trình](docs/WORKFLOW_VI.md) để biết khi nào dùng task, khi nào dùng spec.

## Thứ gì nằm ở đâu

| File hoặc thư mục      | Chứa                                  |
| ---------------------- | ------------------------------------- |
| `.claudart/CONTEXT.md` | Những gì đang đúng ở thời điểm này    |
| `.claudart/OWNER.md`   | Cách bạn muốn agent làm việc với bạn  |
| `.claudart/knowledge/` | Sự thật lâu dài về dự án              |
| `.claudart/tasks/`     | Kế hoạch task                         |
| `.claudart/specs/`     | Spec cho việc lớn                     |
| `.claudart/VERSION`    | Commit upstream của từng layer đã cài |
| `.claude/`, `.codex/`  | Rule, lệnh và script của agent        |

## Đóng góp

```bash
npm ci
npm run check
```

Xem [CONTRIBUTING.md](CONTRIBUTING.md).

## Giấy phép

[MIT](LICENSE)
