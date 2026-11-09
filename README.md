# TEAMCS ARENA 4v4 — natywna gra 3D (Godot 4.7.2)

Projekt Android z rzeczywistym światem 3D, animowanymi ludzkimi postaciami,
8 mapami i pojedynkami drużynowymi na bezkrwawe impulsy energetyczne.

## Co faktycznie działa w natywnym prototypie

- Mecz **4 na 4**: jeden gracz i trzech sojuszników przeciw czterem botom.
- Punkty drużyn, limit rundy, odnawianie osłony oraz odradzanie postaci.
- **Osiem aren** o różnych układach i art direction:
  port, pustynia, nocne miasto, fabryka, metro, góry, stare miasto i wieżowce.
- Teksturowane modele ludzkich postaci 3D z animacjami bezczynności i chodzenia.
- Materiały fotograficzne PBR i oddzielne niebo oraz oświetlenie map.
- Grafika Low / High / Ultra, sterowanie dotykowe, obsługa pada i klawiatury.
- Kamera pierwszoosobowa, przybliżenie, dźwięki sterowania i efektów elektronicznych.

## Sterowanie

**Telefon:** lewy joystick = ruch, przeciąganie po prawej = obracanie kamery,
PULS = impuls energetyczny, ŁADUJ = odnów energię, ZOOM = przybliżenie,
SKOK = skok, BIEG = szybszy ruch.

**Komputer:** WASD = ruch, F = impuls, R = energia, E = przybliżenie,
spacja = skok, Esc = ustawienia. Można też korzystać z podłączonego pada.

## Budowa

Workflow `.github/workflows/godot-android-qa-apk.yml` ma tryb ręcznego
uruchamiania: **nie** uruchamia się automatycznie przy każdym zapisie kodu.
Wykorzystuje oficjalny silnik i szablony eksportu Godot 4.7.2, Java/Android
Gradle oraz narzędzie PBR CC0, a na koniec kontroluje podpis APK, uruchomienie
na emulatorze i niepusty zrzut renderowanej sceny.

## Uczciwy status

To **działający prototyp rozgrywki offline**, a nie ukończona komercyjna gra.
Brakuje pełnego internetu między graczami, usług matchmakingowych, kont,
globalnego rankingu, pełnych animacji bojowych i profesjonalnych map tworzonych
ręcznie przez artystów 3D. Pokazywany FPS emulatora z programowym GPU nie
stanowi pomiaru wydajności konkretnego telefonu.

Zweryfikowano ekran gry w Androidzie 15 na emulatorze. Działanie na każdym
telefonie i Androidzie 16 pozostaje do zweryfikowania praktycznie.

## Prawa do assetów

- Materiały tekstur: Poly Haven (CC0).
- Animowany model człowieka Soldier.glb z repozytorium przykładów three.js
  (źródło i powiązane powiadomienia w `godot/assets/models/README-Soldier-license.txt`).
- Zapewniony awaryjny model RobotExpressive (Quaternius, CC0).
- Dźwięki elektroniczne są generowane w kodzie, bez zapożyczonych nagrań.
