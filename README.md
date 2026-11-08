# NEON STRIKE — Android (wersja testowa)

To projekt aplikacji Android z jedną grą: **SOLO + MULTI 5v5**, sterowaniem dotykowym i ustawieniami w trakcie gry. Obsługa padów Bluetooth jest zaimplementowana, lecz wymaga testu na telefonie. MULTI wymaga internetu i zewnętrznej usługi P2P.

## Jak pobrać APK na telefonie

1. Otwórz zakładkę **Actions**: https://github.com/bartus9711-spec/neon-strike-android/actions
2. Wybierz **Buduj NEON STRIKE APK**.
3. Jeśli nie ma żadnego uruchomienia, kliknij **Run workflow** („Uruchom proces”), a potem ponownie **Run workflow**.
4. Poczekaj na zielony znaczek przy uruchomieniu. Czerwony oznacza błąd budowania.
5. Wejdź w zakończone uruchomienie i pod **Artifacts** („Pliki wynikowe”) pobierz **NEON-STRIKE-Android-APK**.
6. Rozpakuj pobrane archiwum ZIP. Znajdziesz tam **app-debug.apk**, czyli instalator testowy Androida.

**Uwaga:** kod został przesłany do repozytorium, ale pomyślnego zbudowania APK i działania na rzeczywistym telefonie jeszcze nie potwierdzono. Jeśli budowanie będzie czerwone, trzeba odczytać błąd w zakładce Actions i poprawić projekt.

## Co jest w środku

- Aplikacja Android uruchamiająca lokalny silnik WebGL w WebView.
- Jeden ekran gry SOLO/MULTI (nie dwa osobne HTML-e).
- Ustawienia podczas rozgrywki, regulacja czułości, obsługa ekranu dotykowego.
- Kod do obsługi kontrolerów Android oraz zaproszeń kodem pokoju.
- Skrypt GitHub Actions tworzący testowy APK.

Gra jest prototypem. W trybie MULTI powodzenie połączenia zależy od dostępności usługi sygnalizacji, konfiguracji sieci i urządzenia. Wi-Fi i transmisja komórkowa nie są łączone w jedno łącze.
