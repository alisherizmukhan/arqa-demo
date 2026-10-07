# Дневник смен

Мобильное приложение для водителя такси. Водитель записывает поездки: время, сумму, комиссию парка, способ оплаты. Приложение показывает итоги дня: сколько получено на руки, выручку, комиссию, число поездок, долю наличных и карты.

Состав репозитория:
- `apps/mobile` — Flutter-приложение;
- `packages/design_kit` — дизайн-кит;
- `backend` — API на FastAPI с PostgreSQL, развёрнут на Railway.

| День (светлая тема) | День (тёмная тема) | Новая поездка |
|---|---|---|
| <img src="docs/screenshots/day_light.png" width="200"> | <img src="docs/screenshots/day_dark.png" width="200"> | <img src="docs/screenshots/add_trip.png" width="200"> |

---

## Требования задания

Эталонный день — **2026-10-01**: 2 поездки, выручка 3 900 ₸, комиссия 585 ₸, на руки 3 315 ₸, наличные 1 500 ₸, карта 2 400 ₸. Эти числа проверяются тестами бэкенда и клиента, а также на развёрнутом API.

| Требование | Статус | Где реализовано | Какой тест доказывает |
|---|---|---|---|
| API: поездки за день и итоги дня | ✅ | `backend/app/api/routes.py` (`GET /trips`, `GET /summary`), `backend/app/domain/summary.py`, `backend/app/domain/day.py` | `backend/tests/integration/test_api_trips.py::test_reference_case_summary`, `::test_reference_case_trips`; `backend/tests/unit/domain/test_summary.py::test_reference_case_from_assignment` |
| Клиент: итоги дня, список поездок, переключение дней | ✅ | `apps/mobile/lib/features/trips/presentation/screens/day_screen.dart`, `apps/mobile/lib/features/trips/domain/entities/daily_summary.dart`, `apps/mobile/lib/features/trips/presentation/providers/trips_providers.dart` | `apps/mobile/test/features/trips/domain/domain_test.dart` («reference case 2026-10-01»); `apps/mobile/test/features/trips/presentation/screens_test.dart` («renders the reference day»); `apps/mobile/test/features/trips/presentation/providers_test.dart` («each day is fetched once…») |
| Создание поездки с валидацией (сумма > 0, конец позже начала) | ✅ | `apps/mobile/lib/features/trips/presentation/screens/add_trip_screen.dart`, `apps/mobile/lib/features/trips/domain/entities/trip_rules.dart`, `backend/app/domain/trip.py` | `apps/mobile/test/features/trips/presentation/trip_form_test.dart`; `backend/tests/unit/domain/test_trip.py::test_invalid_trip_is_rejected`; `backend/tests/integration/test_api_validation.py` |
| Нет дублей при повторной отправке | ✅ | `backend/app/infrastructure/repository.py` (`INSERT … ON CONFLICT (id) DO NOTHING`), `backend/app/application/use_cases.py`; в клиенте `AddTripController` в `trips_providers.dart` и повторы в `add_trip_screen.dart` | `backend/tests/integration/test_idempotency.py` (повтор → 200, гонка параллельных POST → одна строка, другие данные → 409); `providers_test.dart` («retrying the same trip after a network error reuses its id»); `apps/mobile/test/features/trips/presentation/form_behaviour_test.dart` («resent with the same id») |
| Тесты на итоги и на дубли | ✅ | `backend/tests/`, `apps/mobile/test/`, CI в `.github/workflows/ci.yml` | бэкенд: 194 теста; приложение: 220; дизайн-кит: 177. Все проходят в CI |
| README, деплой, скриншоты | ✅ | `README.md`, `backend/Dockerfile`, `railway.json`, `docs/screenshots/` | `GET /health` на Railway отвечает 200; скриншоты рендерит `apps/mobile/test/screens/screenshots_test.dart` |

---

## Как запустить

Нужны Flutter 3.47.6 (Dart 3.13), Python 3.12 с [uv](https://docs.astral.sh/uv/) и Docker.

### Бэкенд локально

```bash
docker compose up -d db          # PostgreSQL 16 на localhost:5433 (+ база driver_diary_test для тестов)
cd backend
uv sync
uv run alembic upgrade head      # создать схему
uv run python -m app             # http://127.0.0.1:8000/docs; пустая база заполняется из data/trips.json
```

Весь стек в Docker: `docker compose --profile full up --build`, API на http://localhost:8000/docs.

Настройки берутся из переменных окружения:

| Переменная | Значение |
|---|---|
| `DATABASE_URL` | Строка подключения к PostgreSQL |
| `PORT` | Порт API |
| `SEED_ON_STARTUP` | Заполнять пустую базу при старте (по умолчанию `true`) |
| `SEED_FILE` | Файл с данными для заполнения |
| `CORS_ORIGINS` | Разрешённые источники (по умолчанию `["*"]`) |

### Мобильное приложение

```bash
flutter pub get                                          # из корня репозитория (pub workspace)
cd apps/mobile
flutter run                                              # работает с развёрнутым API
flutter run --dart-define=API_URL=http://10.0.2.2:8000   # эмулятор Android -> локальный бэкенд
flutter run -d chrome --dart-define=API_URL=http://localhost:8000   # веб -> локальный бэкенд
```

Часовой пояс водителя задаётся флагом `--dart-define=DRIVER_TZ=+05:00` (это значение по умолчанию). После изменения DTO или провайдеров нужна кодогенерация: `dart run build_runner build`.

### Тесты

```bash
# Бэкенд (интеграционным тестам нужен Postgres из docker compose)
cd backend
uv run ruff format --check . && uv run ruff check . && uv run mypy
uv run pytest                    # если Windows блокирует pytest.exe: uv run python -m pytest

# Flutter (из корня репозитория)
flutter analyze
(cd packages/design_kit && flutter test)
(cd packages/design_kit/example && flutter test)
(cd apps/mobile && flutter test)

# Контрактные тесты клиента против запущенного бэкенда
(cd apps/mobile && LIVE_API_URL=http://127.0.0.1:8000 flutter test test/live)
```

### Голдены: локально и в CI

Голден-тесты ([alchemist](https://pub.dev/packages/alchemist)) бывают двух видов:

| Вид | Где лежат | Текст | Когда сравниваются |
|---|---|---|---|
| Платформенные | `test/goldens/<os>/` (например, `windows/`) | настоящие шрифты, для просмотра | только локально (без переменной `CI`) |
| CI | `test/goldens/ci/` (в приложении `test/screens/goldens/ci/`) | текст рисуется прямоугольниками | только в CI |

```bash
# После намеренного изменения внешнего вида: голдены своей ОС
(cd packages/design_kit && flutter test --update-goldens)
(cd apps/mobile && flutter test --update-goldens test/screens/day_golden_test.dart)

# Голдены для CI генерируются в Linux через Docker: метрики шрифтов отличаются между ОС
tool/update_ci_goldens.sh packages/design_kit apps/mobile

# Скриншоты для README (390×844 @2x, настоящие шрифты)
(cd apps/mobile && SCREENSHOTS_DIR=build/screens flutter test test/screens/screenshots_test.dart)
```

---

## Развёрнутый API

- API: https://api-production-6e8b.up.railway.app
- Swagger UI: [`/docs`](https://api-production-6e8b.up.railway.app/docs)

```bash
API=https://api-production-6e8b.up.railway.app

curl $API/health
# {"status":"ok","database":"ok"}

curl "$API/summary?date=2026-10-01&tz=%2B05:00"
# {"date":"2026-10-01","tz":"+05:00","trips_count":2,"revenue":3900,"commission":585,"net":3315,"cash":1500,"card":2400}

curl "$API/trips?date=2026-10-01&tz=%2B05:00"
# {"date":"2026-10-01","tz":"+05:00","trips":[{"id":"t1",...},{"id":"t2",...}]}
```

В `tz` знак `+` кодируется как `%2B`. Без кодирования сервер тоже поймёт `+05:00`.

Создание поездки. `id` — ключ идемпотентности, его генерирует клиент:

```bash
TRIP='{"id":"readme-demo-1","start":"2026-01-15T10:00:00+05:00","end":"2026-01-15T10:25:00+05:00","amount":2500,"payment":"card","commission":375}'

# Новая поездка -> 201
curl -i -X POST $API/trips -H 'Content-Type: application/json' -d "$TRIP"

# Тот же запрос ещё раз -> 200, возвращается сохранённая поездка, дубля нет
curl -i -X POST $API/trips -H 'Content-Type: application/json' -d "$TRIP"

# Тот же id, другая сумма -> 409
curl -i -X POST $API/trips -H 'Content-Type: application/json' \
  -d '{"id":"readme-demo-1","start":"2026-01-15T10:00:00+05:00","end":"2026-01-15T10:25:00+05:00","amount":3000,"payment":"card","commission":375}'
# {"error":{"code":"trip_conflict","message":"trip 'readme-demo-1' already exists with a different payload","field":"id"}}

# Невалидные данные -> 422
curl -i -X POST $API/trips -H 'Content-Type: application/json' \
  -d '{"id":"readme-demo-2","start":"2026-01-15T11:00:00+05:00","end":"2026-01-15T11:20:00+05:00","amount":0,"payment":"cash","commission":0}'
# {"error":{"code":"invalid_amount","message":"amount must be a positive integer","field":"amount"}}
```

Если `readme-demo-1` уже кто-то создал, первый запрос вернёт 200, а не 201. Для проверки 201 возьмите новый `id`.

Все ошибки имеют один формат: `{"error": {"code", "message", "field"}}`. Клиент показывает свой русский текст по `code`, а не `message` сервера.

---

## Что сделано

- **Архитектура бэкенда.** Слои `domain` → `application` → `api` / `infrastructure`.
  - Доменные сущности сами проверяют правила, поэтому невалидная поездка не может существовать.
  - Каждое правило продублировано в базе как `CHECK`.
- **Архитектура приложения.** Структура по фичам (`features/trips/{domain,data,presentation}`) и Riverpod. Ошибки возвращаются как `Result<T>` с запечатанным `Failure`.
- **Дизайн-кит.** Цвета, типографика, отступы и компоненты живут только в `packages/design_kit`.
- **Идемпотентность на уровне базы.**
  - `INSERT … ON CONFLICT (id) DO NOTHING`, затем сохранённая поездка читается и сравнивается с запросом.
  - Атомарность обеспечивает первичный ключ, без «проверить, потом вставить».
  - Тест с параллельными запросами создаёт ровно одну строку.
- **Границы дня в +05:00.**
  - День — полуинтервал `[00:00, следующие 00:00)` в поясе водителя.
  - Поездка относится к дню своего начала. Поездка 23:50–00:20 целиком учитывается в первом дне.
  - Запрос в базу идёт по UTC-интервалу и не зависит от пояса сессии.
- **Деньги — целые тенге.** `int` в Python и Dart, `BIGINT` в базе. Формат в интерфейсе: `3 315 ₸` (узкий неразрывный пробел U+202F, настоящий минус `−585 ₸`).
- **Повторная отправка без дублей.**
  - При обрыве связи, таймауте или 5xx форма повторяет **ту же поездку с тем же `id`**: через 2, 4 и 8 с, затем каждые 30 с.
  - Кнопка «Повторить» отправляет сразу.
  - Ответ 4xx не повторяется: 422 показывается под полем, 409 открывает диалог.
- **Удобство на экране дня.**
  - Кнопка «Сегодня» в шапке.
  - Выбор даты и времени — колесо в стиле iOS на обеих платформах.
  - Сортировка поездок: по времени (по умолчанию — сначала ранние) или по сумме.
  - После сохранения список прокручивается к новой поездке и подсвечивает её.
- **Голдены и скриншоты.** Голдены кита и экрана дня есть в двух темах. Скриншоты всех состояний рендерятся тестами.
- **Доступность.**
  - Цели нажатия не меньше 48 dp, у всех элементов есть подписи для скринридера.
  - Контраст по WCAG AA в обеих темах.
  - Матрица вёрстки: 360 и 390 dp, масштаб текста 1.0 и 1.3. Тест падает при любом переполнении или обрезанном тексте.
- **CI** (`.github/workflows/ci.yml`) — три задачи:
  - бэкенд: ruff, mypy, pytest с настоящим Postgres, покрытие ≥ 95 %;
  - дизайн-кит: analyze, формат, тесты;
  - приложение: актуальность кодогенерации, запрет «сырых» цветов и стилей, analyze, формат, тесты.

---

## Решения и ограничения

Главные решения (остальные с обоснованием — в [`docs/DECISIONS.md`](docs/DECISIONS.md)):

1. **`id` поездки — ключ идемпотентности.** Его генерирует клиент (UUID v4), поэтому повтор безопасен и не нужен отдельный заголовок.
2. **Пояс — фиксированное смещение `+05:00`, а не пояс телефона.** В Казахстане с 2024 года нет перехода на летнее время, поэтому день всегда длится 24 часа.
3. **Итоги дня клиент считает из тех же поездок, что показывает в списке.** Один запрос на день, карточка и список не могут разойтись. `GET /summary` остаётся в API и проверен тестами.
4. **Повторяются только запросы с неизвестным исходом** (сеть, таймаут, 5xx). После правки формы следующий «Сохранить» получает новый `id`.
5. **Строгие типы на входе API.** Pydantic проверяет только типы, бизнес-правила — домен. `true` не принимается как сумма, unix-время не принимается как дата.
6. **Дизайн-кит — единственный источник стилей.** Тест сверяет значения токенов с таблицами в `DESIGN.md`.
7. **Каждый открытый день кешируется на 5 минут, соседние дни загружаются заранее.** Возврат к уже просмотренному дню не показывает загрузку.

Известные ограничения:

- **«Сегодня» не обновляется после полуночи.** Если приложение открыто через полночь, вчерашний день остаётся «Сегодня» до перерисовки экрана или перезапуска.
- **Дата поездки — это выбранный день.** В форме нет поля даты. Чтобы добавить поездку за другой день, нужно сначала переключить день на главном экране.
- **Нет аккаунтов.** API открыт, список поездок один на всех. Аккаунты, роли и вывод денег — следующий этап.
- **Только русский язык.** Поездку нельзя изменить или удалить.
- **Неотправленная поездка живёт, пока открыта форма.** Офлайн-хранилища нет.
- **Кеш дня может отставать до 5 минут,** если поездки добавлены с другого устройства. Свайп вниз обновляет день.

---

## Как использовался ИИ

Код, тесты и документацию писал ИИ-ассистент (Claude Code) по этапам. После каждого этапа я проверял результат и давал согласие на следующий. Ошибки ИИ ловились тестами, скриншотами с настоящими шрифтами и ручными проверками API. Среди них неверная валидация дат, кнопка, растянутая на весь экран, и голдены, которые отличаются между Windows и Linux. Все такие случаи и способы их поймать записаны в [`docs/AI_NOTES.md`](docs/AI_NOTES.md).

---

## Скриншоты

Рендерятся тестами приложения (390×844 @2x, настоящие шрифты).

| День | День, тёмная тема | Новая поездка | Нет связи | Конфликт 409 |
|---|---|---|---|---|
| <img src="docs/screenshots/day_light.png" width="160"> | <img src="docs/screenshots/day_dark.png" width="160"> | <img src="docs/screenshots/add_trip.png" width="160"> | <img src="docs/screenshots/add_trip_offline.png" width="160"> | <img src="docs/screenshots/add_trip_409.png" width="160"> |

Сравнение с макетами — в `docs/design/audit/` и [`docs/DESIGN_AUDIT.md`](docs/DESIGN_AUDIT.md).
