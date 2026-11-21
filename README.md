# Replication: "Musical taste and patterns of symbolic exclusion in the United States 1993–2012: Generational dynamics of differentiation and continuity"

Open-source R reproduction of the figures and likelihood-ratio tests in
Lizardo & Skiles, *Poetics* 53: 9–21.

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

Each bar in the figures is the average marginal effect of survey year at each
age band: the change in the predicted probability of disliking a style when a
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
source("R/05-validate-merge.R")        # optional: internal consistency checks
source("R/06-lr-tests.R")              # Tables 1-3
source("R/07-figures.R")               # Figures 1-3
```

Requires R >= 4.2 and the packages: `gssr`, `haven`, `dplyr`, `purrr`,
`tibble`, `ggplot2`, `fs`. Run `renv::restore()` for the exact versions
recorded in `renv.lock`.

## Method notes

- **Model specifications.** Figure 1 and Table 1 use an additive model with a
  quadratic in `agecat`; Figure 2, Table 2, Figure 3, and Table 3 use a
  **cubic** polynomial in age (the cubic reproduces the U-shapes, humps, and
  end-of-distribution reversals visible in the published figures, and every
  decision in Tables 2 and 3; a quadratic misses Folk in Table 2 and
  Country/Rap/Metal in Table 3).
- **Recode semantics:** first matching rule wins in the cohort recodes
  (cohort 1975 goes to the 1965-1975 bin, not the 1975-2000 bin); in the SSI
  degree construction, later rules override earlier ones; GSS cases with
  missing degree (`degree > 2`) count as college-educated; a missing taste
  yields 0 (not missing) in the like/dislike/mixed/don't-know dummies.
- **SSI degree collapse:** the 0-6 degree scale is recoded to 0-4 with some
  college counted as high school (`degree` 2 -> 1, 3 -> 2, 4 -> 3, 5/6 -> 4).
- **Validation (`R/05-validate-merge.R`).** Internal consistency checks on the
  rebuilt merged dataset (3,881 rows: 1,606 GSS 1993 + 2,275 SSI 2012). The
  public SSI release has one record fewer than the internal 2,276-record file
  used for the paper, and `income` is coded differently in the public release
  (it is not used in the analysis).
- Published predicted-probability anchors from the text reproduce closely
  (e.g. Opera, college-educated 25-29: 0.51 -> 0.36 in the replication vs
  0.48 -> 0.35 reported).

## License

Code: MIT. The SSI-2012 dataset is distributed by its authors under CC BY 4.0;
GSS data are subject to the GSS terms of use (NORC).
