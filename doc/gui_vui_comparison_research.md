# GUI vs VUI Hotel Booking Comparison - Research Checklist

This document lists what to add for a comprehensive GUI vs VUI comparison study, and what to include in your paper (metrics, tables, and graphs).

## 1) What to add to the app and study design

### A. Behavioral and performance metrics (beyond current tracking)
- Task success rate per task step (search, select, payment, confirmation).
- Task completion time per step (not only total time).
- Time to first successful action (first search submit, first hotel selection).
- Number of backtracks/undo actions (e.g., returning to search results).
- Retry count (repeat voice commands or repeated taps for the same step).
- Input correction count (edits in search field or re-speaking commands).
- Session interruption count (app backgrounded, phone call, or cancel).
- Error type taxonomy (network error, misunderstanding, invalid input, UI error).
- Navigation depth and path length (number of screens visited).
- Cognitive load proxy (optional): NASA-TLX short form after task.

### B. Voice-specific metrics (VUI)
- ASR confidence (if available from VUI SDK).
- Number of reprompts/clarifications needed.
- Command ambiguity count (multiple matches, fallback prompts).
- Wake word/activation failures.
- Time between voice turns (latency).

### C. GUI-specific metrics
- Touch accuracy (mis-taps and immediate corrections).
- Scroll depth before selection.
- Tap density or total taps per step.

### D. Qualitative and subjective measures
- SUS (System Usability Scale) per method.
- UMUX-Lite (short usability measure).
- User satisfaction per task step (Likert 1-7).
- Trust and reliability rating for VUI.
- Preference ranking (GUI vs VUI).
- Open-ended feedback (pain points and suggestions).

### E. Experimental control and data quality
- Counterbalanced order (GUI first vs VUI first).
- Fixed task scripts and success criteria.
- Participant profile (age, tech literacy, voice assistant familiarity).
- Device and environment conditions (noise level, internet speed).
- Logging for dropped sessions and incomplete tasks.

## 2) What to include in the paper

### A. Study design
- Research questions and hypotheses.
- Participant demographics and recruitment criteria.
- Task scenarios and success criteria.
- Experimental conditions (GUI vs VUI) and order randomization.
- Environment and device setup.

### B. Metrics and definitions
- Exact definitions for each metric (units, formula, data source).
- Error taxonomy definitions.
- Task step definitions and boundaries.

### C. Data collection and processing
- Logging architecture (local storage format, timestamps, IDs).
- Anonymization and privacy handling.
- Data cleaning rules (outlier handling, missing data).

### D. Statistical analysis
- Normality checks, tests used (t-test, Mann-Whitney, Wilcoxon).
- Effect size (Cohen d, r) and confidence intervals.
- Multiple comparisons control (Bonferroni or FDR).

### E. Results and interpretation
- Summary of major findings per metric and per task step.
- Trade-offs (speed vs errors, accuracy vs satisfaction).
- Limitations and threats to validity.

## 3) Recommended matrices, tables, and graphs

### A. Matrices
- Metric-by-method matrix: each metric in rows, GUI/VUI in columns.
- Task-by-step matrix: steps in rows, metrics in columns.
- Error-type matrix: error type in rows, GUI/VUI counts and rates.

### B. Tables
- Participant demographics table.
- Task definition and success criteria table.
- Descriptive statistics table (mean, median, SD, CI).
- Statistical test results table (test used, p-value, effect size).
- Questionnaire scores table (SUS/UMUX-Lite per method).

### C. Graphs
- Bar chart: success rate and completion rate per method.
- Box plot: total completion time (GUI vs VUI).
- Stacked bar: error type distribution by method.
- Line chart: step-wise completion time (search -> payment).
- Scatter plot: errors vs duration (per session).
- Radar chart: multi-metric comparison (optional, use sparingly).

## 4) Minimum dataset fields checklist

- sessionId
- startTime, endTime, durationInSeconds
- method (GUI/VUI)
- per-step timing: search, select, payment, confirmation
- total clicks, total voice commands
- errorsCount + error type
- taskCompleted, bookingSuccess
- searchedLocation, selectedHotelName
- user feedback (SUS/UMUX-Lite, satisfaction)
- device/environment metadata

## 5) Practical next steps

- Add step-level timing and error taxonomy to the local log model.
- Add short post-task survey screen for SUS/UMUX-Lite.
- Add VUI event hooks for latency and reprompt counts.
- Create a CSV export format aligned with the tables above.
