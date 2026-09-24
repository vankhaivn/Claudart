# CLAUDART

[English](README.md) · [Hướng dẫn quy trình](docs/WORKFLOW_VI.md)

CLAUDART là một bộ quy trình đặt ngay trong repository dành cho Claude Code và Codex. Trạng thái phiên làm việc, kế hoạch triển khai, kiến thức dự án và chỉ dẫn cho agent đều được lưu bằng Markdown và quản lý cùng mã nguồn.

Claude và Codex có adapter riêng, dùng chung trạng thái dự án trong `.claudart/`. Bạn có thể cài một adapter hoặc cả hai. CLAUDART không cần cơ sở dữ liệu, daemon hay dịch vụ chạy nền.

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

# Codex
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --codex

# Cả hai
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --both

# Thêm module Project Docs tùy chọn cho lớp đã chọn
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --claude --project-docs
```

Mọi chế độ cài đặt đều tạo seed `.claudart/` một lần cùng adapter đã chọn. Trình cài đặt sao chép file còn thiếu và giữ nguyên trạng thái dự án đã có. Bản cài mặc định chỉ chứa lớp core; `--project-docs` thêm command hoặc skill cùng references cho vòng đời tài liệu tùy chọn. Nó không tự tạo hoặc migrate tài liệu dự án. `--force` chỉ cập nhật payload adapter; shared state và root loader Codex đã có luôn được giữ nguyên. Dùng `INTEGRATE.md` để đối soát chỉ dẫn tùy chỉnh.

Project Docs có [template đầu ra và ví dụ đã điền](modules/project-docs/README.md#output-templates-and-examples) cho phạm vi product, hành vi, kiến trúc, phát triển và vận hành, được dẫn từ một router tài liệu nhỏ. Chỉ dùng phần đang cần nguồn sở hữu; docs và knowledge hiện có có thể tiếp tục giữ trách nhiệm của mình. Template thích ứng với việc chạy local, dùng `main` latest, deploy liên tục hoặc release theo quy trình của team; giữ yêu cầu thực tế mà không tự áp thêm quy trình production-readiness.

Với một bản cài Codex mới, trình cài đặt thêm `.claudart/`, `.codex/`, `.agents/skills/` và `AGENTS.md` ở thư mục gốc. Trong repository CLAUDART, file mẫu nguồn nằm tại `.codex/AGENTS.md`.

### Dự án đã có cấu hình hoặc đã cài CLAUDART

Không dùng trình cài đặt như một công cụ hợp nhất. Nó có thể sao chép hoặc ghi đè file, nhưng không đối soát được chỉ dẫn tùy chỉnh, trạng thái đang dùng, tác vụ, đặc tả hay kiến thức riêng của dự án.

Hãy yêu cầu coding agent làm theo quy trình tích hợp:

> Đọc https://raw.githubusercontent.com/vankhaivn/Claudart/main/INTEGRATE.md và làm theo để tích hợp hoặc cập nhật CLAUDART trong dự án này. Giữ nguyên nội dung riêng của dự án và trình bày các thay đổi dự kiến trước khi ghi file.

Quy trình này so sánh dự án hiện tại với nhánh `main` mới nhất, đồng thời phân biệt file CLAUDART đã cũ với nội dung do dự án tự viết. Quy trình cũng nhận diện module tùy chọn phù hợp và giải thích đề xuất trong kế hoạch. Bạn không cần biết tên module từ trước; chỉ cài module được bạn chọn trong kế hoạch đã duyệt. Cài Project Docs không tự sắp xếp lại docs hoặc knowledge hiện có.

### Lần chạy đầu tiên

Bắt đầu phiên bình thường bằng `/start` hoặc `$codex-start`. Khi tích hợp, làm theo bước xác minh giới hạn trong [INTEGRATE.md](INTEGRATE.md); chỉ chạy doctor đầy đủ hoặc refactor bộ nhớ khi có căn cứ hay yêu cầu của bạn.

Khi audit, `/doctor` hoặc `$codex-doctor` chạy `doctor-check.sh` một lần rồi kiểm tra ngữ nghĩa và tính nhất quán của workflow. Helper kiểm tra cấu trúc, metadata, reference local rõ ràng và giới hạn kích thước, đồng thời gọi knowledge checker hiện có. Đích reference có thể là code/docs ở bất kỳ đâu trong repo; chỉ quét thêm nguồn Markdown khi được chọn. Xem [cách dùng và giới hạn checker](.codex/references/doctor-check.md). Script chỉ đọc, dùng Bash 3.2 cùng tiện ích tiêu chuẩn, không cần cài package.

## Quy trình hằng ngày

| Mục đích                                               | Claude Code        | Codex                    |
| ------------------------------------------------------ | ------------------ | ------------------------ |
| Định hướng phiên                                       | `/start`           | `$codex-start`           |
| Tạo kế hoạch triển khai bền vững                       | `/plan <task>`     | `$codex-plan <task>`     |
| Mô tả công việc lớn, kéo dài nhiều phiên               | `/spec <mission>`  | `$codex-spec <mission>`  |
| Thực thi đặc tả đã được phê duyệt                      | `/spec-run <slug>` | `$codex-spec-run <slug>` |
| Lưu phần điều tra đang dở                              | `/handoff`         | `$codex-handoff`         |
| Xây dựng lại trạng thái hiện tại tại điểm dừng phù hợp | `/checkpoint`      | `$codex-checkpoint`      |
| Biến cách làm lặp lại thành quy tắc                    | `/learn`           | `$codex-learn`           |
| Kiểm tra bản cài đặt                                   | `/doctor`          | `$codex-doctor`          |
| Bảo trì tài liệu dự án hiện hành (tùy chọn)            | `/project-docs`    | `$codex-project-docs`    |

Dùng task plan khi quyết định quan trọng, phối hợp, gián đoạn hoặc review cần được lưu bền vững, hay khi user yêu cầu rõ ràng. Thay đổi nhỏ, rõ ràng không cần workspace; số lượng file không phải điều kiện tự động. Dùng spec cho phạm vi cấp mission cần ý định được duyệt chung và roadmap nhiều phase—không phải chỉ vì task cần ảnh, JSON hay archive.

Task nằm tại `.claudart/tasks/YYYY-MM-DD-NNN-<slug>/TASK.md`, dùng chung cho cả hai runtime. `TASK.md` là file bắt buộc duy nhất. Chỉ tạo `artifacts/` cho input/output ở định dạng riêng, bằng chứng cần giữ hoặc nghiên cứu chi tiết của task; phát hiện ngắn nằm ngay trong plan. Không bắt buộc POC, ledger, vòng review lặp lại hay đổi phiên. Khi user xác nhận đóng, archive toàn bộ thư mục. Task discovery chỉ dùng cấu trúc workspace này.

Khi đã được yêu cầu triển khai hoặc tiếp tục, agent chuyển từ lập kế hoạch sang thực hiện mà không hỏi lại. Yêu cầu chỉ lập kế hoạch vẫn giữ chế độ chỉ đọc; đóng công việc cuối cùng vẫn cần user xác nhận. Spec đã duyệt có thể chuyển sang runner ngay trong cùng phiên nếu user đã yêu cầu thực thi; đổi phiên là tùy chọn.

## Cách tổ chức trạng thái

| Vị trí                      | Mục đích                                         | Cách nạp                                                             |
| --------------------------- | ------------------------------------------------ | -------------------------------------------------------------------- |
| `.claudart/CONTEXT.md`      | Trạng thái hiện tại của dự án và công việc       | Đọc khi bắt đầu phiên; được checkpoint viết lại                      |
| `.claudart/JOURNAL.md`      | Lịch sử đã kết thúc                              | Chỉ nối thêm; không tự động nạp                                      |
| `rules/` hoặc `guidelines/` | Chỉ dẫn mang tính quy định cho hành vi của agent | Nạp khi phù hợp                                                      |
| `.claudart/knowledge/`      | Các sự thật bền vững mô tả dự án                 | Định tuyến qua `INDEX.md`; chỉ đọc chi tiết khi cần                  |
| `.claudart/tasks/`          | Kế hoạch triển khai bền vững                     | Metadata lúc start; `TASK.md` đã chọn và file cần thiết khi tiếp tục |
| `.claudart/specs/`          | Đặc tả công việc lớn và lịch sử thực thi         | Đọc khi đặc tả đang hoạt động                                        |
| `.claudart/HANDOFF.md`      | Bàn giao suy luận cho một phiên kế tiếp          | Phiên `/start` kế tiếp tiếp nhận rồi xóa                             |

Ranh giới quan trọng nhất: **quy tắc nói agent nên làm việc như thế nào; knowledge giữ fact chưa có owner hiện hành phù hợp; task và spec ghi công việc đang được thực hiện.** Khi source, schema, generated reference hoặc tài liệu dự án đã sở hữu một fact, knowledge chỉ giữ route ngắn thay vì tạo bản kể lại cạnh tranh.

Cả hai adapter đọc và ghi cùng một `.claudart/`. Đổi runtime giữ nguyên phạm vi task/spec, phê duyệt, bằng chứng và cổng review cuối; metadata `agent` ghi nguồn gốc, không chọn store hay cấp quyền. Công cụ và chỉ dẫn thực thi theo khả năng của host hiện tại.

Shared state hỗ trợ bàn giao tuần tự, không tự đồng bộ nhiều writer. Cần điều phối việc ghi summary, index và handoff; checkpoint giữ công việc chưa giải quyết của phiên khác và không âm thầm thay một handoff chưa tiếp nhận. Các checkout riêng vẫn tuân theo Git và quy trình cộng tác của dự án.

Rule workflow chỉ nạp khi cần. Loader Claude đã cài đặt tính đường dẫn import từ `.claude/CLAUDE.md`; chi tiết bảo trì knowledge nằm trong `references/`. Module Project Docs tùy chọn dùng cho lifecycle request hoặc khi thay đổi tác động đến tài liệu hiện hành mà nó sở hữu; nó không chạy full audit ở start, checkpoint hoặc sau thay đổi nhỏ thông thường. Tra cứu không phải nạp schema ghi knowledge; các vòng spec liên tục chỉ đọc trạng thái liên quan thay vì nạp lại toàn bộ tài liệu mission.

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
- [Module Project Docs](modules/project-docs/README.md)
- [Quy trình tích hợp và nâng cấp](INTEGRATE.md)
- [Hướng dẫn đóng góp](CONTRIBUTING.md)

## Giấy phép

CLAUDART được phát hành theo [giấy phép MIT](LICENSE).
