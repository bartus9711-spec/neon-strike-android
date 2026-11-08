# NEON STRIKE V3 — Android 5v5 (wersja testowa)
Jedna aplikacja z SOLO 5v5, pokojami MULTI P2P i 8 mapami 3D.

## Nowości
- **8 map:** Port Zero, Dust District, Nightshift, Ironworks, Metro 09, Alpine Base, Old Quarter i Skyline.
- Stylizowane modele i HUD dla 5 fikcyjnie użytych broni: AK-47, M4A4, AWP, USP i Tec-9.
- **SABOTAŻ**: wirtualny nadajnik w strefie A/B. Strona RIFT aktywuje, NOVA wyłącza. Przytrzymaj E (klawiatura), przycisk AKCJA (telefon) albo Y (pad).
- Kosmetyczne paczki i skórki odblokowywane za grę, bez prawdziwych zakupów i losowania.
- **RANKED BETA**: prywatne pokoje na kod oraz *lokalne* MMR, bez globalnego matchmakingu, antycheata i kont serwerowych.
- Czułość dotyku i pada, grafika i ustawienia w trakcie gry.

## Jak pobrać APK
Otwórz [GitHub Actions](https://github.com/bartus9711-spec/neon-strike-android/actions), wybierz najnowszy zielony przebieg **Buduj NEON STRIKE APK** i pobierz paczkę **NEON-STRIKE-Android-APK** z sekcji Artifacts. W ZIP jest plik **app-debug.apk**.

**Uwaga: instalacja nowej wersji:** poprzedni APK testowy może mieć inny certyfikat debug. Wtedy Android nie pozwoli go nadinstalować — przed instalacją V3 konieczne może być odinstalowanie starej aplikacji, co usuwa jej lokalne ustawienia. Docelowe bezproblemowe aktualizacje będą wymagały stałego, prywatnego klucza podpisującego.

## Status
- Kod JS przeszedł kontrolę składni.
- Testy w Chromium ze *zastępczym WebGL* potwierdziły 8 map, solo z 9 botami, menu, skórki, aktywację i wyłączenie wirtualnego nadajnika i ustawienia w grze.
- **Prawdziwe renderowanie WebGL na Androidzie i pełne działanie P2P 5v5 nadal trzeba sprawdzić na telefonach.**
- Globalny ranking online i automatyczne wyszukiwanie graczy wymagają osobnego, bezpiecznego backendu.
