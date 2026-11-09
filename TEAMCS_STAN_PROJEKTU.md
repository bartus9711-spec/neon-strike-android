# TeamCS — sprawdzony stan i kierunek projektu

Aktualizacja: 2026-11-09. Ten plik chroni projekt przed powtarzaniem tych samych zadań.

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
