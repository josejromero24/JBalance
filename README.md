# JBalance

<img src="JBalance/Assets.xcassets/AppLogo.imageset/LogoApp2.png" width="96" alt="JBalance logo">

JBalance es una app iOS para llevar el control de peso, comida, hidratación, actividad y recordatorios sin depender de una cuenta externa. Los datos principales viven en local y la app solo pide permisos cuando una función los necesita.

## Qué Hace

- Registra peso, objetivo, evolución y tendencias.
- Guarda comidas con notas, señales rápidas y análisis nutricional local.
- Controla hidratación con cantidades habituales.
- Resume actividad con entradas locales o datos importados desde Salud.
- Programa recordatorios locales para peso, agua, check-ins y registros pendientes.
- Sugiere recetas a partir de ingredientes disponibles.
- Analiza fotos de comida con APIs del dispositivo cuando están disponibles.
- Exporta e importa copias de seguridad.

## Proyecto

```text
JBalance/
  App/           Entrada de la app y composición de dependencias
  Core/          Diseño, soporte de plataforma y recursos compartidos
  Domain/        Modelos, contratos, servicios y casos de uso
  Data/          Repositorios e integración local/remota
  Presentation/  Vistas SwiftUI y ViewModels
JBalanceTests/   Tests unitarios y de ViewModels
JBalanceUITests/ Tests de interfaz
```

La arquitectura está separada por capas: `Presentation` coordina estado y UI, `Domain` concentra reglas y contratos, y `Data` implementa persistencia e integraciones. Más detalle en [`JBalance/ARCHITECTURE.md`](JBalance/ARCHITECTURE.md).

## Privacidad

- Perfil, peso, comida, hidratación, actividad y recordatorios se guardan en local.
- Salud/HealthKit es opcional y requiere permiso del usuario.
- Los recordatorios son notificaciones locales.
- Open Food Facts solo se usa cuando se hace una búsqueda de producto por código de barras.

## Requisitos

- Xcode 26 o superior recomendado.
- Proyecto configurado con SDK iOS 26.
- Swift 5.

Para ejecutar en dispositivo físico, configura tu equipo de firma en Xcode. HealthKit y otras capacidades pueden requerir entitlements locales.

## Ejecutar

```bash
git clone https://github.com/josejromero24/JBalance.git
cd JBalance
open JBalance.xcodeproj
```

Selecciona el scheme `JBalance`, configura firma si hace falta y ejecuta.

## Tests

Ejecuta los tests desde Xcode con el scheme `JBalance`.

## Licencia

MIT. Ver [`LICENSE`](LICENSE).
