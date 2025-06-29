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
#import "@preview/fontawesome:0.5.0": *
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
  title: [Quarto Clean Theme],
  subtitle: [A Minimalistic Theme for Quarto + Typst + Touying],
  authors: (
                    ( name: [Kazuharu Yanagimoto],
            affiliation: [CEMFI],
            email: [kazuharu.yanagimoto\@cemfi.edu.es],
            orcid: [0009-0007-1967-8304]),
            ),
  date: [June 29, 2025],
)

= Section Slide as Header Level 1
<section-slide-as-header-level-1>
== Slide Title as Header Level 2
<slide-title-as-header-level-2>
=== Subtitle as Header Level 3
<subtitle-as-header-level-3>
You can put any content here, including text, images, tables, code blocks, etc.

- first unorder list item
  - A sub item

+ first ordered list item
  + A sub item

Next, we'll brief review some theme-specific components.

- Note that #emph[all] of the standard Quarto + Typst #link("https://quarto.org/docs/output-formats/typst.html")[features] can be used with this theme
- Also, all the #link("https://touying-typ.github.io")[Touying] features can be used by #strong[Typst native code]

== Before You Go…
<before-you-go>
The #link("https://github.com/kazuyanagimoto/quarto-clean-typst")[clean theme] does not depend on any languages. You can use it with any language supported by Quarto, including R, Python, Julia.

For this demo, I use R code to show the figures and tables usage in the slides.

#v(0.5em)

#block[
#callout(
body: 
[
R Packages:

```r
install.packages(c("modelsummary", "tinytable", "dplyr", "ggplot2", "showtext"))
```

]
, 
title: 
[
Required Software (this demo only)
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]
= Components
<components>
== Components
<components-1>
=== Ordered & Unordered Lists
<ordered-unordered-lists>
Here we have an unordered list.

- first item
  - sub-item
- second item

And next we have an ordered one.

+ first item
  + sub-item
+ second item

== Components
<components-2>
=== Alerts & Cross-refs
<sec-crossref>
Special classes for emphasis

- `.alert` class for default emphasis, e.g.~#alert()[the second accent color].
- `.fg` class for custom color, e.g.~#fg(fill: rgb("#5D639E"))[with `options='fill: rgb("#5D639E")'`].
- `.bg` class for custom background, e.g.~#bg()[with the default color].

To cross-reference, you have several options, for example:

- Beamer-like .button class provided by this theme, e.g.~#button()[#link(<sec-appendix>)[Appendix];]
- Sections are not numbered in Touying, you cannot use `@sec-` cross-references

== Components
<components-3>
=== Citations
<citations>
Citations follow the standard #link("https://quarto.org/docs/authoring/footnotes-and-citations.html#citations")[Quarto format] and be sourced from BibLaTeX, BibTeX, or CLS files. For example:

- #alert()[Topic 1:] Review of DID @arkhangelsky2024

- #alert()[Topic 2:] #cite(<goodman-bacon2021>, form: "prose")

=== Small Citations
<small-citations>
In many cases, you may want to use small citations, like

- #alert()[Staggered DID] @callaway2021[#small-cite()[; #cite(<sun2021>, form: "prose");; #cite(<borusyak2024>, form: "prose");]]

This `.small-cite` class is defined as a custom style #button()[#link(<sec-custom-styling>)[custom styling];]

== Components
<components-4>
=== Blocks
<blocks>
Quarto provides #link("https://quarto.org/docs/authoring/cross-references.html#theorems-and-proofs")[dedicated environments] for theorems, lemmas, and so forth.

But in presentation format, it's arguably more effective just to use a #link("https://quarto.org/docs/authoring/callouts.html")[Callout Block];.

#block[
#callout(
body: 
[
The main specification is as follows:

$ y_(i t) = X_(i t) beta + mu_i + epsilon_(i t) $

]
, 
title: 
[
Regression Specification
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
== Components
<components-5>
=== Multicolumn I: Text only
<multicolumn-i-text-only>
#grid(
columns: (1fr, 1fr), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
#alert()[Column 1]

Here is a long sentence that will wrap onto the next line as it hits the column width, and continue this way until it stops.

Some text that should be laid out below the code

],
  rect(stroke: none, width: 100%)[
#alert()[Column 2]

Some other text in another column.

A second paragraph.

],
)
#link("https://quarto.org/docs/authoring/figures.html#block-layout")[Quarto's layout] is more simple and flexible than Touying's native multicolumn support.

== Components
<components-6>
=== Multicolumn II: Text and Figures
<multicolumn-ii-text-and-figures>
#grid(
columns: (1fr, 1fr), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
#box(image("static/img/hokusai_kanagawa.jpg", width: 100.0%))

],
  rect(stroke: none, width: 100%)[
- First point
- Second point

],
)
For simple cases, you don't even need to specify the class for each column.

== Ad-hoc Styling
<ad-hoc-styling>
=== Typst CSS
<typst-css>
- Quarto supports #link("https://quarto.org/docs/advanced/typst/typst-css.html")[Typst CSS] for simple styling
- You can change #text(fill: rgb("#009f8c"))[colors], #highlight(fill: rgb("#f0f0f0"))[backgrounds], and #text(fill: rgb(0, 0, 0, 50%))[opacity] for `span` elements

#block[
#set text(size: 30pt , font: ("Times New Roman",)); You can also change the font size and family for `div` elements.

]
#v(1em)

=== Vertical Spacing
<vertical-spacing>
- A helper shortcode `{{< v DIST >}}` is provided to add vertical spacing
- This is converted to a Typst code `#v(DIST)` internally.

#v(2em)

This is a `2em` vertical spaced from above.

== Custom Styling
<sec-custom-styling>
As #link("https://github.com/quarto-ext/latex-environment")[latex-environment] quarto extenstion, you can define custom `div` and `span` elements.

```yaml
format:
  clean-typst:
    include-in-header: "custom.typ"
    commands: [foo]
```

- You can define custom `div` and `span` elements as Typst functions in `custom.typ`
  - `environments` in YAML is for block elements `:::{.foo}\nbody\n:::`
  - `commands` in YAML is for inline elements `[]{.foo}`
- `[text]{.foo options="opts"}` is converted to `#foo(opts)[text]` internally
- If you want to use `self` as an argument, you can use `touying-fn-wrapper()`

== `brand.yml` Support
<brand.yml-support>
```yaml
brand:
  typography: 
    base: Montserrat
    headings:
      family: Josefin Sans
      weight: semi-bold
    color:
      palette:
        green: "#009F8C"
        pink: "#B75C9D"
      primary: green
      secondary: pink
```

- This template supports #link("https://posit-dev.github.io/brand-yml/")[`brand.yml`] for typography and color settings
- See #link("https://github.com/kazuyanagimoto/quarto-clean-typst/blob/main/template-brand.qmd")[`template-brand.qmd`] for the full example

= Animations
<animations>
== Simple Animations
<sec-simple-animation>
Touying's #link("https://touying-typ.github.io/docs/dynamic/simple")[simple animations] is available as `{{< pause >}}` and `{{< meanwhile >}}`

#pause
This line appears after a pause.

#meanwhile
This line appears meanwhile.

#pause
As Reveal.js, you can use `. . .` for a pause in the slide.

== Animations in Lists
<animations-in-lists>
#strong[Pause in Lists]

Simple animations `{{< pause >}}` can be used in lists

- First #pause
- Second

#strong[Incremental Class]

As Reveal.js, you can use `.incremental` class

#block[
- First #pause
- Second

]
== Complex Animations
<sec-complex-animation>
#slide(repeat: 4, self => [
#let (uncover, only, alternatives) = utils.methods(self)
Touying's #link("https://touying-typ.github.io/docs/dynamic/complex")[complex animations] is available as `{.complex-anim repeat=4}` environment.

At subslide #self.subslide, we can

use #uncover("2-")[`{.uncover}` environment] for reserving space,

use #only("2-")[`{.only}` environment] for not reserving space,

#alternatives[call `#only` multiple times \u{2717}][use `#alternatives` function #sym.checkmark] for choosing one of the alternatives. But only works in a native Typst code. \
#only(
4
)[
=== Other Features
<other-features>
- All the animation functions can be used in Typst Math code #button()[#link(<sec-math-animations>)[Appendix];]
- `handout: true` in YAML header is available for handout mode (without animations)

]

])
= Figures & Tables
<figures-tables>
== Figures
<figures>
#align(center)[#box(image("template-full_files/figure-typst/plot-facet-1.svg"))]
This is a `facet_wrap` example with `penguins` dataset.

== Figures
<figures-1>
#grid(
columns: (1fr, 1fr), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
#align(center)[#box(image("template-full_files/figure-typst/plot-layout-1.svg"))]
],
  rect(stroke: none, width: 100%)[
#align(center)[#box(image("template-full_files/figure-typst/plot-layout-2.svg"))]
],
)
This is an example of `layout-ncol: 2` for two figures.

== Tables
<tables>
#slide(repeat: 3, self => [
#let (uncover, only, alternatives) = utils.methods(self)
#only(
1
)[
#show figure: set block(breakable: true)
#figure( // start figure preamble
  
  kind: "tinytable",
  supplement: "Table", // end figure preamble

block[ // start block

#let nhead = 2;
#let nrow = 3;
#let ncol = 9;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (2, 0), (2, 1), (2, 2), (2, 3), (2, 4), (3, 0), (3, 1), (3, 2), (3, 3), (3, 4), (4, 0), (4, 1), (4, 2), (4, 3), (4, 4), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (8, 0), (8, 1), (8, 2), (8, 3), (8, 4),), ),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    column-gutter: 5pt,
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 2, start: 0, end: 9, stroke: 0.05em + black),
 table.hline(y: 5, start: 0, end: 9, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 9, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[ ],table.cell(stroke: (bottom: .05em + black), colspan: 4, align: center)[Male],table.cell(stroke: (bottom: .05em + black), colspan: 4, align: center)[Female],
[], [Bill Length (mm)], [Bill Depth (mm)], [Flipper Length (mm)], [Body Mass (g)], [Bill Length (mm)], [Bill Depth (mm)], [Flipper Length (mm)], [Body Mass (g)],
    ),

    // tinytable cell content after
[Adelie], [40.39], [19.07], [192.4], [4043], [37.26], [17.62], [187.8], [3369],
[Gentoo], [49.47], [15.72], [221.5], [5485], [45.56], [14.24], [212.7], [4680],
[Chinstrap], [51.09], [19.25], [199.9], [3939], [46.57], [17.59], [191.7], [3527],

    // tinytable footer after

  ) // end table

  ]) // end align

] // end block
) // end figure
]
#only(
"2-"
)[
#show figure: set block(breakable: true)
#figure( // start figure preamble
  
  kind: "tinytable",
  supplement: "Table", // end figure preamble

block[ // start block

#let nhead = 2;
#let nrow = 3;
#let ncol = 9;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 3), (1, 3), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (8, 3),), bold: true, color: white, background: rgb("#107895"),),
(pairs: ((0, 0), (0, 1), (0, 2), (0, 4), (1, 0), (1, 1), (1, 2), (1, 4), (2, 0), (2, 1), (2, 2), (2, 4), (3, 0), (3, 1), (3, 2), (3, 4), (4, 0), (4, 1), (4, 2), (4, 4), (5, 0), (5, 1), (5, 2), (5, 4), (6, 0), (6, 1), (6, 2), (6, 4), (7, 0), (7, 1), (7, 2), (7, 4), (8, 0), (8, 1), (8, 2), (8, 4),), ),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 2, start: 0, end: 9, stroke: 0.05em + black),
 table.hline(y: 5, start: 0, end: 9, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 9, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[ ],table.cell(stroke: (bottom: .05em + black), colspan: 4, align: center)[Male],table.cell(stroke: (bottom: .05em + black), colspan: 4, align: center)[Female],
[], [Bill Length (mm)], [Bill Depth (mm)], [Flipper Length (mm)], [Body Mass (g)], [Bill Length (mm)], [Bill Depth (mm)], [Flipper Length (mm)], [Body Mass (g)],
    ),

    // tinytable cell content after
[Adelie], [40.39], [19.07], [192.4], [4043], [37.26], [17.62], [187.8], [3369],
[Gentoo], [49.47], [15.72], [221.5], [5485], [45.56], [14.24], [212.7], [4680],
[Chinstrap], [51.09], [19.25], [199.9], [3939], [46.57], [17.59], [191.7], [3527],

    // tinytable footer after

  ) // end table

  ]) // end align

] // end block
) // end figure
]
#v(1em)

- You can easily create Typst tables by #link("https://vincentarelbundock.github.io/tinytable/")[`tinytable`] #pause
- You can #alert()[highlight] by `tinytable::style_tt()`! #pause
- Set `options(tinytable_quarto_figure = TRUE)` to create figures (tables) without captions #pause

])
== Regression Table
<regression-table>
#show figure: set block(breakable: true)
#figure( // start figure preamble
  
  kind: "tinytable",
  supplement: "Table", // end figure preamble

block[ // start block

#let nhead = 2;
#let nrow = 9;
#let ncol = 7;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10),), align: left,),
(pairs: ((1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (2, 0), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (3, 0), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (4, 0), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 6), (6, 7), (6, 8), (6, 9), (6, 10),), align: center,),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    column-gutter: 5pt,
    columns: (auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 2, start: 0, end: 7, stroke: 0.05em + black),
 table.hline(y: 10, start: 0, end: 7, stroke: 0.05em + black),
 table.hline(y: 11, start: 0, end: 7, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 7, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[ ],table.cell(stroke: (bottom: .05em + black), colspan: 3, align: center)[Bill Length (mm)],table.cell(stroke: (bottom: .05em + black), colspan: 3, align: center)[Body Mass (g)],
[ ], [(1)], [(2)], [(3)], [(4)], [(5)], [(6)],
    ),

    // tinytable cell content after
[Chinstrap], [10.042\*\*], [10.010\*\*], [10.037\*\*], [32.426], [26.924], [27.229],
[], [(0.432)], [(0.341)], [(0.340)], [(67.512)], [(46.483)], [(46.587)],
[Gentoo], [8.713\*\*], [8.698\*\*], [8.693\*\*], [1375.354\*\*], [1377.858\*\*], [1377.813\*\*],
[], [(0.360)], [(0.287)], [(0.286)], [(56.148)], [(39.104)], [(39.163)],
[Male], [], [3.694\*\*], [3.694\*\*], [], [667.555\*\*], [667.560\*\*],
[], [], [(0.255)], [(0.254)], [], [(34.704)], [(34.755)],
[Year], [], [], [0.324\*], [], [], [3.629],
[], [], [], [(0.156)], [], [], [(21.428)],
[Observations], [342], [333], [333], [342], [333], [333],

    // tinytable footer after

    table.footer(
      repeat: false,
      // tinytable notes after
    table.cell(align: left, colspan: 7, text([\+ p \< 0.1, \* p \< 0.05, \*\* p \< 0.01])),
    ),
    

  ) // end table

  ]) // end align

] // end block
) // end figure
#link("https://modelsummary.com")[modelsummary] is a super useful for regression tables (`tinytable` is used internally)

== Last Words
<sec-last>
=== Installation
<installation>
```bash
quarto install extension kazuyanagimoto/quarto-clean-typst
```

=== Limitations
<limitations>
- Background colors and images are not supported

=== Appendix
<appendix>
- You can use `{{< appendix >}}` to start an appendix section. Slide numbering will be freezed. (Next Slides)

#show: appendix
= Appendix
<sec-appendix>
== Touying Math Animations
<sec-math-animations>
```typst
Touying equation with pause:
$
  f(x) &= pause x^2 + 2x + 1  \
       &= pause (x + 1)^2  \
$
Touying equation is very simple.
```

Touying equation with pause:

$
  f(x) &= pause x^2 + 2x + 1  \
       &= pause (x + 1)^2  \
$
#meanwhile
Touying equation is very simple.

#button()[#link(<sec-complex-animation>)[Back to main];]

== References
<references>
#block[
] <refs>


 

#set bibliography(style: "chicago-author-date")


#bibliography("static/references.bib")

