# Replication: "Musical taste and patterns of symbolic exclusion in the United States 1993–2012: Generational dynamics of differentiation and continuity"

Open-source R reproduction of the figures and likelihood-ratio tests in
Lizardo & Skiles, *Poetics* 53: 9–21, originally estimated in Stata (the
original `.do` files and the shipped analysis dataset are preserved locally in
`original-stata/` for provenance; that folder is not part of the public
repository).

## Citations

Original publication:

> Lizardo, Omar, and Sara Skiles. 2015. "Musical Taste and Patterns of
> Symbolic Exclusion in the United States 1993–2012: Generational Dynamics of
> Differentiation and Continuity." *Poetics* 53: 9–21.
> https://doi.org/10.1016/j.poetic.2015.08.003

Data:

> Lizardo, Omar, and Sara Skiles. 2012. *Survey Sample International (SSI)
> Cultural Tastes Survey* [Dataset]. Distributed at
> https://olizardo.github.io/SSI-2012/. CC BY 4.0.

> Smith, Tom W., Michael Davern, Jeremy Freese, and Michael Hout. *General
> Social Surveys, 1972–2022: Cumulative Codebook / Data File*. Chicago: NORC
> at the University of Chicago. [Producer and distributor of the 1993 data.]
> Accessed in R via the `gssr` package.

Software:

> Healy, Kieran. *gssr: General Social Survey Data*. R package.
> https://github.com/kjhealy/gssr.

## Outputs reproduced

| Output | Script | File |
|--------|--------|------|
| Figure 1 — year effect on dislike, additive model, 15 styles | `R/07-figures.R` | `output/figures/figure1.png` |
| Figure 2 — year effect, cubic age x year, 12 styles | `R/07-figures.R` | `output/figures/figure2.png` |
| Figure 3 — year effect, cubic age x year x college, 9 styles | `R/07-figures.R` | `output/figures/figure3.png` |
| Table 1 — LR tests, year effect | `R/06-lr-tests.R` | `output/tables/table1-lrtest-year.csv` |
| Table 2 — LR tests, year x age | `R/06-lr-tests.R` | `output/tables/table2-lrtest-year-age.csv` |
| Table 3 — LR tests, year x age x education | `R/06-lr-tests.R` | `output/tables/table3-lrtest-year-age-degree.csv` |

Each bar in the figures is the Stata `margins, dydx(year) over(agecat)`
quantity: the change in the predicted probability of disliking a style when a
respondent is "transported" from 1993 to 2012, computed at each age band, with
95% delta-method confidence intervals.

## Data

No raw data is committed. The scripts fetch both sources remotely:

- **GSS 1993** musical taste module, via the [`gssr`](https://github.com/kjhealy/gssr)
  package (`gss_all`).
- **SSI 2012** (`ssi2012_cleaned.rds`), downloaded from
  https://olizardo.github.io/SSI-2012/ (Lizardo & Skiles, CC BY 4.0).

## How to run

```r
# from the repo root, in order:
source("R/01-download-data.R")         # fetches SSI-2012
source("R/02-process-gss-1993.R")      # builds data/gss-working.rds
source("R/03-process-ssi-2012.R")      # builds data/ssi-working.rds
source("R/04-build-analysis-data.R")   # builds data/gss-ssi-merged.rds
source("R/05-validate-merge.R")        # optional: compares against the shipped
                                       # Stata file (original-stata/, local only)
source("R/06-lr-tests.R")              # Tables 1-3
source("R/07-figures.R")               # Figures 1-3
```

Requires R >= 4.2 and the packages: `gssr`, `haven`, `dplyr`, `purrr`,
`tibble`, `ggplot2`, `fs`.

## Method notes

- **Model specifications.** The shipped Stata do file specifies a quadratic in
  `agecat` throughout, but the published figures and the reported
  Reject/Accept decisions correspond to a **cubic** polynomial in age for
  Figure 2, Table 2, Figure 3, and Table 3 (the cubic reproduces the
  U-shapes, humps, and end-of-distribution reversals visible in the published
  figures, and every decision in Tables 2 and 3; the quadratic misses Folk in
  Table 2 and Country/Rap/Metal in Table 3). Figure 1 and Table 1 use the
  additive/quadratic specifications as written in the do file.
- **Stata recode semantics replicated:** first matching rule wins in `recode`
  (cohort 1975 goes to the 1965-1975 bin, not the 1975-2000 bin); sequential
  `replace` statements let later rules override earlier ones (SSI degree
  construction); a missing value satisfies `> 2`, so the 4 GSS cases with
  missing degree get `college = 1`; a missing taste yields 0 (not missing) in
  the like/dislike/mixed/don't-know dummies.
- **SSI degree collapse:** the do file recodes the 0-6 degree scale to 0-4
  with some college counted as high school (`recode degree 2 = 1 3 = 2 4 = 3
  5/6 = 4`).
- **Validation (`R/05-validate-merge.R`, requires the local
  `original-stata/` folder).** The rebuilt merged dataset
  (3,881 rows) matches the shipped Stata analysis file (3,882 rows) exactly on
  the GSS 1993 block and on 2,260 of 2,262 distinct SSI 2012 records; the
  public SSI release has one record fewer than the internal 2,276-record file
  used for the paper, and `income` is coded differently in the public release
  (it is not used in the analysis).
- Published predicted-probability anchors from the text reproduce closely
  (e.g. Opera, college-educated 25-29: 0.51 -> 0.36 in the replication vs
  0.48 -> 0.35 reported).

## License

Code: MIT. The SSI-2012 dataset is distributed by its authors under CC BY 4.0;
GSS data are subject to the GSS terms of use (NORC).
