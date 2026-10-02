# Addendum: String Theory

This document captures architectural constraints, downstream implementation details, and parked roadmap items surfaced during product brief discovery.

## 1. Technical & Architecture Notes (Downstream for Architecture/PRD)

### 1.1 Extensible Gear Domain Model
* While the Hackathon MVP focuses strictly on **Racquets & Strings**, the backend schema (Serverpod models) must be architected with an extensible `GearItem` pattern or equipment type hierarchy:
  * `Racquet` with attached `StringBed` (MVP).
  * Future types: `Shoe` (tread wear based on court surface + hours), `BallCan` (pressure decay based on open date + sessions), `Overgrip` (hours played / sweat degradation).

### 1.2 Health Score Engine
* **Composite Decay Function:**
  * Evaluates two axes:
    1. **Dynamic Court Hours:** Accumulated playtime relative to string type baseline (or manufacturer declared max hours, e.g., 15–20h for co-poly, 30–40h for synthetic gut).
    2. **Static Calendar Aging:** Time elapsed since restringing date (co-poly strings degrade in elasticity over 60–90 days even without heavy play).
  * Produces a normalized Health Score: `100% -> 0%`.
  * Visual thresholds: Green (Healthy, >70%), Amber (Degrading / Caution, 40–70%), Red (Dead / Injury Risk, <40%).

### 1.3 HealthKit / Health Connect Integration & Demo Fallback
* Integration with Apple HealthKit / Android Health Connect to read completed "Tennis" workout sessions.
* **Auto-suggestion UX:** Prompt the user with a low-friction modal: *"Detected 90m tennis session at 10:00 AM. Assign to Racquet [X]?"*
* **Hackathon Demo Mode / Seed Generator:** A simulated workout generator or one-click demo button in the Flutter app so hackathon judges testing on simulator/emulator or desktop web can trigger detected sessions without an actual smartwatch.

## 2. Parked Roadmap (v1.1+)
* **Footwear Outsole Tracking:** Alert when shoe cushioning and herringbone tread reach high rollover/sprain risk.
* **Tennis Ball Freshness:** Track cans opened to avoid playing with dead balls.
* **String Frequency Acoustic Analyzer:** Microphone pluck analysis (measuring vibration frequency in Hz to estimate string tension drop).
