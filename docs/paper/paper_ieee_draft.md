# Comparative Performance of GUI and VUI in a Flutter-Based Hotel Booking Application: A Pilot Study on Qora

## Title (for IEEE template)
Comparative Performance of GUI and VUI in a Flutter-Based Hotel Booking Application: A Pilot Study on Qora

## Authors (replace in template)
Author 1, Author 2, Author 3
Affiliation, City, Country
Email

## Abstract
This paper presents a pilot comparative analysis of Graphical User Interface (GUI) and Voice User Interface (VUI) interaction in Qora, a Flutter-based hotel booking application with an agentic real-time voice assistant. The objective is to evaluate practical performance trade-offs between manual touch interaction and conversational booking flow. The implemented system uses Flutter with BLoC and GoRouter for presentation and navigation, while the VUI pipeline integrates OpenAI Realtime API via HTTP session creation and WebRTC media/data channels. We analyze CPU usage, peak memory, network traffic, end-to-end latency, and token-based session cost from exported runtime telemetry.

Pilot results from one GUI run and one VUI run show that VUI has substantially higher end-to-end latency (87,550 ms vs 3,126 ms) and non-zero network and API cost overhead (USD 0.0103512 per session, 14,753 tokens), while GUI shows zero model cost and near-zero network usage in the current mock-backed setup. Interestingly, average CPU and peak memory in this pilot are lower for VUI than GUI, indicating that latency and cost are the primary VUI penalties in the current implementation rather than local resource saturation. We also identify instrumentation and flow-validity limitations, including asymmetric scenario complexity and route/tool consistency gaps.

The contribution of this study is a reproducible, code-aligned evaluation framework for GUI versus VUI booking interaction in a real mobile codebase, and a concrete improvement roadmap to elevate the project from pilot benchmarking to publication-grade empirical evidence.

## Index Terms
Flutter, Voice User Interface, Graphical User Interface, Realtime AI, WebRTC, Mobile Performance, Human-Computer Interaction, Hotel Booking

## I. Introduction
Human-computer interaction in mobile applications is shifting from purely touch-based interaction toward conversational and multimodal interaction. In transactional applications such as hotel booking, GUI is traditionally considered reliable and deterministic, while VUI promises hands-free interaction and lower manual effort. However, VUI introduces a real-time speech pipeline, remote model inference, turn-taking uncertainty, and variable token cost.

Qora is a suitable case study because it implements both interaction paradigms in one codebase. The GUI booking flow is implemented through screen-based navigation and local mock data, while the VUI flow uses OpenAI Realtime API with WebRTC and function calling for agentic actions.

This work addresses the following research questions:
RQ1: How do GUI and VUI differ in CPU, memory, network, latency, and cost for the same booking objective?
RQ2: Which components of the VUI pipeline contribute most to performance overhead?
RQ3: What engineering improvements are needed so that Qora can support publication-grade experimental claims?

## II. Related Context and System Overview
### A. Application Architecture
Qora is built with Flutter and applies BLoC for state management and GoRouter for navigation. The voice assistant is integrated as a dedicated feature module with data, domain, and presentation layers. Function calling is orchestrated by an agentic use-case facade that maps model tool calls to booking actions.

### B. GUI Booking Flow
The GUI flow is event-driven and currently starts performance tracking at the payment page and stops at booking confirmation. The flow is mostly deterministic because hotel and booking responses are mock-backed in the current implementation.

### C. VUI Booking Flow
The VUI flow starts by creating a Realtime session (HTTP), negotiating WebRTC SDP, streaming microphone audio, receiving model events via data channel, and executing function calls such as hotel search, room selection, and booking creation. Session cost is estimated from per-turn token logs.

## III. Methodology
### A. Experimental Design
Independent variable:
- Interaction modality: GUI vs VUI

Dependent variables:
- Average CPU utilization (%)
- Peak memory usage (MB)
- Network transmit and receive (KB)
- End-to-end scenario latency (ms)
- Session token count and estimated cost (USD)

Controlled factors (target design for full experiment):
- Same Android device model and OS
- Same app build type (Flutter profile mode)
- Same booking task objective and constraints
- Stable network condition per batch
- Same dataset and model version per run

### B. Data Source
This pilot uses exported scenario JSON from the built-in performance summary feature:
1. VUI scenario: booking flow with realtime conversation and function calling
2. GUI scenario: booking flow without voice interaction

### C. Formulas
Relative overhead of metric M:

$$
Overhead(M) = \frac{M_{VUI} - M_{GUI}}{M_{GUI}} \times 100\%
$$

Latency ratio:

$$
Latency\ Ratio = \frac{Latency_{VUI}}{Latency_{GUI}}
$$

Token-based cost per session is accumulated from per-turn token usage and pricing coefficients configured in the system logging pipeline.

## IV. Pilot Results
### A. Raw Metrics
| Metric | GUI | VUI |
|---|---:|---:|
| Latency (ms) | 3,126 | 87,550 |
| Avg CPU (%) | 6.5878 | 4.9979 |
| Peak Memory (MB) | 392.0166 | 313.7334 |
| Network TX (KB) | 0.0000 | 778.3682 |
| Network RX (KB) | 0.0000 | 1,515.4902 |
| Session Cost (USD) | 0.0000000 | 0.0103512 |
| Total Tokens | 0 | 14,753 |
| Turns | 0 | 12 |

### B. Derived Comparison
- Latency ratio (VUI/GUI): 28.01x
- Latency overhead versus GUI: 2700.70%
- CPU difference versus GUI: -24.13% (pilot VUI lower)
- Peak memory difference versus GUI: -19.97% (pilot VUI lower)

### C. Interpretation
1. VUI introduces strong latency and operational cost overhead in the current implementation.
2. Zero GUI network and token values indicate that current GUI execution path is mostly local/mock and not directly comparable to cloud-assisted VUI complexity.
3. Lower CPU/memory for VUI in this pilot should not be interpreted as definitive superiority, because scenario scope and session dynamics are not yet symmetric.

## V. Threats to Validity
### A. Internal Validity
- Sample size is currently n=1 per modality, so variance and statistical significance cannot be established.
- Scenario symmetry is limited: VUI run includes conversational turns and remote inference, while GUI run is short and model-free.

### B. Construct Validity
- GUI tracking starts at payment page, which may exclude earlier navigation/search overhead.
- VUI flow can terminate at booking summary by design, affecting direct parity with full end-to-end payment completion.

### C. Implementation Validity
- Route mapping for booking guest info currently resolves to payment page, which can blur per-step analysis.
- A function tool references room mock data that is currently absent, creating potential runtime failure paths when tool coverage is expanded.

## VI. Improvement Roadmap for Publication-Grade Study
### A. Experiment Quality Improvements
1. Run at least 30 repetitions per modality and scenario type.
2. Report mean, median, standard deviation, p95, and 95% confidence interval.
3. Add inferential statistics (e.g., Mann-Whitney U for non-normal data) and effect size.
4. Add task success rate and correction count to complement system metrics.

### B. Instrumentation Improvements
1. Expand GUI measurement start point from payment-only to the true booking entry point.
2. Add stage-level timestamps (search, detail, summary, payment) for both modalities.
3. Export unified CSV/JSON schema for batch analysis scripts.
4. Separate network metrics into HTTP signaling vs WebRTC media/event traffic in final analysis tables.

### C. Product/Codebase Improvements
1. Fix route semantics so guest-info and payment are mapped to distinct pages.
2. Complete missing mock assets for all registered voice tools, especially availability checking.
3. Standardize scenario scripts so GUI and VUI solve equivalent constraints and completion criteria.
4. Add fail-safe and retry policy metrics (timeout count, reconnection attempts, failed function calls).

## VII. Recommended Final Experimental Protocol
1. Prepare one physical Android device and lock network profile for each batch.
2. Build once in Flutter profile mode and clear app cache before each batch.
3. Execute three scenario categories per modality: ideal flow, correction flow, and ambiguous-input flow.
4. For each run, record latency, CPU, memory, network, tokens, cost, success/failure.
5. Aggregate all runs and compute descriptive + inferential statistics.
6. Present results using paired tables and boxplots per metric.

## VIII. Conclusion
This pilot confirms that Qora can already produce meaningful telemetry for GUI-VUI comparison, but current evidence is not yet sufficient for strong statistical claims. The main observed VUI penalty is latency and cloud-cost overhead, while local CPU and memory differences remain inconclusive under current sample size and scenario asymmetry. With instrumentation refinement, scenario parity, and repeated trials, Qora is technically suitable to become a strong empirical paper on GUI versus VUI performance in mobile hotel booking.

## Acknowledgment (optional)
This work was supported by [Institution/Lab Name], and conducted using the Qora prototype repository.

## Notes for Copy-Paste into IEEE Template
1. Keep section titles in IEEE format (Roman numerals).
2. Put Abstract and Index Terms exactly in template-provided blocks.
3. Replace author/affiliation placeholders before submission.
4. If required by conference policy, convert this markdown text into plain template text without markdown symbols.

## Evidence Links in Current Codebase
- Performance tracking service: [lib/core/services/performance_tracking_service.dart](lib/core/services/performance_tracking_service.dart)
- Runtime metrics channel: [lib/core/services/performance_runtime_metrics_service.dart](lib/core/services/performance_runtime_metrics_service.dart)
- GUI scenario start (payment page): [lib/features/booking/presentation/pages/payment_page.dart](lib/features/booking/presentation/pages/payment_page.dart)
- GUI scenario finish (confirmation page): [lib/features/booking/presentation/pages/booking_confirmation_page.dart](lib/features/booking/presentation/pages/booking_confirmation_page.dart)
- VUI scenario start/finish handling: [lib/features/voice_assistant/presentation/bloc/voice_assistant_bloc.dart](lib/features/voice_assistant/presentation/bloc/voice_assistant_bloc.dart)
- VUI function definitions: [lib/features/voice_assistant/domain/usecases/agentic_function_definitions_usecase.dart](lib/features/voice_assistant/domain/usecases/agentic_function_definitions_usecase.dart)
- Agentic action use cases including availability tool: [lib/features/voice_assistant/domain/usecases/agentic_action_usecases.dart](lib/features/voice_assistant/domain/usecases/agentic_action_usecases.dart)
- Route mapping (guest info and payment): [lib/core/router/app_router.dart](lib/core/router/app_router.dart)
