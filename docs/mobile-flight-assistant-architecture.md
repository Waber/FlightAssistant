# Mobile Flight Assistant — proponowana architektura projektu

## Cel dokumentu

Ten dokument opisuje proponowaną architekturę aplikacji mobilnej dla pilotów GA, której pierwszy etap skupia się na podstawowej nawigacji:
- wybór punktu startu,
- dodawanie kolejnych waypointów,
- rysowanie odcinków pomiędzy punktami,
- wyliczanie sugerowanego kursu,
- prezentacja trasy na mapie,
- zapis i odczyt tras lokalnie.

Dokument jest napisany pod projekt rozwijany w modelu:
- **ja przygotowuję większość implementacji i decyzji technicznych**,
- **Ty nadzorujesz kierunek, testujesz, zgłaszasz poprawki i akceptujesz kolejne etapy**,
- rozwiązania powinny być dobierane tak, aby były **czytelne, możliwe do wytłumaczenia krok po kroku** i bezpieczne dla osoby, która nie ma jeszcze dużego doświadczenia we Flutterze, Darcie, mobilnych mapach i architekturze aplikacji.

To oznacza, że architektura nie powinna być przesadnie „enterprise”, tylko:
- modularna,
- łatwa do rozwijania,
- łatwa do debugowania,
- łatwa do tłumaczenia.

---

## Założenia technologiczne

### Rekomendowany stack na start
- **Flutter** — jedna baza kodu dla iOS i Androida
- **Dart** — główny język aplikacji
- **Riverpod** — zarządzanie stanem
- **go_router** — routing / nawigacja między ekranami
- **Drift lub SQLite** — lokalne przechowywanie danych
- **MapLibre lub Mapbox** — renderowanie mapy i warstw
- **Swift / Kotlin** — tylko tam, gdzie w przyszłości będzie potrzebna natywna integracja

### Dlaczego taki wybór
Ten zestaw jest dobry dla MVP, ponieważ:
- pozwala szybko dostarczać kolejne funkcje,
- utrzymuje jedną bazę kodu,
- ogranicza liczbę decyzji architektonicznych na starcie,
- daje rozsądną ścieżkę rozwoju w kierunku bardziej zaawansowanej aplikacji lotniczej.

---

## Główne założenia architektoniczne

### 1. Prosty core domenowy
Na początku logika nawigacyjna powinna być napisana w Darcie i oddzielona od UI.

To znaczy, że obiekty takie jak:
- `Waypoint`
- `Leg`
- `RoutePlan`
- `NavigationSnapshot`
- `CourseCalculationResult`

nie powinny zależeć od widgetów Fluttera.

Dzięki temu:
- łatwiej testować obliczenia,
- łatwiej tłumaczyć, co robi kod,
- łatwiej w przyszłości wydzielić część do osobnego silnika.

### 2. UI oddzielone od logiki biznesowej
Ekrany powinny wyświetlać dane i reagować na akcje użytkownika, ale nie powinny zawierać ciężkiej logiki obliczeniowej.

Przykład:
- ekran mapy wywołuje akcję „dodaj waypoint”,
- provider lub use case aktualizuje trasę,
- warstwa prezentacji tylko odświeża widok.

### 3. Architektura zorientowana na funkcje
Zamiast dzielić kod wyłącznie wg typów plików, lepiej dzielić go wg obszarów funkcjonalnych.

Na przykład:
- `flight_planning`
- `navigation`
- `map`
- `route_storage`
- `settings`

To lepiej skaluje projekt niż pojedyncze katalogi typu `models`, `services`, `screens` dla całej aplikacji.

### 4. Podejście „explainable architecture”
Każdy większy element powinien być wdrażany tak, by można go było łatwo wyjaśnić.

To oznacza m.in.:
- krótkie pliki,
- małe klasy,
- ograniczenie magicznych skrótów,
- komentarze tam, gdzie logika nie jest oczywista,
- prostsze wzorce zamiast zbyt zaawansowanych abstrakcji.

---

## Proponowana struktura katalogów

```text
lib/
  app/
    app.dart
    router/
      app_router.dart
    theme/
      app_theme.dart

  core/
    constants/
      app_constants.dart
    errors/
      app_exception.dart
      failure.dart
    utils/
      angle_utils.dart
      distance_utils.dart
      geo_utils.dart
      unit_converters.dart
    services/
      logger_service.dart

  features/
    flight_planning/
      domain/
        entities/
          waypoint.dart
          leg.dart
          route_plan.dart
        value_objects/
          coordinate.dart
          bearing.dart
          distance.dart
        services/
          route_calculation_service.dart
        repositories/
          route_repository.dart

      application/
        use_cases/
          create_route_use_case.dart
          add_waypoint_use_case.dart
          remove_waypoint_use_case.dart
          reorder_waypoints_use_case.dart
          calculate_route_summary_use_case.dart
        providers/
          flight_planning_providers.dart
          flight_planning_controller.dart

      data/
        models/
          waypoint_model.dart
          leg_model.dart
          route_plan_model.dart
        datasources/
          local_route_datasource.dart
        repositories/
          route_repository_impl.dart

      presentation/
        screens/
          flight_planning_screen.dart
        widgets/
          route_summary_card.dart
          waypoint_list.dart
          add_waypoint_button.dart

    navigation/
      domain/
        entities/
          aircraft_position.dart
          active_navigation_state.dart
        services/
          navigation_service.dart
          waypoint_sequencing_service.dart
      application/
        providers/
          navigation_providers.dart
          navigation_controller.dart
      data/
        datasources/
          gps_datasource.dart
      presentation/
        widgets/
          navigation_status_panel.dart
          next_waypoint_card.dart

    map_view/
      domain/
        entities/
          map_route_overlay.dart
      application/
        providers/
          map_providers.dart
      presentation/
        screens/
          map_screen.dart
        widgets/
          flight_map_widget.dart
          aircraft_marker.dart
          route_polyline_layer.dart
          waypoint_marker_layer.dart

    route_storage/
      application/
        providers/
          route_storage_providers.dart
      data/
        database/
          app_database.dart
          tables/
            routes_table.dart
            waypoints_table.dart
      presentation/
        screens/
          saved_routes_screen.dart

    settings/
      presentation/
        screens/
          settings_screen.dart

  shared/
    widgets/
      app_scaffold.dart
      loading_indicator.dart
      error_view.dart
      primary_button.dart

main.dart
```

---

## Warstwy projektu

### 1. `presentation`
Warstwa UI:
- ekrany,
- widgety,
- formularze,
- obsługa interakcji użytkownika.

Jej zadanie:
- pokazać dane,
- przekazać intencję użytkownika dalej,
- nie wykonywać skomplikowanych obliczeń.

### 2. `application`
Warstwa pośrednia pomiędzy UI a domeną:
- kontrolery,
- providery,
- use case’y.

Tu umieszczamy logikę typu:
- „co się dzieje po kliknięciu dodaj waypoint”,
- „jak odświeżyć podsumowanie trasy”,
- „z jakich danych złożyć stan ekranu”.

### 3. `domain`
Najważniejsza warstwa biznesowa:
- encje,
- value objecty,
- interfejsy repozytoriów,
- serwisy domenowe z obliczeniami.

To tu powinna mieszkać logika lotniczo-nawigacyjna.

### 4. `data`
Warstwa techniczna:
- modele zapisu,
- implementacje repozytoriów,
- lokalna baza,
- źródła danych GPS,
- integracje z bibliotekami zewnętrznymi.

---

## Najważniejsze moduły domenowe

## `flight_planning`
Odpowiada za budowanie i edycję trasy.

### Encje

#### `Waypoint`
Reprezentuje punkt trasy.
Przykładowe pola:
- `id`
- `name`
- `latitude`
- `longitude`
- `type` (np. departure, enroute, destination, user_defined)

#### `Leg`
Reprezentuje odcinek między dwoma waypointami.
Przykładowe pola:
- `fromWaypoint`
- `toWaypoint`
- `distanceNm`
- `trueCourseDeg`
- `magneticCourseDeg` (później, jeśli dojdzie model deklinacji)

#### `RoutePlan`
Reprezentuje całą trasę.
Przykładowe pola:
- `id`
- `name`
- `waypoints`
- `legs`
- `totalDistanceNm`
- `createdAt`
- `updatedAt`

### Serwis domenowy

#### `RouteCalculationService`
Odpowiada za:
- tworzenie legów z listy waypointów,
- obliczanie dystansów,
- obliczanie kursów,
- podsumowanie trasy.

Ten serwis jest bardzo ważny, bo to jeden z pierwszych kandydatów do późniejszego wydzielenia, jeśli aplikacja urośnie.

---

## `navigation`
Odpowiada za logikę nawigacji „w locie”.

Na pierwszym etapie ten moduł może być prostszy, ale warto go wydzielić już teraz, żeby nie mieszać planowania trasy z aktywną nawigacją.

### Przykładowe odpowiedzialności
- aktualna pozycja samolotu,
- aktywny leg,
- bearing do następnego waypointu,
- informacja o odległości do kolejnego punktu,
- później: cross-track error, ETA, groundspeed.

### Encje

#### `AircraftPosition`
- `latitude`
- `longitude`
- `altitudeFt` (opcjonalnie)
- `groundSpeedKt` (opcjonalnie)
- `trackDeg` (opcjonalnie)
- `timestamp`

#### `ActiveNavigationState`
- `activeRouteId`
- `activeLegIndex`
- `nextWaypoint`
- `distanceToNextNm`
- `desiredTrackDeg`
- `bearingToWaypointDeg`

---

## `map_view`
To warstwa odpowiedzialna za wyświetlenie mapy i nakładek.

Powinna być możliwie cienka: ma pobierać przygotowane dane i rysować je na mapie.

### Odpowiedzialności
- renderowanie waypointów,
- renderowanie linii trasy,
- pokazanie bieżącej pozycji,
- obsługa zoom/pan,
- reagowanie na tapnięcie w mapę.

### Ważna zasada
Logika obliczania trasy nie powinna siedzieć w komponencie mapy.
Mapa ma wyświetlać wynik, a nie liczyć trasę.

---

## `route_storage`
Odpowiada za lokalny zapis danych.

### Zakres na start
- zapis tras,
- odczyt tras,
- usuwanie tras,
- później: eksport/import.

### Dlaczego osobny moduł
Bo dzięki temu łatwo będzie później podmienić:
- samą lokalną bazę,
- format danych,
- albo dodać synchronizację z backendem.

---

## Przepływ danych

### Przykład: dodanie waypointu
1. Użytkownik klika „Dodaj waypoint”.
2. `flight_planning_screen` przekazuje akcję do kontrolera.
3. `FlightPlanningController` wywołuje `AddWaypointUseCase`.
4. Use case aktualizuje `RoutePlan`.
5. `RouteCalculationService` przelicza legi i podsumowanie.
6. Zmieniony stan trafia do providera.
7. UI odświeża listę waypointów i linię na mapie.

### Przykład: uruchomienie aktywnej nawigacji
1. Użytkownik wybiera zapisaną trasę.
2. `NavigationController` pobiera route plan.
3. `GpsDataSource` zaczyna emitować pozycję.
4. `NavigationService` liczy bearing i dystans do aktywnego waypointu.
5. Ekran mapy oraz panel statusu odświeżają się na podstawie nowego stanu.

---

## Zarządzanie stanem

### Rekomendacja: Riverpod
Powód wyboru:
- jest czytelny,
- dobrze działa w większych projektach,
- wspiera testowanie,
- pozwala stopniowo budować architekturę bez nadmiaru boilerplate.

### Proponowane typy providerów
- `Provider` — dla lekkich zależności i serwisów,
- `StateNotifierProvider` lub nowsze kontrolery Riverpoda — dla stanu ekranów,
- `FutureProvider` — dla ładowania zapisanych tras,
- `StreamProvider` — dla strumienia GPS.

### Zasada
Stan widoku powinien być oparty na providerach, a nie na rozproszonym `setState` w wielu miejscach.

---

## Model danych — wersja MVP

## `Waypoint`
```dart
class Waypoint {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final WaypointType type;
}
```

## `Leg`
```dart
class Leg {
  final Waypoint from;
  final Waypoint to;
  final double distanceNm;
  final double trueCourseDeg;
}
```

## `RoutePlan`
```dart
class RoutePlan {
  final String id;
  final String name;
  final List<Waypoint> waypoints;
  final List<Leg> legs;
  final double totalDistanceNm;
}
```

Te modele celowo są proste. Na starcie nie warto dodawać zbyt wielu pól.

---

## Obliczenia nawigacyjne — co umieścić w osobnych utilach/serwisach

Na początku wydzieliłbym osobne funkcje do:
- obliczania dystansu między dwoma współrzędnymi,
- obliczania true bearing,
- normalizacji kątów do zakresu 0–360,
- konwersji jednostek,
- ewentualnie później: cross-track error.

### Dlaczego osobno
Bo to logika:
- wielokrotnego użytku,
- łatwa do testowania,
- krytyczna z punktu widzenia poprawności działania.

---

## Baza danych

### Na start
Najprostszy sensowny wariant:
- SQLite
- warstwa dostępu przez Drift albo prostą bibliotekę SQLite

### Co przechowywać
- route header (`id`, `name`, `createdAt`, `updatedAt`)
- waypointy przypisane do trasy
- kolejność waypointów

### Czego nie robić na starcie
- nie robić od razu backendu,
- nie robić synchronizacji kont,
- nie komplikować modelu wersjonowania danych.

Lokalny zapis w zupełności wystarczy dla pierwszego etapu.

---

## Testy

To ważny element, szczególnie jeśli większość kodu mam przygotowywać ja, a Ty będziesz nadzorował rezultat.

### 1. Unit testy
Obowiązkowo dla:
- obliczeń dystansu,
- bearingu,
- składania legów,
- sumowania trasy,
- logiki przełączania waypointów.

### 2. Widget testy
Dla:
- listy waypointów,
- podstawowych ekranów,
- stanów błędów i ładowania.

### 3. Manualne testy urządzeniowe
Na MVP bardzo ważne dla:
- GPS,
- mapy,
- działania na realnym urządzeniu,
- zachowania przy zmianie orientacji i przy wznowieniu aplikacji.

---

## Plan implementacji etapami

## Etap 1 — MVP nawigacyjne
Zakres:
- projekt Flutter,
- mapa,
- dodawanie waypointów,
- rysowanie trasy,
- liczenie dystansu i kursu,
- zapis i odczyt lokalny,
- podstawowy ekran nawigacji.

### Co powinno powstać technicznie
- podstawowy routing aplikacji,
- moduł `flight_planning`,
- moduł `map_view`,
- moduł `route_storage`,
- proste utilsy geograficzne,
- pierwsze testy jednostkowe.

## Etap 2 — aktywna nawigacja
Zakres:
- GPS live,
- wskazanie aktualnej pozycji,
- active leg,
- bearing do następnego punktu,
- dystans do kolejnego punktu,
- panel statusowy.

## Etap 3 — rozwój lotniczy
Zakres:
- lotniska,
- baza punktów,
- offline maps,
- przestrzenie powietrzne,
- import/export GPX,
- elementy bardziej lotnicze.

---

## Jak powinien wyglądać sposób współpracy przy tym projekcie

Ponieważ to ja mam wykonywać większość pracy implementacyjnej, a Ty masz nadzorować oraz poprawiać kierunek, proponuję następujący model:

### 1. Każdą większą decyzję opisuję prostym językiem
Przy wdrażaniu nowych elementów powinienem każdorazowo wyjaśniać:
- po co to wprowadzamy,
- gdzie to trafia w architekturze,
- jakie problemy rozwiązuje,
- jakie są alternatywy,
- dlaczego wybrałem właśnie to.

### 2. Unikamy nadmiernie skomplikowanych wzorców
Nie ma sensu na początku wprowadzać zbyt wielu warstw abstrakcji, jeśli nie dają realnej wartości.

### 3. Każdy etap powinien kończyć się działającym fragmentem aplikacji
Zamiast budować najpierw „idealną architekturę”, lepiej budować kolejne pionowe kawałki funkcji.

### 4. Kod powinien być „czytelny do nauki”
To znaczy:
- sensowne nazwy,
- komentarze przy trudniejszej logice,
- małe pliki,
- ograniczenie ukrytych zależności,
- unikanie zbyt sprytnego kodu.

---

## Ryzyka projektowe

### 1. Zbyt wczesna komplikacja architektury
Ryzyko: projekt stanie się trudny do rozwijania zanim powstanie działające MVP.

### 2. Zbyt mocne związanie logiki z biblioteką mapową
Ryzyko: późniejsza zmiana map lub warstw będzie kosztowna.

### 3. Brak testów w obliczeniach nawigacyjnych
Ryzyko: aplikacja będzie wizualnie działać, ale podawać błędne wyniki.

### 4. Przenoszenie zbyt wielu rzeczy do natywnego kodu za wcześnie
Ryzyko: wzrost kosztu utrzymania i spadek szybkości developmentu.

---

## Rekomendacje końcowe

Na pierwszy etap rekomenduję:
- **całość logiki w Darcie**,
- **Flutter jako główny framework**,
- **modułową architekturę opartą o feature’y**,
- **oddzielenie domain/application/presentation/data**,
- **lokalny storage bez backendu**,
- **testy jednostkowe dla obliczeń od samego początku**.

To będzie najbezpieczniejszy i najbardziej praktyczny fundament pod rozwój aplikacji lotniczej.

---

## Narzędzia rekomendowane do budowy projektu

### IDE / edytor

#### 1. Visual Studio Code
Najlepszy wybór na start, jeśli chcesz prostsze środowisko i szybsze wejście.

Warto doinstalować rozszerzenia:
- Flutter
- Dart
- Error Lens
- GitLens
- Todo Tree
- Pretty Dart / formatowanie zgodne z Dart

#### 2. Android Studio
Bardzo przydatne nawet jeśli głównie będziesz pracował w VS Code.

Dlaczego warto je mieć:
- emulator Androida,
- zarządzanie SDK Android,
- inspekcja logów,
- debugowanie problemów builda,
- podgląd narzędzi mobilnych.

#### 3. Xcode
Niezbędne, jeśli chcesz budować i testować iOS na Macu.

Potrzebne do:
- buildów iOS,
- simulatora iPhone,
- podpisywania aplikacji,
- rozwiązywania problemów natywnych po stronie Apple.

---

## Narzędzia dodatkowe

### Git + GitHub / GitLab
Do wersjonowania kodu i pracy etapami.

### Figma
Do szybkich makiet ekranów, nawet bardzo prostych.

### Postman / Bruno
Na później, jeśli dojdzie backend lub integracje sieciowe.

### DBeaver albo DB Browser for SQLite
Do podglądu lokalnej bazy danych podczas developmentu.

### iOS Simulator + Android Emulator
Do codziennych testów funkcjonalnych.

### TestFlight / Firebase App Distribution
Do późniejszego rozsyłania wersji testowych.

---

## Rekomendowany setup roboczy na start

Najbardziej praktyczny wariant dla tego projektu:
- **VS Code** jako główne IDE
- **Android Studio** do Android SDK i emulatora
- **Xcode** do iOS buildów i simulatora
- **Git** do kontroli wersji
- **Figma** do prostych makiet
- **DB Browser for SQLite** do weryfikacji danych lokalnych

To będzie dobry balans między prostotą, możliwościami i wygodą nauki.

---

## Ostatnia uwaga organizacyjna

Ponieważ projekt ma być rozwijany głównie przeze mnie przy Twoim nadzorze, warto od początku przyjąć zasadę, że:
- każdy większy moduł będzie miał krótkie wyjaśnienie architektoniczne,
- każda zmiana będzie uzasadniona prostym językiem,
- każda nowa technologia będzie wprowadzana stopniowo,
- priorytetem będzie działające MVP, a nie maksymalnie zaawansowana architektura.

To podejście najlepiej pasuje do projektu, który ma jednocześnie powstać i służyć jako proces nauki technologii.
