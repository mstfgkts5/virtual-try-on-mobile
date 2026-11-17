import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/core/constants.dart';

void main() {
  test('web backend adresi sayfanın açıldığı bilgisayarı izler', () {
    // iPhone Safari'den Wi-Fi ile açılınca backend aynı bilgisayardadır
    expect(AppConstants.webBaseUrl(Uri.parse('http://10.100.12.89:8080/#/')), 'http://10.100.12.89:8000');
    expect(AppConstants.webBaseUrl(Uri.parse('http://localhost:8080/')), 'http://localhost:8000');
    // Sayfa HTTPS ise backend aynı adreste (Safari'de kamera yalnızca güvenli bağlamda açılır;
    // karışık içerik engellenir; kendi imzalı sertifika tek adres için bir kez onaylanır)
    expect(AppConstants.webBaseUrl(Uri.parse('https://172.20.10.2:8443/#/home')), 'https://172.20.10.2:8443');
    expect(AppConstants.webBaseUrl(Uri.parse('https://seeiton.example.com/')), 'https://seeiton.example.com');
    // Adres yoksa (ör. dosyadan açılmış) yerel bilgisayar
    expect(AppConstants.webBaseUrl(Uri.parse('file:///index.html')), 'http://127.0.0.1:8000');
  });
}
