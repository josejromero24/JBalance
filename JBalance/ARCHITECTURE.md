# JBalance Architecture

Esta estructura separa la app en capas más cercanas a Clean Architecture + MVVM.

## App
Punto de entrada y composición raíz.

`JBalanceDependencies` crea las implementaciones concretas (`LocalStorageRepository`, `HealthKitRepository`, analizadores locales y schedulers) y las inyecta en ViewModels.

## Core
Componentes transversales:
- `DesignSystem`: tema, colores y componentes visuales compartidos.
- `Support`: wrappers de plataforma.
- `Resources`: soporte de persistencia generado/base.

## Domain
Reglas y contratos:
- `Models`: entidades de negocio.
- `Repositories`: protocolos.
- `UseCases`: casos de uso.
- `Services`: lógica local pura, como el motor de patrones de comida.

`Domain` no importa frameworks de UI/plataforma como SwiftUI, UIKit, Vision, FoundationModels, CoreData, UserNotifications o HealthKit. Los nombres `HealthKit*` son contratos/modelos de dominio para aislar la implementación real.

## Data
Implementaciones concretas de repositorios:
- almacenamiento local
- HealthKit
- clientes remotos como Open Food Facts

## Presentation
Vistas y ViewModels:
- `Presentation/App`: estado principal de la app.
- `Presentation/Features/*`: pantallas agrupadas por feature.

## Tests
Los tests cubren el motor local de patrones, decodificación retrocompatible y mapeo de foto a etiquetas.


## AppViewModel split

`AppViewModel` queda como estado raíz compartido y orquestador de casos de uso. La composición concreta vive en `JBalanceDependencies`.

La lógica está separada por extensiones:
- `AppViewModel+Profile`
- `AppViewModel+Weight`
- `AppViewModel+Food`
- `AppViewModel+HealthKit`
- `AppViewModel+Trends`

El siguiente paso, si hace falta más aislamiento, sería reemplazar estas extensiones por ViewModels independientes por pantalla.


## Feature ViewModels

La UI ya no consume `AppViewModel` directamente en las pantallas principales.

`ContentView` crea un `AppViewModel` raíz y lo inyecta en:
- `DashboardViewModel`
- `WeightHistoryViewModel`
- `FoodDiaryViewModel`
- `ProfileViewModel`

`AppViewModel` mantiene el estado compartido y la composición de casos de uso.
Los feature ViewModels exponen solo lo que necesita cada pantalla.


## Hydration

La hidratación vive como entidad propia:
- `HydrationEntry`
- `HydrationContainer`
- `HydrationEntryRepositoryProtocol`
- `HydrationUseCases`

La UI la consume desde `FoodDiaryViewModel` y se muestra también en Dashboard.


## Local notifications

Los recordatorios son locales y no usan push/APNs:
- `ReminderSettings`
- `ReminderSettingsRepositoryProtocol`
- `ReminderSettingsUseCases`
- `LocalNotificationScheduler`
- `AppViewModel+Notifications`
- `ReminderSettingsView`

Cubren peso diario, agua, check-in nocturno, aviso de falta de registro y aviso personalizado por hora.


## Recipes + food image analysis

Tab `Recetas`:
- varias fotos por alimento/producto
- Vision local para clasificación visual
- OCR local para ingredientes/tabla nutricional
- barcode local
- Open Food Facts si hay código e internet
- ingredientes editables
- recetas locales sin API

Los wrappers de plataforma viven fuera de `Domain`:
- `BetterFoodImageAnalyzer`
- `LocalPhotoFoodSignalImageAnalyzer`
- `FoundationModelsRecipeSuggestionEngine`

La lógica pura de mapeo de etiquetas y recetas vive en `Domain`.
