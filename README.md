# Mobile Flight Assistant

Repozytorium robocze dla projektu mobilnego asystenta lotu (GA).

## Aktualny zakres

W repo jest wdrozony pierwszy fundament MVP:
- szkielet aplikacji Flutter (`Riverpod`, `go_router`),
- modul `flight_planning` z obliczaniem legow i dystansu,
- lokalny zapis/odczyt tras (SQLite),
- podstawowe ekrany: planowanie, zapisane trasy, ustawienia,
- pierwsze testy jednostkowe dla obliczen geo.

## Wymagania lokalne

1. Flutter SDK (stabilny kanal)
2. Dart SDK (w pakiecie z Flutterem)
3. Android Studio lub Xcode (zaleznie od platformy)

## Uruchomienie

```bash
flutter pub get
flutter test
flutter run
```

## Dziennik prac

Szczegoly etapow znajduja sie w pliku `docs/development-journal.md`.
