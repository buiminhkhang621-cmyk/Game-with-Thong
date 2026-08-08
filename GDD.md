# Game Design Document (GDD): Project Slime Survivor

## 1. Tóm tắt dự án (Project Overview)

- **Thể loại:** Hành động sinh tồn, Roguelite, Bullet Heaven (tương tự Vampire Survivors, Magic Survival).
- **Góc nhìn:** Top-down 2D, darksoul-like (nhỉ).
- **Nền tảng:** PC (Godot 4.7).
- **Core Loop:** Người chơi điều khiển một khối Slime di chuyển tự do trên bản đồ vô tận. Vũ khí tự động tấn công. Tiêu diệt quái, nhặt kinh nghiệm (XP) để lên cấp, chọn kỹ năng mới hoặc cường hóa sức mạnh, và cố gắng sống sót lâu nhất có thể trước hàng đàn quái vật ngày càng đông và mạnh.

## 2. Hệ thống Nhân vật (Classes)

Người chơi hóa thân thành một khối Slime có thể mang nhiều dạng khác nhau, mỗi dạng có chỉ số và vũ khí khởi đầu riêng:

1. **Berserker (Đỏ):** Cận chiến, sát thương cơ bản cực lớn. Vũ khí khởi đầu: Rìu phóng (Throwing Axe).
2. **Vanguard (Vàng):** Chống chịu tốt, giảm sát thương nhận vào nhưng hồi máu bị giảm. Vũ khí khởi đầu: Kiếm bay quanh người (Orbit Blade).
3. **Assassin (Xanh dương):** Tốc độ di chuyển cực nhanh, sát thương chí mạng cao. Vũ khí khởi đầu: Tia chớp xuyên thấu (Piercing Bolt).
4. **Void Mage (Tím):** Pháp sư bóng tối, máu tối đa thấp nhưng kiểm soát diện rộng tốt. Vũ khí khởi đầu: Quả cầu nguyên tố (Elemental Orbs).

## 3. Hệ thống Vũ khí & Kỹ năng (Active Skills)

- Giới hạn mang theo: Tối đa **4** vũ khí chủ động.
- Vũ khí hiện tại:
  - **Throwing Axe**: Ném rìu về phía kẻ địch gần nhất.
  - **Orbit Blade**: Kiếm xoay quanh người bảo vệ người chơi.
  - **Piercing Bolt**: Tia đạn bắn thẳng xuyên thấu mục tiêu.
  - **Elemental Orbs**: Phóng ngẫu nhiên các quả cầu mang nguyên tố.
  - **Nova Scatter**: Nổ đạn tỏa ra mọi hướng.
  - **AoE Pulse**: Gây sát thương liên tục trong phạm vi hình tròn.
  - **Magic Whip**: Quất roi hình nón quét sạch quái vật phía trước.

## 4. Hệ thống Nguyên tố (Runes & Elements)

Hệ thống nguyên tố là một cơ chế ẩn trên bản đồ giúp thay đổi hoàn toàn cách vũ khí hoạt động.

- **Mở khóa:** Trên bản đồ có 4 bia đá nguyên tố (Rune Fountains) nằm rải rác. Người chơi phải tự đi tìm và chạm vào để **Mở Khóa (Unlock)** nguyên tố cho vòng chơi đó.
- **Khảm (Imbue):** Khi đã mở khóa, tùy chọn Khảm Nguyên Tố sẽ có tỷ lệ xuất hiện khi lên cấp. Mỗi vũ khí được khảm **tối đa 2 nguyên tố**.

### Các Nguyên tố

1. **Sét (Lightning):** Giật sét nảy lây lan sang các kẻ địch lân cận.
2. **Băng (Ice):** Tỷ lệ cao làm chậm, tỷ lệ thấp đóng băng vĩnh viễn kẻ địch.
3. **Hắc Ám (Dark):** Hấp thụ vĩnh viễn HP và sát thương của quái vật bù vào bản thân (có giới hạn).
4. **Vô Cực (Void):** Có 30% tỷ lệ xóa sổ (bốc hơi) quái vật tức thì. Nếu trượt sẽ lây lan ấn chú sang quái khác.

### Sự Cộng Hưởng (Resonance)

Nếu **TOÀN BỘ 4 VŨ KHÍ** đều được khảm cùng chung 1 loại nguyên tố, sức mạnh cốt lõi của nguyên tố đó sẽ thức tỉnh (Max 1 Resonance được kích hoạt):

- **Lightning Resonance:** Sét nảy sang 5 mục tiêu, sát thương cao hơn. Player nhận +20% tốc độ di chuyển và giảm thời gian hồi chiêu.
- **Ice Resonance (Hàn Băng):** Vòng hào quang băng giá khổng lồ liên tục bao quanh người chơi, làm chậm và gây sát thương DPS cho bất cứ thứ gì bước vào.
- **Dark Resonance (Hắc Ám):** X2 giới hạn hút máu và sát thương. Cứ mỗi 10 giây có tỷ lệ biến thành bóng ma vô địch trong 3 giây, chạy cực nhanh và hồi máu liên tục.
- **Void Resonance (Hư Vô Nuke):** Mỗi đòn đánh có 0.2% tỷ lệ nổ Hư Vô, nháy sáng trắng màn hình và **xóa sổ toàn bộ quái vật** trên bản đồ ngay lập tức.

## 5. Ghép Phép Thuật (Spell Crafting)

Hệ thống độc quyền cho phép ghép Vòng (Seals) và Nét (Crests).

- Người chơi nhặt Vòng và Nét khi lên cấp.
- Đủ 1 Vòng + 1 Nét sẽ tự ghép thành một loại Phép Thuật thụ động (Ví dụ: Chữa lành khi máu thấp, bắn đạn ruồi khi đứng yên).
- Phép thuật và Cộng hưởng (Resonance) chia sẻ chung một Giới hạn Phép Thuật (Max Spells). Ban đầu là 1, lên level 15 sẽ được nâng thành 2.

## 6. Kẻ địch & Môi trường (Enemies)

- **Map Tier:** Các màn chơi được chia tier (Tier 1, 2, 3), độ khó và giới hạn quái vật tăng dần.
- **Quái vật:**
  - *Normal:* Đi theo player chậm rãi.
  - *Swarm:* Bầy đàn đông đảo máu giấy.
  - *Tank:* Khổng lồ máu trâu.
  - *Sniper:* Giữ khoảng cách bắn tỉa.
  - *Teleporter:* Tốc biến áp sát.
  - *Bomber:* Nổ tung khi chết gây sát thương.
  - *Summoner:* Gọi đệ.
- Để tối ưu hóa, số lượng quái vật trên màn hình bị giới hạn (75/125/200 tùy Tier).

## 7. Cổ vật (Relics) & Lời Nguyền (Curses)

- Quái vật có tỷ lệ rơi ra Cổ Vật. Cổ vật mang lại hiệu ứng buff vĩnh viễn (như Greed Ring tăng XP).
- Trước màn chơi, có thể bật các Lời Nguyền (Curses) ở menu chọn Map để tăng độ khó (Quái trâu hơn, nhanh hơn) đổi lại tăng tỷ lệ rớt Cổ vật.

## 8. Giao diện (UI)

- Màn hình trong game tối giản. Có một bảng trong suốt ở góc trái màn hình hiển thị theo thời gian thực (Real-time HUD) danh sách Vòng, Nét, Spells đang sở hữu và trạng thái Resonance hiện tại để người chơi dễ dàng theo dõi hướng build của mình.
