# Карта проекта Pillura Med

Справочник по структуре приложения и **общим методам** — используйте их при добавлении нового кода вместо прямых вызовов Flutter API.

## Структура `lib/`

```
lib/
├── main.dart                    # Точка входа, ProviderScope, AppRoot (lifecycle)
├── firebase_options.dart
│
├── core/                        # Общие утилиты без привязки к фиче
│   ├── app_snackbar.dart        # ★ Единая точка показа SnackBar
│   ├── listen_errors.dart       # ★ Подписка на ошибки провайдера → SnackBar
│   ├── notification_service.dart
│   ├── theme/app_theme.dart
│   └── extension/
│       ├── theme_extension.dart
│       └── time_of_day_extension.dart
│
├── domain/                      # Сущности, enum'ы, контракты репозиториев
│   ├── entities/
│   ├── enums/
│   ├── repositories/
│   ├── errors/
│   └── policies/
│
├── data/                        # Реализации репозиториев (Firebase)
│   ├── repositories/
│   └── models/                  # Данные для маршрутов (route extra)
│
├── presentation/
│   ├── pages/                   # Экраны
│   ├── widgets/                 # Переиспользуемые виджеты
│   └── providers/               # Riverpod-провайдеры
│
└── router/
    ├── app_router.dart          # GoRouter, redirect по auth
    └── scaffold_with_navbar.dart
```

## Навигация (GoRouter)

| Путь | Экран | Вкладка |
|------|-------|---------|
| `/landing` | Landing (старт, разрешения) | — |
| `/welcomePage` | WelcomePage (вход) | — |
| `/medicationPage` | MedicationPage | Лекарства |
| `/profilePage` | ProfilePage | Профиль |
| `/addMedication` | AddMedicationPage | Профиль |
| `/shareMedications` | ShareMedicationsPage | Профиль |
| `/add` | MenuAddPerson | Добавить |
| `/add/ward` | AddWard | Добавить |

Роутер: `lib/router/app_router.dart`. Данные в `extra` — через модели из `data/models/`.

## Провайдеры (Riverpod)

| Провайдер | Файл | Назначение |
|-----------|------|------------|
| `goRouterProvider` | `router/app_router.dart` | Навигация |
| `authNotifierProvider` | `auth_providers.dart` | Авторизация, гостевой режим |
| `linkedUsersProvider` | `auth_providers.dart` | Связанные пользователи |
| `medicationNotifierProvider(userId)` | `medication_provider.dart` | CRUD лекарств |
| `medicationRepositoryByUserIdProvider` | `repository_provider.dart` | Репозиторий по userId |
| `currentUserIdProvider` | `repository_provider.dart` | UID текущего пользователя |
| `notificationServiceProvider` | `notification_provider.dart` | Локальные уведомления |

Состояние фич — через `AsyncNotifier` + `AsyncValue` (`loading` / `data` / `error`).

---

## ★ Общие методы `core/` — обязательно использовать

При добавлении нового кода **не дублируйте** логику напрямую. Используйте существующие утилиты.

### 1. Сообщения пользователю — `AppSnackBar`

**Файл:** `lib/core/app_snackbar.dart`

```dart
import 'package:pillura_med/core/app_snackbar.dart';

AppSnackBar.show(context, 'Текст сообщения');
```

**Нюансы:**
- **Не вызывать** `ScaffoldMessenger.of(context).showSnackBar(...)` напрямую.
- Пока SnackBar виден, повторные вызовы **игнорируются** — нет очереди при быстрых тапах.
- Длительность по умолчанию — 2 секунды; можно передать `duration:`.

**Когда использовать:** успех сохранения, ограничения гостевого режима, «скопировано», любые короткие уведомления снизу экрана.

### 2. Ошибки провайдеров — `listenErrors`

**Файл:** `lib/core/listen_errors.dart`

```dart
import 'package:pillura_med/core/listen_errors.dart';

@override
Widget build(BuildContext context, WidgetRef ref) {
  listenErrors(context, ref, someNotifierProvider);
  // ...
}
```

**Нюансы:**
- Подписывается на `AsyncValue` провайдера и при `hasError` показывает ошибку через `AppSnackBar`.
- Единая точка для ошибок UI — не показывайте ошибки провайдера вручную через SnackBar.

### 3. Тема — `AppTheme` и расширения

**Файлы:** `lib/core/theme/app_theme.dart`, `lib/core/extension/theme_extension.dart`

```dart
// В main.dart уже подключено:
theme: AppTheme.light,

// В виджетах:
context.theme
context.textTheme
context.primaryColor  // бренд #202D85
```

**Нюансы:**
- Новые цвета/стили кнопок и инпутов — добавлять в `AppTheme`, не хардкодить в страницах.
- Брендовый цвет: `Color(0xFF202D85)`.

### 4. Уведомления — `NotificationService`

**Файл:** `lib/core/notification_service.dart`  
**Провайдер:** `notificationServiceProvider`

Инициализация в `AppRoot` после первого кадра. Планирование напоминаний о приёме — только через сервис, не напрямую через пакет уведомлений из UI.

### 5. Время — `time_of_day_extension.dart`

Расширения для `TimeOfDay` — использовать при работе с временем приёма лекарств.

---

## Чеклист при добавлении кода

| Задача | Что использовать |
|--------|------------------|
| Показать короткое сообщение | `AppSnackBar.show(context, '...')` |
| Показать ошибку из провайдера | `listenErrors(context, ref, provider)` |
| Новый экран | `presentation/pages/`, маршрут в `app_router.dart` |
| Состояние фичи | `AsyncNotifier` в `presentation/providers/` |
| Доступ к данным | интерфейс из `domain/repositories/`, реализация в `data/` |
| Данные для навигации | модель в `data/models/`, передача через `state.extra` |
| Переиспользуемый UI | `presentation/widgets/` |
| Стили | `AppTheme` + `context.theme` / extensions |

## Направление зависимостей

```
presentation → domain, core
data         → domain, core
domain       → (ничего из data/presentation)
```

Подробнее о слоях и Riverpod — `.cursor/rules/flutter-clean-arch-riverpod3.mdc`.

## Гостевой режим и ограничения

Проверки `isAnonymous`, `isWard`, `hasShareStatus` — в UI перед действием. Сообщения об ограничениях — только через `AppSnackBar.show`, не через диалоги и не через прямой SnackBar.

Примеры: `menu_add_person.dart`, `add_medication.dart`.
