# Curriculum acceptance contract

The user requirement is strict alignment to the **inovovaný ŠVP for lower secondary education**, administered by NIVAM, for Slovenský jazyk a literatúra, Anglický jazyk, Matematika, Fyzika, Chémia, Biológia, Geografia, Dejepis and Informatika.

Authoritative starting points: https://nivam.sk/ and https://www.statpedu.sk/ (archived iŠVP subject educational standards). No official documents have been fetched or verified in this task. Do not invent exact standard identifiers or label seeded examples as approved. Distinguish iŠVP from the newer reform curriculum; confirm the school's cohort and school educational programme (ŠkVP). A standard's allocation to an individual grade may be specified by the school's ŠkVP rather than universally fixed by iŠVP.

All 18 seeded topic candidates (one per subject per grade) carry `curriculum_status=draft`. Only three have playable lesson questions. Topic titles indicate planning candidates, not certified grade placement. No empty lessons are presented as playable.

Before release, a qualified subject teacher must:

1. Record the official document edition, subject, applicable cohort, content standard and performance standard for each topic/question, with exact page/section and source URL.
2. Confirm grade 8/9 placement against the target school's ŠkVP; adjust the proposed seed in a separate content revision.
3. Review Slovak wording, numerical units, answer tolerances, ambiguous alternatives, explanations and accessibility.
4. Populate `curriculum_source` and `curriculum_standard`, record reviewer/date in editorial records, and change `curriculum_status` to `reviewed` only after approval.
5. Add a production content publication gate so only reviewed topics are available. The current development RLS deliberately permits authenticated review of drafts; it is not a launch gate.

The math example is a 3–4–5 right triangle (metres); the detective text intentionally contains “kamarátiy” → “kamaráti” and “Bolily” → “Boli”. The map target is Bojnice, using an illustrative projected viewport. These examples validate mechanics, not subject-wide learning outcomes.
