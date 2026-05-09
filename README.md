# Apex Coach

A premium, local-first SwiftUI workout coach prototype. The app uses local rule-based generation today and keeps the generator behind `WorkoutPlanGenerating` so a remote AI service can replace it later without changing the rest of the app.

## Architecture

- `ApexCoach/App`: app entry point, root routing, and app-level MVVM state.
- `ApexCoach/Core/Models`: user profile, workout plan, exercise, history, PR, and settings models.
- `ApexCoach/Core/Persistence`: local JSON snapshot storage in Application Support.
- `ApexCoach/Core/Services`: plan generation, progressive overload, haptics, and timestamp-based timer recovery.
- `ApexCoach/Core/SampleData`: local exercise database used by the generator.
- `ApexCoach/Features`: onboarding, home, plan, exercise detail, active workout/rest, progress, and profile.
- `ApexCoach/Shared`: reusable UI components and front/back muscle diagrams.
- `ApexCoach/DesignSystem`: dark premium visual system and platform helpers.

## Local-First Behavior

The generator runs only from onboarding or explicit profile actions:

- Refresh Workouts
- Change Workout Plan
- Generate New Program

Daily workout flow, timers, history, PRs, progression, and future week generation run locally from persisted JSON.

## Verification

This environment has Command Line Tools selected instead of full Xcode, so `xcodebuild` cannot run here. The project file was linted with `plutil`, and the Swift sources were typechecked using the installed Swift compiler with a writable module cache.
