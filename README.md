
- Kiểm tra cấu hình máy tính
  + Cmd: ipconfig
  + Copy Ipv4: vd 192.168.1.1
- Chạy BE:
  + cd HairCareShop.Web
  + sửa Base url api trong api service
  + dotnet watch run --urls "http://192.168.1.1:5194"
- Chạy FE (chạy với điện thoại thật)
  + Bật Developer options => bật USB debugging
  + cd hairshop_app
  + flutter run
    
