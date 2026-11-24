# Architecture

Sakina uses a feature-first clean architecture. Each feature owns its `domain` (pure Dart models
and rules, plus repository interfaces), `data` (SQLite or SharedPreferences implementations), and
`presentation` (Riverpod notifiers and widgets). Cross-cutting infrastructure lives in `core`;
reusable UI lives in `shared`.

```
lib/
  main.dart, bootstrap.dart, app.dart
  core/
    database/     AppDatabase: schema and migrations (sqflite)
    providers/    infrastructure providers, revision counters, injectable clock
    router/       GoRouter (StatefulShellRoute with four tabs, plus pushed routes)
    services/     haptics, sound (audioplayers), notifications (local only)
    theme/        palette, semantic color tokens, typography, spacing, motion
    utils/        dates, formatting, TapGuard
  features/<feature>/{domain,data,presentation}
  shared/widgets/
```

## Technology choices

| Concern | Choice | Why |
| --- | --- | --- |
| State | Riverpod 3 (`Notifier`, `AsyncNotifier`, `FutureProvider`) | Compile-safe dependency graph, easy overrides for tests, no code generation |
| Navigation | GoRouter `StatefulShellRoute.indexedStack` | Each tab keeps its state; detail screens are pushed over the shell |
| Storage | sqflite for records, SharedPreferences for settings | Relational queries for statistics; simple keys for preferences |
| Animation | Implicit animations, `AnimationController`, flutter_animate | Physics-like bead motion is driven directly; entrances use flutter_animate |
| Rendering | `CustomPainter` | Beads, tassel, LCD digits, charts, heatmap, patterns and icons are all vector-drawn |

## Counting pipeline

```
tap or drag ─► TasbihController.increment()
                 │ TapGuard (70 ms) rejects double fires
                 │ CounterSession.increment(now) (pure: rounds, active time)
                 │ goal crossing check against today's in-memory counts
                 ├─► state = AsyncData(...)          (UI updates on the same frame)
                 ├─► haptics / sound                 (respecting settings)
                 └─► serial write queue ─► SessionRepository.save(session, dayDelta: +1)
                                             one transaction: sessions row + session_days row
                     debounced countingRevision ─► statistics read models refresh
```

- The controller never awaits the database on the counting path, so input latency is independent
  of I/O. Writes are chained on a single `Future`, so they always land in order.
- The app flushes the queue when it goes to the background.
- `CounterSession` is immutable and pure. All counting rules (rounds, boundaries, pause, undo,
  idle-capped active time) are unit-tested without Flutter.

## Data model

| Table | Purpose |
| --- | --- |
| `dhikr` | Library entries. Built-ins are seeded with `INSERT OR IGNORE`, so user flags survive updates |
| `sessions` | One row per session. `ended_at IS NULL` marks the active session (at most one). Stores snapshots of the label and Arabic text so history survives library edits |
| `session_days` | `(session_id, day, count)`. Per-day attribution makes daily statistics exact across midnight. Cascades on session delete, so deleting history updates statistics |
| `goals` | Daily targets; `dhikr_id NULL` means all dhikr |
| `reminders` | Time plus a weekday bitmask; each weekday maps to its own notification id |

Statistics are computed with SQL aggregates (`SUM`, `GROUP BY day`), plus pure Dart for streaks.

## Read-model refresh

Two revision counters in `core/providers` drive refreshes:

- `countingRevisionProvider` is bumped (debounced, 450 ms) while counting.
- `structureRevisionProvider` is bumped when sessions are finished, discarded or deleted, or when
  the library changes.

Read models (`statsSummaryProvider`, `activitySeriesProvider`, `goalProgressProvider`, and others)
watch the revisions and re-query. Queries are small aggregates over indexed columns.

## Bead tasbih rendering

`BeadLoop` (domain, pure) models the string as a closed loop of equal slots: the imam bead, the
beads, and separators for multiples of three above 33. For a given total count it yields a
monotonic **cursor**. Each item's offset from the cursor is mapped to a distance along the string
by a piecewise function:

- Items not yet counted queue before the anchor.
- Counted items stack after a gap of bare string.
- The bead in transit glides across the gap.

`LoopGeometry` maps a distance to a point and tangent: a circle whose circumference is exactly
beads plus gap (Ring, so there is no seam), or a long sinusoidal strand whose seam is far off
screen (Strand). Because the same model drives both styles, round completion is the imam bead
naturally passing through the gap.

`BeadRenderer` draws each material procedurally in unit space (a sphere of radius 1):

- Shaders and texture paths are built once per material and reused through canvas transforms,
  so painting 102 beads allocates nothing per frame.
- Lighting is fixed (key light from the upper left) while grain and veins rotate with the string.
- Finishes: wood (grain), stone (banding or a matrix web), marble (veins), gem (translucent glow
  and clouds), and pearl (soft-light iridescence).

The cursor is an unbounded `AnimationController`. Rapid taps re-target the running animation, so
motion stays continuous. Undo animates backwards; resets and session switches roll forwards to
the nearest equivalent position.

## Testability

All platform dependencies sit behind interfaces and are provided through Riverpod:

- `HapticsService`, `SoundService` and `NotificationService`
- the clock (`clockProvider`)
- the database factory (`AppDatabase.open(factory:)`)

Tests substitute recording fakes, a controllable clock, and an in-memory FFI SQLite database with
the real schema. A gated screenshot test renders every screen with the bundled fonts for visual
review.

## Design system

- **Palette tokens** (`SakinaColors`): ivory `#FAF9F6`, emerald `#176B50`, forest `#103D32`,
  champagne `#C9AE76`, beige `#EDE5D8`, night `#101512`. The user-selected accent flows through
  the theme; in dark mode it is lightened to keep contrast.
- **Typography**: Manrope for the interface, Cormorant Garamond (lining figures) for headings and
  numerals, and Amiri for Arabic with generous line height for harakat. Arabic text has its own
  size setting, independent of interface scaling.
- **Restraint**: one hero card per screen at most. Sections are separated by whitespace and
  hairlines rather than stacked cards. Motion is short and eased, and gradients are reserved for
  physical materials.
