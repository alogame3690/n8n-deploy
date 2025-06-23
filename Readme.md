🧾 Hướng dẫn triển khai hệ thống n8n bản mới nhất (Auto Deploy)
✅ Bước 1: Chuẩn bị trước
Mục	Yêu cầu
✅ VPS	Ubuntu 22.04 mới hoàn toàn, chưa cài gì
✅ Domain / Subdomain	Đã có, ví dụ: test.ntvn8n.xyz
✅ Mapping DNS	Domain phải đ trỏ về đúng IP VPS (dùng lệnh dig để kiểm tra – hướng dẫn bên dưới)
✅ Mở port	Phải mở cổng 80 và 443:
sudo ufw allow 80,443
sudo ufw enable

👉 Kiểm tra domain đã trỏ chưa:

bash
Sao chép
Chỉnh sửa
dig +short test.ntvn8n.xyz
Nếu kết quả trả về giống IP máy chủ của bạn (VD: 103.77.172.150) → hợp lệ.

✅ Bước 2: Tải & chạy script auto deploy
bash
Sao chép
Chỉnh sửa
wget http://103.172.179.11/files/setup.sh -O setup.sh
chmod +x setup.sh
bash setup.sh
✅ Bước 3: Nhập domain khi được yêu cầu
Khi script hỏi "DOMAIN: ", hãy nhập chính xác domain bạn đã cấu hình trước đó, ví dụ:

makefile
Sao chép
Chỉnh sửa
DOMAIN: test.ntvn8n.xyz
✅ Bước 4: Mở trình duyệt và kiểm tra
Sau khi chạy xong → mở trình duyệt, truy cập:

arduino
Sao chép
Chỉnh sửa
https://test.ntvn8n.xyz
Nếu bạn thấy giao diện như hình dưới đây là thành công 🎉

⚠️ Lưu ý quan trọng
Bản n8n luôn là bản mới nhất (n8n/n8n:latest) đảm bảo có tất cả tính năng mới nhất, bao gồm UI ba tab Editor / Executions / Trigger.

Nếu gặp lỗi:

nginx
Sao chép
Chỉnh sửa
ERR_SSL_PROTOCOL_ERROR
→ rất có thể do domain của bạn đã vượt giới hạn cấp SSL của Let's Encrypt (5 lần trong vòng 168h). Đây là giới hạn hệ thống, không phải do lỗi file .sh hay VPS.

👉 Cách xử lý:

Dùng subdomain khác (VD: test2.ntvn8n.xyz)

Hoặc đợi sau 7 ngày rồi chạy lại

Đừng dùng localhost trong Caddyfile, phải dùng 127.0.0.1 để tránh lỗi auto_bind sai lệch.

