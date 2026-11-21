# Process the SSI 2012 survey.
# R port of the SSI block of dataproc-gss-ssi-merge.do. Source data: public
# SSI-2012 release (https://olizardo.github.io/SSI-2012/, CC BY 4.0).
#
# Note: the public release contains 2,275 records; the original analysis used
# the 2,276-record internal file. Taste codes are already 1 = like, 2 = dislike,
# 3 = mixed feelings, 4 = not familiar (dk).
suppressMessages({
  library(dplyr)
  library(purrr)
  library(tibble)
})

ssi <- readRDS("data-raw/ssi2012_cleaned.rds")
# strip haven labels (values are used as raw numeric codes, as in the Stata code)
ssi[] <- lapply(ssi, function(x) if (inherits(x, "haven_labelled")) as.numeric(unclass(x)) else x)

taste_names <- c(
  "classical", "opera", "jazz", "bwayst", "moodez", "country", "blueg",
  "folk", "hymgos", "latspsal", "raphiphop", "blurb", "reggae",
  "controck", "hvymtl"
)

# Degree collapsed to the 0-4 GSS scale (Stata: recode degree 2=1 3=2 4=3 5/6=4)
ssi <- ssi |>
  mutate(
    # Stata applies the replace statements in sequence, so later rules override
    # earlier ones (e.g. bach == 1 wins over somcol == 1). Replicate by listing
    # the rules in reverse order under first-match case_when.
    degree6 = case_when(
      docprof == 1 ~ 6,
      ma == 1 & docprof == 0 ~ 5,
      bach == 1 & ma == 0 ~ 4,
      aadeg == 1 & bach == 0 ~ 3,
      somcol == 1 & aadeg == 0 ~ 2,
      hsged == 1 & somcol == 0 ~ 1,
      nodipdeg == 1 ~ 0
    ),
    # Stata: recode degree 2 = 1 3 = 2 4 = 3 5/6 = 4 (some college counts as HS)
    degree = case_when(
      degree6 == 0 ~ 0, degree6 <= 2 ~ 1, degree6 == 3 ~ 2,
      degree6 == 4 ~ 3, degree6 >= 5 ~ 4
    ),
    # original: female (0/1) recoded to sex 1 = men, 2 = women
    sex = ifelse(female == 1, 2, 1),
    race = case_when(raceeth == 4 ~ 1, raceeth == 2 ~ 2, TRUE ~ 3),
    agecat = as.numeric(age), # SSI age is already the 2-15 band code
    year = 2012,
    # Stata: gen inc = income; recode inc 17/20 = 17 21/23 = 18
    inc = ifelse(income >= 21, 18, ifelse(income >= 17, 17, income))
  )

# Stata semantics: a missing taste yields 0 (not missing) in every dummy
dummies <- map(taste_names, function(g) {
  t <- ssi[[paste0(g, "taste")]]
  tibble(
    "{g}like" := as.numeric(!is.na(t) & t == 1),
    "{g}dis" := as.numeric(!is.na(t) & t == 2),
    "{g}meh" := as.numeric(!is.na(t) & t == 3),
    "{g}dk" := as.numeric(!is.na(t) & t == 4)
  )
}) |>
  bind_cols()

ssi <- ssi |>
  bind_cols(dummies) |>
  select(year, degree, agecat, sex, race, income, inc, all_of(paste0(rep(taste_names, each = 4),
    c("like", "dis", "meh", "dk"))))

fs::dir_create("data")
saveRDS(ssi, "data/ssi-working.rds")
cat("SSI 2012 processed:", nrow(ssi), "rows\n")
