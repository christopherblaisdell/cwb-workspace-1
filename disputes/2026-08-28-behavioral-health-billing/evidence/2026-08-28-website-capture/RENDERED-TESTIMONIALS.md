# Rendered-DOM Capture — Testimonials (JavaScript-Loaded Content)

> 🔴 **EVIDENTIARY WARNING — added 2026-09-05. This is transcription, not capture.**
>
> Every other artifact in this folder is a preserved file with a SHA-256 hash in
> `SHA256SUMS.txt`. **This one is not.** There is no DOM dump, no PDF, no screenshot, no
> hash, and the method line below does not record the browser, its version, the script,
> the user-agent, the viewport, or the timestamp to the second — all of which the `curl`
> manifest *does* record.
>
> **The Bible-study testimonial below is arguably the most probative marketing evidence
> in the entire case, and it currently exists only as text someone typed into a Markdown
> file.** It is impeachable on that basis alone.
>
> **To fix it — this is the highest-value evidence task outstanding:**
> 1. Open the homepage in a browser, scroll to the bottom to trigger the testimonials.
> 2. ⌘P → Save as PDF. Screenshot the testimonial section separately.
> 3. Save both into this folder and regenerate `SHA256SUMS.txt`.
> 4. Record browser name, version, OS, and the exact capture timestamp.
> 5. Confirm the Wayback snapshots for `/`, `/treatments/individual-therapy/`, and
>    `/about/our-facility/` — **none of the four confirmed Wayback URLs contains the
>    testimonials, the CBT claim, or the catered-meals language.** The independent
>    corroboration currently covers only the pages that do not matter.
>
> ⚠️ **The "zero matches for 12-step content" finding below is the most fragile claim
> here.** No search command or output was preserved, and the five search terms are too
> narrow to support the conclusion — they omit *spirituality, the steps, sponsor,
> fellowship, AA, NA, God, higher power, surrender, recovery meeting.* Re-run it with a
> broad term set, save the command and its output to a file, and hash both. A negative
> finding is only ever as good as the search that produced it.

**Captured:** 2026-08-28
**Source:** `https://www.remedytherapybehavioralhealth.com/` (homepage)
**Method:** headless browser, full page scroll to trigger lazy-loading, then extraction of
`document.body.innerText`
**Why this file exists:** the testimonials are **not present in the page source**. A
`curl` capture, and very likely the Wayback Machine crawler, will miss them entirely.

> Before scrolling, rendered text was 4,688 characters and contained **no testimonials**.
> After a full scroll, rendered text was 9,737 characters and the testimonials appeared.
> This is why a static capture is insufficient for this site.

---

## ⭐ Testimonial — religious accommodation of a Christian patient

Attributed on the page to **"Michael P"**. Verbatim as rendered:

> "I LOVED THIS PLACE AND IT WILL FOREVER BE THE REASON I CAME BACK TO GOD! I was able to
> share how I felt and not be judged, **I was able to share about Jesus and not be judged
> most importantly, and I was able to have MY OWN BIBLE STUDY GROUP!!!!** There's a few
> people that I want to shout out and yes all the reviews have one person that stands out
> and this is **Josh D**! Josh was an important part of my journey at remedy and he made
> his mark not only in my recovery but **in my spiritual journey** to! He was an amazing
> mentor and teacher he really does care and LOVE everyone that comes through the front
> door. He is so incredibly supportive and kind it's unbelievable how much he reminds me
> of **what a Christian Should act like**. Next off we got Cindy! Oh Cindy was awesome...
> She has incredible energy and I will always remember **her meditations**."

**Significance:** the facility publishes, as marketing, a patient's account of having his
religious practice accommodated — including **his own Bible study group** — and praises a
staff member for Christian mentorship.

Set against the same facility refusing to provide any secular or CBT alternative, and a
facilitator turning his back during group prayer saying "SOME of us will be praying,"
this is **disparate treatment on the basis of religion, evidenced by the facility's own
website**.

Note also **"Josh D"** appears elsewhere as **Activities Director** — a non-clinical role
described here in mentorship/spiritual terms.

## Testimonial — food quality

Attributed to a patient describing recovery after an overdose:

> "The staff truly cared and gave me the tools and support I still use every day. And
> honestly, **the food was top notch too.**"

**Significance:** set against a refrigerator the facility logged at **67°F** daily,
rotting food, and spoiled milk. Supports the FDUTPA claim alongside the site's own
"delicious catered meals" and "wellness retreat" language.

## Marketing claims confirmed in rendered DOM

**Cognitive behavioral therapy** — from the Individual Therapy section:

> "When a patient comes to Remedy Therapy Behavioral Health, we **strive to tailor the
> treatment options to the individual's challenges**. We utilize a range of treatment
> options, **including cognitive-behavioral therapy**, to provide healing for our
> patients."

**Facility and food** — from the Our Facility section:

> "Unlike a typical hospital setting, our center feels more like a **wellness retreat**.
> You'll enjoy cozy beds, **delicious catered meals**, and a variety of amenities... Relax
> by our sparkling pool, unwind under the tiki hut..."

## ⭐ Negative finding — no disclosure of 12-step or religious programming

Searched both the static HTML of all 16 captured pages **and** the fully rendered
homepage DOM for:

`12-step` · `twelve-step` · `higher power` · `Alcoholics Anonymous` · `Narcotics
Anonymous`

**Zero matches.**

The facility's treatment pages describe detox, residential treatment, individual therapy,
group therapy, family therapy, trauma therapy, and medication-assisted treatment. **None
disclose that programming is twelve-step based or religious in content.**

Under FDUTPA a material omission is actionable in the same way as an affirmative
misrepresentation. A person selecting a treatment program — particularly while in crisis —
would plainly consider that material.

---

## ⚠️ Gap to close yourself

Because this content is JavaScript-rendered, **your Wayback Machine captures may not
include the testimonials.**

To capture them properly:

1. Open the homepage in your own browser.
2. **Scroll slowly all the way to the bottom** and wait for the testimonial carousel to
   appear.
3. Scroll back through it so every testimonial has rendered.
4. **⌘P → Save as PDF** — this prints the rendered DOM, including the testimonials.
5. Separately, **screenshot** the "Michael P" testimonial and the "food was top notch"
   testimonial.
6. Save to `evidence/2026-08-28-website-capture/`.

Then verify your Wayback snapshots: open each archived URL, scroll down, and confirm
whether the testimonials are present. If they aren't, your browser PDF is the only capture
of them — treat it accordingly.

## Evidentiary note

This is a self-collected capture, authentic but made by the complainant's own tooling. It
is corroborative, not independent. The strongest versions of this evidence are, in order:
the facility's own records produced in discovery, an independent third-party archive, and
then this. Preserve all three.
