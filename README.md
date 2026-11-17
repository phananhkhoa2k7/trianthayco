# 🎓 Game Tri Ân Thầy Cô 20/11 – Flutter Web

Một dự án mini-game xây dựng bằng Flutter giúp sinh viên/học sinh gửi tặng những bó hoa và lời chúc ý nghĩa đến các thầy cô giáo nhân ngày Nhà giáo Việt Nam 20/11. Người chơi sẽ điều khiển nhân vật vượt qua các ải mê cung, thu thập đủ hoa và thư để đến được căn phòng cuối cùng tặng quà cho thầy cô.

## ✨ Tính năng nổi bật
- **Mê cung 3 ải:** Độ khó và kích thước mê cung tăng dần. Người chơi phải tìm đường, nhặt đủ số lượng hoa và thư yêu cầu để mở khóa cửa ra.
- **Đồ họa tự vẽ (No Assets):** Toàn bộ nhân vật (người chơi, thầy giáo, cô giáo), tường, hoa, và thư được vẽ trực tiếp bằng `CustomPainter`, giúp ứng dụng cực nhẹ và không phụ thuộc vào file ảnh bên ngoài.
- **Hiệu ứng sinh động:** 
  - Animation nhân vật di chuyển mượt mà (không bị khựng).
  - Vật phẩm (hoa, thư) trôi nổi nhấp nhô liên tục.
  - Pháo giấy (Confetti) bắn chúc mừng khi tặng hoa thành công.
- **Responsive Design:** Chơi mượt mà trên cả Desktop (dùng phím mũi tên / WASD) và Mobile (vuốt màn hình hoặc dùng nút D-pad ảo).

---

## 🛠 Cấu trúc thư mục chính
```text
lib/
  ├── main.dart                      # Khởi tạo App + Chọn repository
  ├── config/app_config.dart         # Quản lý biến môi trường (--dart-define)
  ├── models/                        # Teacher, GiftSubmission, GiftSummary
  ├── data/                          # teachers.dart (Dữ liệu giảng viên), wishes.dart (Lời chúc mẫu)
  ├── services/                      # Xử lý Logic Database & Sinh mê cung (DFS Algorithm)
  ├── screens/                       # Màn hình chính: Home, Game, Tribute, Teacher Detail
  └── widgets/                       # UI Components: MazeView, TeacherCard, GiftSummary...