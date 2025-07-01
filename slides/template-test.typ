// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}

#import "@preview/touying-quarto-clean:0.1.1": *

#let _small-cite(self: none, it) = text(
  size: 0.7em,
  fill: self.colors.neutral-darkest.lighten(30%),
  it
)

#let small-cite(it) = touying-fn-wrapper(_small-cite.with(it))
#set text(weight: "light", )
#show heading: set text(font: ("Roboto",), )

#show: clean-theme.with(
  aspect-ratio: "16-9",
    // Typography ---------------------------------------------------------------
        font-family-heading: ("Roboto",),
        font-family-body: ("Roboto",),
        font-weight-heading: "light",
      // Colors --------------------------------------------------------------------
        // Title slide ---------------------------------------------------------------
      )

#title-slide(
  title: [The impact of climate-realted disasters on aid delivery],
  subtitle: [CERDI Phd Seminar],
  authors: (
                    ( name: [Paul Vernus],
            affiliation: [],
            email: [],
            orcid: []),
            ),
  date: [2025-07-03],
)

= Introduction
<introduction>
== Motivation
<motivation>
-

=== Climate-related disastrous extreme events
<climate-related-disastrous-extreme-events>
- Already high costs of climate-related disasters, especially in LMICs

- Gap between what gov. in affected countries expect and what they actually receive, both in terms of volume and type of aid

=== The Political economy of disaster responses
<the-political-economy-of-disaster-responses>
- Disasters act as exogenous shocks to the strategic interactions between donors and recipients

- Provide the donor a window of opportunity to pursue its own strategic interests @cheng2021@arezki2025

- Produce incentives for recipient leaders seeking international/domestic reputation @grossman2024

=== Domestic politics and Aid policy
<domestic-politics-and-aid-policy>
- Besides aid volume, aid #emph[delivery] is also used as a tool for foreign influence

- Theoretical framework: need-governance trade off @bourguignon2020[#small-cite()[; #cite(<bourguignon2022>, form: "prose");]]

  - external discipline: donor ➝ leader

    - e.g.~implicit conditionality in the mode/channel of delivery @raschky2012[#small-cite()[; #cite(<dietrich2013>, form: "prose");; #cite(<knack2014>, form: "prose");]]

  - internal discipline: population ➝ leader

    - e.g.~political system @flores2013@cole2012

- How do exogenous shocks impact donor--government relations at the recipient-country level?

#strong[Aid policy (compromise)] = outcome of the negotiations between donor agencies and recipient governments @mosley2012[#small-cite()[; #cite(<swedlund2017>, form: "prose");]] on the aid volume #emph[and] delivery/composition

== Research question
<research-question>
#strong[How do exogenous shocks such as climate-related disasters impact donor--government relations through aid policy at the recipient-country level? Does post-disaster aid delivery react to domestic politics?]

== This Paper
<this-paper>
=== What I do
<what-i-do>
- Look at the effect of exogenous shocks on the delegation of authority/control over aid flows

- Combine development and humanitarian ODA from bilateral and multilateral providers in a dyadic panel setting

- Use gridded data to build a global measure of exposure to disastrous weather and climate extreme events, aggregated at the country-year level

- Adopt a non-parametric multiple event study to characterize the dynamic treatment effects (DTE) of recurring "on-off" events

=== What I find
<what-i-find>
…

= Related literature
<related-literature>
== Related literature
<related-literature-1>
=== Political economy post-disaster foreign aid disbursements
<political-economy-post-disaster-foreign-aid-disbursements>
- Focus on how (international) political economy factors impact government responsiveness

Yang, 2008; David, 2011;

=== Climate econometrics
<climate-econometrics>
- Use more granular data (°0.5) and follow up-to-date methodology to Global multi-hazard measure with more granular data @dellmuth2021[{.small-cite}]

=== Multiple event study approach
<multiple-event-study-approach>
- To my knowledge, first application to a dyadic panel setting

= Conceptual framework
<conceptual-framework>
== Conceptual framework
<conceptual-framework-1>
- Cross-table design/implementation

- OR tree/DAG

= Data and descriptive statistics
<data-and-descriptive-statistics>
== Data
<data>
=== Outcome
<outcome>
- source: OECD CRS project-level

- window: report channels since 2004

=== Treatment
<treatment>
- source: EMDAT/GDIS

- Event window: (i) Under-reporting before 2000, (ii) no geocoded data after 2018

- Aggregate all the types of disasters at a yearly frequency to build a country-level indicator, Disaster, that takes the value of 1 if country i experienced at least one disaster in year t, and 0 otherwise.

== Descriptive statistics
<descriptive-statistics>
=== Outcome: official Development Assistance (ODA)
<outcome-official-development-assistance-oda>
- non-negative, skewed, mass at zero -\> non-linear

- extensive margin

=== Treatment: Disasters
<treatment-disasters>
- Treatment status graph

=== Treatment: Disasters
<treatment-disasters-1>
- Multiple 'on-off' (non-absorbing) treatments

  - Potential carryover effects ($D_(t - n) arrow.r.double Y_t$)

- Many potential 'always-treated' units

- Relatively few 'never-treated'

- Treatment heterogeneity, e.g., sudden-onset vs.~slow-onset events

- Non-binary treatment, cf.~hazard intensity/severity

=== Treatment: Disaster intensity
<treatment-disaster-intensity>
- Follow approach suggested by @dellmuth2021[{.small-cite}]

  - Link grid-level climate data to geocoded disaster locations at ADM1-level

    - Baseline distribution of gridded daily weather variables (1980-today)

    - Extreme event = daily weather value \> 95th percentile baseline distribution

    - Intensity = frequency of daily extreme events per year

    - Average grid-level yearly intensity measures at ADM1-level disaster location

- Finally, aggregate disaster locations at the country-year level with a (population-)weighted sum

  - Alternative weighting scheme: grid-level

  - Alternative exposure variable: population density, agricultural land and/or built-up area

- n.b.~Similar approach than in other single-hazard studies in climate economics (e.g., 'degree-days')

= Empirical stragegy
<empirical-stragegy>
== Empirical strategy
<empirical-strategy>
I follow a similar approach as @bettin2025[{.small-cite}]

- Exploit the exogenous nature of disasters

- Non-parametric event study specification @dobkin2018[{.small-cite}]

  - flexibly assess the pattern of outcomes relative to the time-to-treatment

- Multiple Dummies On (MDO) approach @sandler2014a[{.small-cite}]

  - Multiple event-time dummies are taken on at once

  - in a given period can respond to multiple disasters with overlapping effect windows

- Binned endpoints to defined the #emph[effect window] @schmidheiny2023[{.small-cite}]

  - Assume that treatment effects remain constant outside the chosen t-year window

  - control for both past and future treatments

Main differences

- Dyadic outcome variables observed each year (donor-recipient-year units)

- Non-linear setting (Binomial "Logit", PPML)

- #strong[effect window] as an open interval with

  - Assume that the effect of disasters does not vanish but remains constant outside the chosen t-year window

  - control for both past and future disasters

=== Example: Effect window matrix
<example-effect-window-matrix>
#emph[Table]

=== Alternative approach
<alternative-approach>
- DID "binarize and staggerize" @dechaisemartin2024[#small-cite()[; #cite(<deryugina2017a>, form: "prose");]]

  - staggered DiD procedure according to first-time of treatment exposure

  - Advantage: no 'carryover' assumption

  - Inconvenient:

    - loss of information (single binary 'first-time' treatment)

    - rely on 'never-treated' groups as controls

=== Empirical specification: static
<empirical-specification-static>
- Dyadic setting with country-specific treatment

- Follow @faye2012[#small-cite()[; #cite(<arezki2025>, form: "prose");]]

$ O D A_(d r t) = delta D I S_(r t) + X'_(d r t) beta + alpha_(d r) + epsilon.alt_(d r t) $ $O D A_(d r t)$: commitment ODA from donor #emph[d] to recipient #emph[r] at year #emph[t]

$D I S_(r t)$: dummy that takes 1 if country r has any climate-related disasters in year t or the value of the hazard intensity index

$X'_(d r t)$: a vector of (i) time-varying donor or recipient specific control variables, such as GDP and population, or (ii) year or donor-year fixed effects

$alpha_(d r)$: a vector of donor-recipient country pair fixed effects

=== Empirical specification: Event study
<empirical-specification-event-study>
Timeline

Bar graph: freq obs. (y-axis), year (y-axis)

- Effect window from $underline(m) = - 5$ to $overline(m) = 5$.

- Treatment window: 2001:2018

- Outcome window: 2004:2023

- Limit to external validity

- Relevant period

  - 2008-09: financial crisis (supply constraints)

  - 2009-2010: ENSO (increasing demand)

$ Y_(d r t) = sum_(m = underline(m))^(overline(m)) beta_m bb(B)_(r t)^m + sum_(z in Z) beta_z X_(Z_(d r t)) + alpha_(d r) + tau_t + epsilon.alt_(d r t) $

where $bb(B)_(r t)^m$ is the disaster indicator binned at the endpoints, such that:

\$\$ ^{m}\_{rt}=

\$\$

= Results
<results>
== Results
<results-1>
== Robustness checks
<robustness-checks>
== Heterogeneity
<heterogeneity>
- nature of the disaster:

  - sudden-onset / slow-onset disasters

  - hydrological, meteorological, climatological

- International political alignment

- Domestic political (alignment)

= Conclusion
<conclusion>
== Conclusion
<conclusion-1>
#show: appendix
= Appendix
<appendix>
== References
<references>
#block[
] <refs>


 

#set bibliography(style: "chicago-author-date")


#bibliography("references.bib")

