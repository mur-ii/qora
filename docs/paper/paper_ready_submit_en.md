# Final Ready-to-Submit Manuscript (English)

## Title
Comparative Performance Analysis of GUI and VUI in a Flutter-Based Hotel Booking Application: A Pilot Study on Qora

## Authors
Author 1, Author 2, Author 3
Affiliation, City, Country
Email

## Abstract
This paper presents a pilot performance comparison between Graphical User Interface (GUI) and Voice User Interface (VUI) interaction in Qora, a Flutter-based hotel booking application equipped with an agentic real-time voice assistant. The objective is to evaluate practical trade-offs between manual touch interaction and conversational voice interaction under the same booking objective. The application stack uses Flutter, BLoC, and GoRouter, while the VUI pipeline integrates OpenAI Realtime API through HTTP session setup and WebRTC media/data channels. The evaluation focuses on average CPU usage, peak memory, network traffic, end-to-end latency, token usage, and session cost.

Pilot results from one GUI run and one VUI run indicate that VUI has substantially higher end-to-end latency (87,550 ms vs 3,126 ms), non-zero network overhead, and non-zero model cost (USD 0.0103512 per session with 14,753 tokens). In contrast, GUI shows zero model cost and near-zero network usage in the current mock-backed path. The pilot also shows lower average CPU and peak memory for VUI, suggesting that latency and cloud cost are currently the dominant VUI penalties rather than local resource saturation. This work contributes a code-aligned, reproducible evaluation framework and a concrete engineering roadmap to move from pilot benchmarking to publication-grade empirical evidence.

## Index Terms
Flutter, Voice User Interface, Graphical User Interface, Realtime AI, WebRTC, Mobile Performance, Human-Computer Interaction, Hotel Booking

## I. Introduction
Mobile human-computer interaction is evolving from purely touch-based interaction to conversational and multimodal interaction. In transactional domains such as hotel booking, GUI is commonly perceived as deterministic and controllable, whereas VUI offers hands-free interaction and automation potential.

However, VUI introduces additional complexity, including continuous audio streaming, remote model inference, turn-taking behavior, and token-based operating cost. Therefore, GUI versus VUI evaluation should be conducted on an implemented system rather than conceptual assumptions.

Qora is an appropriate case study because both modalities are implemented within the same codebase. The GUI flow is driven by screen navigation and local mock data, while the VUI flow relies on OpenAI Realtime API, WebRTC, and function calling.

Research questions:
1. How do GUI and VUI differ in CPU, memory, network, latency, and cost for equivalent booking objectives?
2. Which VUI pipeline components contribute most to the observed overhead?
3. What engineering improvements are required for publication-grade evidence?

## II. System Architecture and Instrumentation
### A. Application Architecture
Qora is implemented in Flutter with BLoC for state management and GoRouter for routing. The voice assistant module follows layered separation (data, domain, presentation). Agentic function execution is coordinated through use cases that map model tool calls to booking actions.

### B. GUI Pipeline
In the current implementation, GUI performance tracking starts at the payment page and ends at booking confirmation. The GUI flow is event-driven and strongly influenced by local mock-backed responses.

### C. VUI Pipeline
The VUI flow includes Realtime session creation over HTTP, SDP negotiation, microphone audio streaming over WebRTC, data channel event handling, and function-call execution for booking actions.

### D. Telemetry Coverage
The exported telemetry contains:
1. Average CPU.
2. Peak memory.
3. HTTP and WebRTC network traffic.
4. Scenario latency.
5. Token usage and session cost.

## III. Methodology
### A. Experimental Design
Independent variable:
- Interaction modality: GUI and VUI.

Dependent variables:
- Average CPU (%).
- Peak memory (MB).
- Network TX/RX (KB).
- End-to-end latency (ms).
- Tokens and session cost (USD).

Target control variables:
1. Same Android device.
2. Same app build mode (Flutter profile mode).
3. Same booking objective.
4. Stable network condition per batch.
5. Consistent dataset and model version.

### B. Data Source
This pilot uses two exported telemetry files:
1. GUI booking flow.
2. VUI booking flow.

### C. Equations
Relative overhead of metric M:

$$
Overhead(M) = \frac{M_{VUI} - M_{GUI}}{M_{GUI}} \times 100\%
$$

Latency ratio:

$$
Latency\ Ratio = \frac{Latency_{VUI}}{Latency_{GUI}}
$$

## IV. Results and Discussion
### A. Pilot Raw Results
| Metric | GUI | VUI |
|---|---:|---:|
| Latency (ms) | 3,126 | 87,550 |
| Average CPU (%) | 6.5878 | 4.9979 |
| Peak Memory (MB) | 392.0166 | 313.7334 |
| Network TX (KB) | 0.0000 | 778.3682 |
| Network RX (KB) | 0.0000 | 1,515.4902 |
| Session Cost (USD) | 0.0000000 | 0.0103512 |
| Total Tokens | 0 | 14,753 |
| Total Turns | 0 | 12 |

### B. Derived Comparison
1. VUI-to-GUI latency ratio: 28.01x.
2. VUI latency overhead versus GUI: 2700.70%.
3. VUI CPU difference versus GUI: -24.13%.
4. VUI peak memory difference versus GUI: -19.97%.

### C. Discussion
1. In the current implementation, the major VUI penalties are end-to-end latency and cloud cost.
2. Zero GUI tokens and network values indicate that the GUI path is currently dominated by local/mock processing, so complexity symmetry with cloud-assisted VUI is limited.
3. Lower pilot CPU and memory values for VUI should not be treated as conclusive superiority due to limited sample size and incomplete scenario parity.

## V. Threats to Validity
### A. Internal Validity
1. Sample size is currently n=1 per modality, preventing variance and significance analysis.
2. GUI and VUI flows are not yet fully symmetric in interaction complexity and step coverage.

### B. Construct Validity
1. GUI tracking currently starts from payment instead of the true booking entry point.
2. VUI sessions may terminate earlier by design in some flow states.

### C. Implementation Validity
1. The booking guest-info route currently resolves to the payment page, reducing step-level clarity.
2. One registered voice tool references an availability mock asset that is not yet present.

## VI. Improvement Plan Toward Publication-Grade Study
### A. Methodological Improvements
1. Execute at least 30 repetitions per modality and scenario type.
2. Report mean, median, standard deviation, p95, and 95% confidence intervals.
3. Add inferential tests and effect size.
4. Add task success and user correction metrics.

### B. Instrumentation Improvements
1. Move GUI start measurement to the true booking entry stage.
2. Add per-stage timestamps for both GUI and VUI.
3. Export unified batch data schema for statistical processing.
4. Separate HTTP signaling and WebRTC media/event traffic in reporting.

### C. Product and Codebase Improvements
1. Separate guest-info and payment routes for strict stage semantics.
2. Complete missing mock assets for all registered voice tools.
3. Standardize GUI and VUI scenario scripts for equivalent goals and stop criteria.
4. Add retry, timeout, and function-failure telemetry.

## VII. Recommended Final Experimental Protocol
1. Use one physical Android device for each test batch.
2. Keep app build mode fixed to Flutter profile mode.
3. Run three scenario classes: ideal flow, correction flow, and ambiguous-input flow.
4. Record all metrics per run and mark failures explicitly.
5. Aggregate with descriptive and inferential statistics.
6. Present results using paired tables and per-metric boxplots.

## VIII. Conclusion
Qora already provides a strong telemetry foundation for GUI versus VUI analysis. The pilot indicates significant VUI overhead in latency and cloud cost under the current setup, while CPU and memory differences remain inconclusive. With scenario parity, broader tracking coverage, and sufficient repetitions, the project is well-positioned to become a solid empirical paper on interaction modality performance in hotel booking applications.

## Acknowledgment (Optional)
This work was supported by the relevant institution/lab and implemented using the Qora prototype.

## References (complete according to target conference style)
[1] Flutter Documentation. https://docs.flutter.dev
[2] BLoC Library Documentation. https://bloclibrary.dev
[3] GoRouter Documentation. https://pub.dev/packages/go_router
[4] WebRTC for the Curious. https://webrtcforthecurious.com
[5] OpenAI Realtime API Documentation. https://platform.openai.com/docs
[6] IEEE Editorial Style Manual.

## IEEE Template Paste Notes
1. Paste Abstract and Index Terms into the exact template blocks.
2. Keep Roman numeral section headings.
3. Replace author and affiliation placeholders before submission.
4. Format references to strict IEEE conference style required by the ISITIA template.
