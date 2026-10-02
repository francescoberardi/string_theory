# Addendum: String Theory PRD

Downstream architectural notes, technical implementation details, and parked roadmap items preserved from discovery.

## 1. Technical & Architecture Notes (For Winston / System Architecture)
- **Extensible Gear Hierarchy:** Polymorphic `GearItem` table structure in Serverpod ORM. In v1: `Racquet` with active `StringBed`. Future: `Shoe` and `BallCan`.
- **Composite Decay Math:**
  - `HealthScore = 100 - (DynamicHourPenalty + CalendarAgePenalty)`
  - Dynamic penalty: `(hours_played / max_rated_hours) * 70`
  - Calendar penalty: `(days_elapsed / max_calendar_shelf_life) * 30` (calibrated by string material: Co-Poly shelf life ~75 days, Multifilament ~180 days, Natural Gut ~365 days).
- **Serverpod Integration Touchpoints:**
  - Real-time streaming (`StreamController`) updating client health gauges instantly on session log.
  - Serverpod `FutureCalls` running daily at midnight UTC to increment calendar decay and push alerts.
  - Built-in Authentication: support anonymous guest sessions with account linking to Google/Email.
- **Apple Health / Health Connect Integration:**
  - Query completed `HKWorkoutActivityTypeTennis` sessions.
  - Include an interactive "Simulate Workout" generator for demo and hackathon judging on desktop/web/simulators.

## 2. Parked Roadmap Items
- Footwear tread depth tracking and midsole foam degradation.
- Can pressure expiration tracking.
- Audio acoustic frequency vibration pluck analyzer.
