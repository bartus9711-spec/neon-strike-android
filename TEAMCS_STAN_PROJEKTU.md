# TeamCS — sprawdzony stan i kierunek projektu

Aktualizacja: 2026-11-10. Ten plik chroni projekt przed powtarzaniem tych samych zadań.

## Aktywny etap: naprawa rzeczywistego renderowania

Gałąź robocza: `teamcs-visual-render-fix-20261109-atlas`, bazuje na `teamcs-natural-motion-20261109-atlas` (`228e4ee51c9e`). Stan sprzed naprawy: `d0198aa23c28`. Poprzednie zielone Actions nie dowodziły widoczności operatorów; obejrzane obrazy Androida pokazywały puste podium.

- Przyczyna: dopasowanie modeli według surowego `Mesh.get_aabb()` pomijało skin/bind matrices. CT był skalowany przez około 0.00000084, T przez 83, a obu dodatkowo błędnie obracano jak modele Z-up. Po deformacji skórą oba źródła są Y-up i mają około 2 m wysokości.
- Naprawa: mierzenie zdeformowanej pozy spoczynkowej, dopasowanie do 1.75 m i podłoża, cache pomiaru raz na plik źródłowy; brak obliczeń wierzchołków w każdej klatce.
- Poprawiono osadzenie słuchawek CT na czapce przez lokalną kopię bindów; usunięto unoszące się znaczniki i przeniesiono kolory drużyny na materiały ubrania. Oryginalne pliki GLB bez zmian.
- Ukryte lobby zatrzymuje animacje podglądu i jego renderowanie. Zwykły start nie wykonuje odczytu obrazu GPU.
- Test pikseli porównuje każdego operatora z pustą sceną i sprawdza powierzchnię, wysokość oraz położenie sylwetki. Kontrola negatywna (istniejące, ale niewidoczne modele) musi zakończyć się błędem. Ten sam test uruchamia się na emulatorze Androida tylko z cechą eksportu `teamcs_render_qa`; ARM64 dla telefonu jej nie zawiera.
- Zweryfikowano lokalny render OpenGL (Godot 4.6.3, llvmpipe), geometrię, lobby oraz 20 asercji ekonomii. Testy CI/Androida tej poprawki wymagają jeszcze wyniku nowego commitu — nie traktować tego wpisu jako potwierdzenia APK.
- CI `42868278620` (`799049f`) zaliczyło import, testy geometrii/ekonomii, piksele desktopowe i osiem map, ale zatrzymało się na Androidzie: brak sygnału testu pikseli i czarny podgląd. Poprawka uruchamia QA przez jawną cechę eksportu, pobiera rzeczywistą ścieżkę user:// z aplikacji i przywraca UPDATE_ALWAYS na pierwszą klatkę podglądu. Wymaga nowego testu Androida.
- Uzupełniono kredyty klipów Quaternius i 100STYLE na podstawie przypiętego README upstream; plik z atrybucją jest jawnie dołączany do eksportu. Pobieranie modeli sprawdza SHA-256.

### Porównanie istniejących gałęzi

| Gałąź z datą 20261109-atlas | Sprawdzony commit | Co zachować |
| --- | --- | --- |
| teamcs-human-characters | 2641b1c2ecaf | baza GLB i ekonomii |
| teamcs-verified-humanoid | 8ee34733d136 | różne modele CT/T w lobby; zawarte w natural-motion |
| teamcs-natural-motion | 228e4ee51c9e | idle/walk/run/sprint i płynna prędkość; wybrana baza |
| teamcs-integrated-humanoids | a01e3fd348c1 | istniejące profile broni FPS, blokada inputu przy zakupach i HUD amunicji; osobna gałąź, jeszcze nie scalona |

### Następny etap po potwierdzeniu Androida

Dodatkowo lokalnie wykryto i naprawiono dwa koszty/regresje: rysowanie całej areny za nieprzezroczystym lobby (558 → 86 wywołań rysowania w OpenGL/llvmpipe, bez obietnicy FPS telefonu) oraz przełączanie poruszających się botów do idle poniżej 1.5 m/s lub podczas hamowania. Test botów sprawdza ruszanie, hamowanie i zatrzymanie; przed poprawką pierwsze dwa przypadki nie przechodziły. Test sceny weryfikuje przywrócenie 3D po GRAJ i zakupach.

1. Przenieść animacje na szczegółowy model taktyczny (źródłowy GLB nadal bez klipów), ocenić stopy, barki i chwyt broni w ruchu. Aktualny model T nadal ma uproszczony opancerzony wygląd; sam poprawny render nie spełnia całego celu artystycznego.
2. Zweryfikować i przenieść istniejące zmiany widoku broni z integrated-humanoids bez przepisywania ekonomii/menu.
3. Dopiero potem detal otoczenia i pomiary czasu klatki na fizycznym Androidzie. FPS z renderera programowego/emulatora nie jest wynikiem telefonu.

## Cel
Pełnoprawna taktyczna gra na Androida z czytelnym lobby, humanoidalnymi operatorami CT/T, animacjami i mapami. Nie prezentować prototypów z figurami lub neonowymi blasterami jako gotowej gry.

## Sprawdzona podstawa graficzna
- Gałąź **teamcs-human-characters-20261109-atlas** ma test CI **42665989357 zakończony sukcesem**: import ludzkich modeli, test geometrii/animacji, test ekonomii, eksport APK i uruchomienie emulatora Android 15.
- `godot/scripts/operative.gd` próbuje załadować importowane GLB; kod proceduralny pozostaje tylko jako awaryjny fallback.
- `godot/tools/fetch_human_models.py` pobiera z przypiętego commitu GLB o zweryfikowanych długościach i formacie:
  - `soldier.glb`: 3 094 592 bajty, 1 mesh, 50 klipów animacji (m.in. idle/ready/walk/run)
  - `soldier_tac.glb`: 4 532 132 bajty, 15 meshy, **brak własnych klipów animacji**.
- `godot/assets/models/ATTRIBUTION.md` zawiera źródła i warunki CC BY 4.0. Zachować kredyty.
- **Same pliki GLB nie są zapisane w Git; CI pobiera je przed importem.** Sprawdzać build po pobraniu.
- Wynik testu nie dowodzi fotorealistycznego wyglądu na telefonie. Przed oceną grafiki konieczny podgląd renderów.

## Czego nie powtarzać
- System zakupów, saldo rund, zmiana slotów i amunicja mają już implementację i testy; bez potrzeby nie przebudowywać ponownie.
- Gałąź `teamcs-economy-buy-menu-20261109-atlas` ma dodatkowy widok pierwszoosobowy, ale CI `42676291901` **nie przeszło** przez dwa błędy inferencji typów w `main.gd`. Poprawka `6a1ed3175a67` została zapisana; nie uznawać jej za potwierdzoną przed nowym CI.
- Gałąź `teamcs-imported-animated-characters-20261109-atlas` CI `42677830618` **nie przeszło** z powodu tych samych błędów. Nie traktować jej jako stabilniejszej niż zweryfikowana gałąź z ludzkimi modelami.

## Kolejność dalszych prac
1. Ogląd i weryfikacja faktycznych renderów CT/T na ekranie Androida; ocena ruchu, skali i sylwetek, szczególnie CT bez animacji źródłowych.
2. Poprawki postaci i animacji; koniecznie bez utraty obecnych działających funkcji.
3. Poprawki rzeczywistej scenografii/map oraz jakości widoku pierwszoosobowego, zamiast kolejnych przeróbek ekonomii.
4. Dopiero po stabilnych testach i oglądzie — dalsze tryby sieciowe i dopracowanie rozgrywki.

## Obowiązkowa kontrola przed KAŻDYM etapem
1. Sprawdzić dostępne gałęzie i pliki, żeby nie napisać drugi raz istniejącego kodu.
2. Porównać gałąź roboczą ze zweryfikowaną i sprawdzić licencje materiałów.
3. Zmieniać jeden obszar na raz; nie przepisywać sprawnych modułów bez powodu.
4. Zweryfikować Godot parser/import, test mechaniki i Android emulator; przed oceną grafiki obejrzeć faktyczny obraz.
5. Nazywać „gotowe” tylko to, co przeszło stosowny test.
