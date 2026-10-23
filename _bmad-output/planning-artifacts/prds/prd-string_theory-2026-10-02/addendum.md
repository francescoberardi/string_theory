# Addendum: String Theory PRD (v1.0 Firebase & Store Launch)

Downstream architectural notes, technical implementation details, and parked roadmap items preserved from discovery for the System Architect (Winston) and Developer (Amelia).

## 1. Technical & Architecture Notes (For Winston / System Architecture)

### 1.1 Firestore Document Hierarchy & Data Model
- **User Document**: `/users/{uid}`
  - User document schema:
    ```json
    {
      "email": "user@example.com",
      "displayName": "Marco Rossi",
      "createdAt": "FieldValue.serverTimestamp()",
      "fcmTokens": []
    }
    ```
- **Racquets Subcollection**: `/users/{uid}/racquets/{racquetId}`
  - Denormalized embedded active string job:
    ```json
    {
      "name": "Wilson Blade 98",
      "currentStringJob": {
        "brand": "Luxilon ALU Power 1.25",
        "material": "coPoly",
        "tensionLbs": 52.0,
        "strungAt": "2026-10-01T12:00:00Z",
        "hoursPlayed": 8.5,
        "maxHours": 20.0,
        "endedAt": null,
        "endReason": null
      },
      "pastStringJobs": [
        {
          "brand": "Head Lynx 1.25",
          "material": "coPoly",
          "tensionLbs": 50.0,
          "strungAt": "2026-08-01T10:00:00Z",
          "hoursPlayed": 19.2,
          "maxHours": 20.0,
          "endedAt": "2026-10-01T11:30:00Z",
          "endReason": "manual_restring"
        }
      ],
      "updatedAt": "FieldValue.serverTimestamp()"
    }
    ```
- **Sessions Subcollection**: `/users/{uid}/sessions/{sessionId}`
  - Dedicated subcollection to support query history and pagination. Schema supports optional fields for future v1.1 compatibility, though the v1.0 quick-logger UI strictly exposes duration chips and racquet picker to honor sub-10s logging (SM-C1):
    ```json
    {
      "racquetId": "{racquetId}",
      "durationHours": 1.5,
      "playedAt": "2026-10-23T16:00:00Z",
      "createdAt": "FieldValue.serverTimestamp()",
      "notes": "Good heavy balls",
      "surface": "hard",
      "location": "City Tennis Club"
    }
    ```

### 1.2 Atomic Session Logging via `WriteBatch`
- When saving a session, execute an atomic Firestore `WriteBatch`:
  1. `batch.set(sessionDocRef, sessionData)`
  2. `batch.update(racquetDocRef, {'currentStringJob.hoursPlayed': FieldValue.increment(durationHours), 'updatedAt': FieldValue.serverTimestamp()})`
- Guarantees data consistency offline and online without Cloud Functions.

### 1.3 Client-Side Decay Calculation Math
- Pure Dart composite calculation in `string_theory_decay_engine`:
  $$\text{DynamicPenalty} = \left(\frac{\text{hoursPlayed}}{\text{maxRatedHours}}\right) \times 70$$
  $$\text{CalendarPenalty} = \left(\frac{\text{daysElapsed}}{\text{maxCalendarShelfLife}}\right) \times 30$$
  $$\text{HealthScore} = \max\left(0, \operatorname{round}\left(100 - \left(\text{DynamicPenalty} + \text{CalendarPenalty}\right)\right)\right)$$
- Evaluated on client read directly from document snapshots.

### 1.4 Security Rules & App Check Blueprint
- Enforce strict ownership: `request.auth.uid == userId`.
- Validate schema payload bounds:
  - Racquet payload $\le 15$ keys; SessionLog $\le 12$ keys.
  - Tension between 20 and 80 lbs.
  - Duration between 0.1 and 24 hours.
- App Check providers: **Play Integrity** (Android) and **reCAPTCHA Enterprise** (Web).

### 1.5 Account Deletion & GDPR
- Trigger `FirebaseAuth.instance.currentUser?.delete()`.
- Official Firebase Extension `delete-user-data` configured to recursively delete `/users/{UID}` and all subcollections.

---

## 2. Parked Roadmap Items

### 2.1 v1.1 (Fast-Follow Store Monetization)
- **AdMob Integration**: Banner ads on Virtual Bag and interstitial after session logging.
- **Paid Pro Subscription (In-App Purchases)**: Unlimited racquets, ad removal, and Pro badge.
- **Remote Config Control**: Toggle `show_ads`, `pro_paywall_trigger`, and `free_racquet_limit` dynamically.
- **Enriched Session Metadata UI**: Form fields for court surface, location, and match notes.

### 2.2 v1.2+ (Pro Longevity & Engagement)
- **String Lab Pro Insights**: Aggregated equipment longevity analytics (average hours before dead/broken per brand/gauge from historical `pastStringJobs`).
- **FCM Push Notifications**: Server-driven background decay alerts when crossing into Red thresholds.
- **Web Funnel "String Health Calculator"**: Interactive unauthenticated widget on Flutter Web converting visitors via "Save my gear with Google".
- **Non-Racquet Gear**: Tennis shoes tread depth tracking and pressurized ball can freshness.
