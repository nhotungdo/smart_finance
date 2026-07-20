# SmartFinance

## Quản lý trạng thái

Ứng dụng dùng Riverpod theo từng lớp chức năng. Repository đọc/ghi SQLite và
Supabase; `AsyncNotifier` điều phối thao tác thêm, sửa, xóa và biểu diễn ba
trạng thái loading/success/error; UI dùng `ref.watch` để tự cập nhật và
`ref.read` để gửi lệnh. Bộ lọc báo cáo và giao diện sáng/tối dùng `Notifier`.

## Điều hướng

`go_router` quản lý toàn bộ route. `redirect` kiểm tra Supabase session để bảo
vệ màn hình nội bộ. `ShellRoute` giữ sidebar/bottom navigation ổn định giữa
Dashboard, Hóa đơn, Chi phí, Báo cáo và Cài đặt. `context.go` thay màn hiện tại;
`context.push` mở màn chi tiết để người dùng có thể quay lại.

## Quan hệ hóa đơn và giao dịch

`transactions.invoice_id` tham chiếu `invoices.invoice_id`. Một hóa đơn chỉ có
một giao dịch `ACTIVE`. Hóa đơn có loại `INCOME` hoặc `EXPENSE`; giao dịch sinh
từ hóa đơn dùng cùng loại và tổng thanh toán. Giao dịch đã liên kết hóa đơn là
chỉ đọc để tránh sai lệch tiền trước thuế, VAT và tổng tiền.

## Offline

Dữ liệu được ghi vào SQLite trước với `is_synced = 0`. Khi có mạng,
BackgroundSyncService tự đẩy dữ liệu lên Supabase và kéo dữ liệu mới về; người
dùng cũng có thể bấm Đồng bộ ngay trong Dashboard hoặc Cài đặt.
