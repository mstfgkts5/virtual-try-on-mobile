# SeeItOn — Kayıt / Giriş Akışı (Tasarım)

Tarih: 2026-11-04 · Durum: onay bekliyor

## Amaç ve neden
Kullanıcılar kendi e-posta/şifreleriyle hesap açıp giriş yapabilsin; gardırop kayıtları bu hesaba bağlansın. Bugün kayıt "başarılı" görünse de oturum açılmadan ana ekrana geçiliyor, oturum hatırlanmıyor, çıkış yok, hata mesajları İngilizce ham Supabase metni. Bitirme demosunda akış sorunsuz ve iki dilli çalışmalı.

## Hedefler
- E-posta + şifre ile **kayıt** ve **giriş** (Supabase Auth). **E-posta doğrulaması yok** (kullanıcı kararı): kayıt olan hemen oturum açmış olur.
- **Oturum hatırlama:** oturum varsa uygulama açılışta doğrudan ana ekran; yoksa tanıtım ekranı.
- **Çıkış:** Ayarlar ekranında giriş yapan kullanıcının e-postası ve "Çıkış yap" butonu; çıkınca tanıtım ekranına dönülür.
- **İki dilli hata mesajları** (TR/EN): hatalı e-posta/şifre, e-posta zaten kayıtlı, şifre çok kısa, geçersiz e-posta, bağlantı yok, bilinmeyen hata.
- Şifre **göster/gizle**, gönderimden önce **e-posta biçimi** ve **en az 6 karakter** kontrolü.
- Debug derlemedeki "Girişi atla" butonu kalır.

## Kapsam dışı
- Google/Apple ile giriş, şifremi unuttum, profil düzenleme, e-posta doğrulaması.
- Gardırobun Supabase'e bağlanması (ayrı iş; bu iş sadece oturumu sağlar).

## Anti-hedefler
- Oturum açılmadan ana ekrana geçilmesi (bugünkü hata).
- Çıkıştan sonra geri tuşuyla ana ekrana dönülebilmesi.
- Kullanıcıya ham İngilizce Supabase hata metni gösterilmesi (bilinen durumlarda).

## Kısıtlar
- `supabase_flutter` 1.10 (gotrue 1.12): `auth.onAuthStateChange` (`Stream<AuthState>`), `auth.currentSession`, `AuthException(message, statusCode)`.
- Supabase panelinde **"Confirm email" kapalı** olmalı — kullanıcı kendisi kapatır.
- Supabase varsayılan şifre alt sınırı 6 karakter.

## Yaklaşımlar
| Yaklaşım | Artı | Eksi |
|---|---|---|
| **1. Oturum dinleyicisi (AuthGate) — seçildi** | Çıkış/oturum süresi dolması her yerde otomatik; elle yönlendirme yok | Mevcut ekran geçişlerinde küçük düzenleme |
| 2. Yalnızca açılışta kontrol | Daha az değişiklik | Çıkış ve oturum bitişi her ekranda elle ele alınmalı |

## Tasarım
- **`AuthGate`** (`lib/screens/auth_gate.dart`): `MaterialApp.home`. `StreamBuilder<AuthState>` ile oturumu dinler; oturum varsa `HomeScreen`, yoksa `OnboardingScreen`. Test edilebilirlik için oturum akışı ve anlık oturum parametre olarak verilebilir (varsayılan: Supabase istemcisi).
- **Giriş/kayıt başarılı olunca** giriş ekranı kendini kapatır (`popUntil(isFirst)`); kök ekranı AuthGate değiştirir. Debug "Girişi atla" mevcut davranışını korur.
- **Çıkış:** `auth.signOut()` + `popUntil(isFirst)`; AuthGate tanıtım ekranını gösterir. Geri tuşuyla ana ekrana dönülemez.
- **Hata eşleme** (`lib/services/auth_errors.dart`): `String authErrorMessage(AppLocalizations l, Object error)` — `AuthException` mesajındaki bilinen ifadeler (`Invalid login credentials`, `User already registered`, `Password should be at least`, `Unable to validate email address`) ve bağlantı hataları çevrilir; bilinmeyen durumda genel hata metni.
- **Doğrulama:** `bool isValidEmail(String)` (basit `x@y.z` kalıbı), şifre ≥ 6; hata alan altında değil SnackBar ile (mevcut stil).
- **Ayarlar ekranı:** "HESAP" bölümü — e-posta + "Çıkış yap" (oturum yoksa bölüm gizli).
- Bilinen eksik: giriş ekranındaki `AuthException` dalına `mounted` kontrolü (inceleme bulgusu).
- Yeni metinler TR/EN ARB dosyalarına eklenir.
- **Test:** AuthGate (oturum var → ana ekran, yok → tanıtım, akışta oturum gelince/gidince geçiş), hata eşleme (her bilinen ifade, iki dil), e-posta doğrulama, Ayarlar'da oturumsuz hesap bölümünün gizli olması.

## Builder'a bırakılanlar (benim kararlarım)
- Hatalar SnackBar ile gösterilir (alan altı hata metni yok).
- E-posta doğrulaması basit kalıp; RFC tam doğrulaması yok.
