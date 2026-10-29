# ANKA Windows - ikinci erisim kanali (SADECE OZEL DEPO)

## Durum
Bu klasor YALNIZCA kurulum sablonudur. Buradaki is akisi GitHub'daki herkese acik depoda CALISMAZ. GitHub uzerinden Windows kontrolu icin bilgisayarda bir kez self-hosted runner kurulmalidir. Internet erisimi olmadan kurulum tamamlanamaz. Mevcut Windows bilgisayarinda bir runner kuruldugu dogrulanmamistir.

## Tek seferlik kurulum (Windows internete cikabildiginde)
1. 1982-gokce GitHub hesabinda **Private** gorunurlukle `ANKA_Windows_Kontrol` adli AYRI bir depo olustur.
2. Bu sablonun `anka-windows-audit.yml` dosyasini ozel depoda `.github/workflows/anka-windows-audit.yml` yoluna koy.
3. Depoda **Settings > Actions > Runners > New self-hosted runner > Windows x64** sec. GitHub'in verdigi resmi kurulum komutlarini sadece kendi bilgisayarinda calistir. Yapilandirma sirasinda runner'a `anka-windows` etiketini ekle; mumkunse standart kullanici olarak calistir. Hizmet olarak calistirmak istenirse Windows yonetici izni gerekir.
4. GitHub'da durum **Online** gorundugunde baglanti hazirdir. Bu islem telefon USB baglantisiyla veya sadece GitHub'a dosya yazilarak otomatik tamamlanamaz.

## Uzaktan sinama
Bu ozel depoya `requests/network-check-001.txt` adli bir dosya eklendiginde, Windows uzerindeki runner SADECE sabit ag tanilama komutlarini calistirir ve `reports/latest-network-status.txt` raporunu ozel depoya kaydeder. Raporda parola, belirtec veya API anahtari bulunmaz. Rapor otomatik olarak okunup sorunun kok nedenini belirlemek icin kullanilabilir. DNS/proxy ayarlari bu surumde DEGISTIRILMEZ.

## Guvenlik
- **Herkese acik depoya self-hosted runner baglama.** GitHub bunu guvenlik riski nedeniyle onermiyor.
- Runner'a yonetici yetkisi verme, gerekmedikce hizmet olarak calistirma.
- Kayit belirtecini, parolalari ve API anahtarlarini repoya yazma.
- Buradaki sablon kurulumu ve bilgisayarda komut calistirmayi kanitlamaz.
- Hazirlanmis rapor daha sonra bir degisikligin gercekten ise yaradigini dogrulamak icin kullanilir.

Resmi kaynak: https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/add-runners
