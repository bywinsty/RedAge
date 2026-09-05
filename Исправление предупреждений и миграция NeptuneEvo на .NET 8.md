# Исправление предупреждений и миграция NeptuneEvo на .NET 8

## Результат

Текущая сборка успешна: 3 проекта собраны, ошибок нет. План устраняет все пять предупреждений, уязвимые зависимости и переводит решение с неподдерживаемого `netcoreapp3.1` на `net8.0`. Из-за ограниченной поддержки .NET 8 и зависимости RAGE MP от старого Bootstrapper развёртывание выполняется через параллельный пилот без изменения действующего сервера.

## Изменения

1. **Базовая миграция**

   - Установить .NET SDK `8.0.424` и Runtime `8.0.30` x64; добавить корневой `global.json` с `rollForward: latestPatch`.
   - Перевести `NeptuneEvo`, `NeptuneEvoSDK` и `Localization` на `net8.0`.
   - Удалить устаревший `PackageReference Update="Microsoft.NETCore.App" Version="2.0.0"`.
   - Задать безусловный `PlatformTarget=x64` для `NeptuneEvo` и `NeptuneEvoSDK`; сохранить solution-конфигурацию `Any CPU` и текущую структуру выходных каталогов.
   - Изменить путь ресурса в `meta.xml` на `bin/Debug/net8.0/NeptuneEvo.dll`.
   - Не изменять пользовательские незакоммиченные файлы и не перезаписывать существующий `Build-RedAge.cmd`.

2. **Устранение текущих предупреждений**

   - Обновить Newtonsoft.Json в основном проекте и SDK с `12.0.3` до `13.0.4`, устранив `NU1903` ([описание уязвимости](https://github.com/advisories/GHSA-5crp-9r3c-p9vr)).
   - В `Localization/Library.cs` заменить негeneric `Enum.GetValues(...)` на `Enum.GetValues<DataName>()`, устранив потенциальное null-unboxing `CS8605`.
   - Заменить неиспользуемый `catch (Exception e)` на обработку ожидаемого `FormatException` с выводом имени элемента и текста исключения; неожиданные ошибки больше не скрывать.
   - Не подавлять `MSB3270`: архитектура проектов должна совпадать с AMD64 `Bootstrapper.dll`, как рекомендует [документация MSBuild](https://learn.microsoft.com/en-us/visualstudio/msbuild/errors/msb3270).

3. **Поэтапное обновление зависимостей**

   - Этап БД:
     - заменить runtime-зависимость `linq2db.MySql 3.3.0` на `linq2db 6.4.0`;
     - оставить `linq2db.MySql 6.4.0` только как T4-инструмент с `PrivateAssets=all`;
     - обновить `MySqlConnector` до `2.6.2`;
     - заменить `MySqlBackup.NET` на `MySqlBackup.NET.MySqlConnector 2.7.1`;
     - удалить `MySql.Data`;
     - переключить LINQ to DB с `"MySql.Data.MySqlClient"` на `ProviderName.MariaDB10MySqlConnector`;
     - обновить namespace в SQL backup-коде и проверить преобразование всех трёх T4-шаблонов.
   - Этап остальных библиотек:
     - `StackExchange.Redis 3.1.31`;
     - `System.Data.SQLite.Core 1.0.119` в обоих проектах;
     - `Otp.NET 1.4.1`.
   - После каждого этапа выполнять restore, rebuild и интеграционные проверки. Не маскировать транзитивную уязвимость `System.Drawing.Common 5.0.0` прямым pin: она должна исчезнуть после удаления старых цепочек MySql.Data/Redis.

4. **Чистый RAGE runtime**

   - Добавить воспроизводимый скрипт `Prepare-RageRuntime.ps1`, принимающий официальный архив .NET Runtime `8.0.30` win-x64, текущий RAGE runtime и выходной каталог.
   - Формировать runtime с нуля, а не накладывать .NET 8 поверх 3.1.
   - Из старого runtime переносить только RAGE-компоненты: `Bootstrapper*`, MessagePack, Roslyn, Colorful.Console, Ben.Demystifier, xxHash и необходимые System.Composition-сборки.
   - Не переносить старые `coreclr`, `hostpolicy`, `System.*`, отладочные и servicing-файлы .NET 3.1.
   - Помещать Newtonsoft.Json `13.0.4` также в runtime и проверять загрузку всех типов Bootstrapper.
   - Версии, архитектуру и контрольные суммы записывать в манифест сборки.

## Проверка и развёртывание

- Создать отдельный каталог `E:\RedAge-net8-pilot`; действующий `E:\RedAge` оставить пригодным для мгновенного отката.
- Добавить pilot-compose с MariaDB `10.5.19` и Redis 7, доступными только через loopback. Использовать одноразовые учётные данные и отдельные Docker volumes.
- Импортировать `main.sql`, `mainconfig.sql` и `mainlogs.sql`; создать обезличенный pilot-вариант `settings/mainDB.json`. Сервер RAGE запускать с `announce=false` на порту `22006`.
- Проверить:
  - Debug и Release rebuild без `NU1903`, `MSB3270`, `CS8605`, `CS0168`;
  - отсутствие известных прямых и транзитивных уязвимостей через `dotnet list package --vulnerable --include-transitive`;
  - загрузку CoreCLR, Bootstrapper и NeptuneEvo без `TypeLoadException`, hash mismatch и ошибок разрешения CoreCLR;
  - чтение/запись во всех трёх БД, транзакции и типовые LINQ-запросы;
  - SQL backup/restore, Redis connect и pub/sub, SQLite, OTP, JSON и Localization;
  - повторный запуск, подключение клиента и 24-часовой pilot-soak без новых необработанных исключений.
- Продвижение разрешать только после прохождения всех проверок. При несовместимости RAGE Bootstrapper с .NET 8 пилот останавливается, production не меняется; исправление не подменяется подавлением ошибок.
- После успешного .NET-релиза отдельным изменением обновить MariaDB с 10.5 до 10.11 LTS: восстановить копию данных, выполнить upgrade, повторить интеграционные тесты и только затем переключить production.

## Интерфейсы и допущения

- Публичные игровые API, сетевые контракты и схема БД не меняются.
- Меняются TFM, путь DLL, архитектура сборки и внутренний ADO.NET-провайдер.
- RAGE MP официально документирует `netcoreapp3.1`, поэтому .NET 8 считается совместимым только после полного пилота ([RAGE MP FAQ](https://wiki.rage.mp/wiki/Serverside_CSharp_FAQ)).
- .NET 8 поддерживается лишь до 10 ноября 2026 года; после стабилизации необходимо отдельное обновление до .NET 10 до этой даты ([политика поддержки .NET](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core)).
- MariaDB 10.5 снята с поддержки с июня 2025 года; её использование допускается только для точного пилотного воспроизведения текущей среды ([жизненный цикл MariaDB](https://mariadb.org/about/)).
