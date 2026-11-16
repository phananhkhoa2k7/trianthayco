# Tri ân thầy cô 20/11 – Flutter Web Game

Danh sách giáo viên + game mê cung 3 ải “Tặng hoa tri ân”. Responsive (desktop 2 cột / mobile điều hướng),
lưu dữ liệu bằng `shared_preferences` (localStorage) hoặc Supabase.

## Cấu trúc
```
lib/
  main.dart                      # khởi tạo + chọn repository
  config/app_config.dart         # biến môi trường (--dart-define)
  models/                        # Teacher, GiftSubmission, GiftSummary
  data/                          # teachers.dart (dữ liệu mẫu), wishes.dart (lời chúc)
  services/                      # TeacherGiftRepository + Local/Supabase, maze_generator (DFS)
  screens/                       # home, teacher_detail, game, tribute
  widgets/                       # teacher_card, avatar, maze_view, gift_summary_view, detail_panel
```

## Chạy local
Repo này chỉ chứa `lib/` và `pubspec.yaml`. Tạo khung project rồi chép đè:
```bash
flutter create tri_an_thay_co --platforms=web,android,ios
# chép lib/ và pubspec.yaml của repo này vào thư mục vừa tạo (ghi đè), xoá test/widget_test.dart
cd tri_an_thay_co
flutter pub get
flutter run -d chrome
```
Điều khiển: phím mũi tên hoặc W/A/S/D (desktop); vuốt hoặc nút mũi tên (mobile).
Luật: mỗi ải phải nhặt đủ 3 hoa + 2 thư thì cửa ra mới mở (đổi trong `kLevels` ở `game_screen.dart`).

## Build web / GitHub Pages
```bash
flutter build web --release --base-href /<ten-repo>/
# đẩy thư mục build/web lên nhánh gh-pages (hoặc dùng GitHub Actions)
```

## Chuyển sang Supabase
Mặc định dùng lưu cục bộ. Để dùng Supabase:

1. Chạy SQL trong Supabase SQL Editor:
```sql
create table public.gifts (
  id         bigint generated always as identity primary key,
  teacher_id text        not null,
  flowers    int         not null default 0,
  wishes     int         not null default 0,
  message    text,
  created_at timestamptz not null default now()
);
create index gifts_teacher_id_idx on public.gifts (teacher_id);

alter table public.gifts enable row level security;
create policy "anon can insert" on public.gifts for insert to anon with check (true);
create policy "anon can read"   on public.gifts for select to anon using (true);
```
2. Chạy/build kèm biến môi trường:
```bash
flutter run -d chrome \
  --dart-define=USE_SUPABASE=true \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>

flutter build web --release --base-href /<ten-repo>/ \
  --dart-define=USE_SUPABASE=true \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```
Anon key là khoá công khai (nằm trong JS), nên bảo mật dựa vào RLS. Policy trên cho phép ai cũng ghi/đọc;
nếu cần chống spam hãy thêm giới hạn độ dài `message`, rate limit hoặc Edge Function.
Muốn dùng backend khác (Firebase…): viết thêm class implements `TeacherGiftRepository` và đăng ký trong `main.dart`.

## Tuỳ biến
- Thay danh sách giáo viên trong `lib/data/teachers.dart` (thêm `avatarUrl` nếu có ảnh).
- Thêm/sửa lời chúc trong `lib/data/wishes.dart`.
