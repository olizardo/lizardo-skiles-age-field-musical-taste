# Process the GSS 1993 musical taste module.
# R port of the GSS block of dataproc-gss-ssi-merge.do. Source data: gssr::gss_all.
# Taste items are recoded: 1-2 = like, 3 = mixed feelings, 4-5 = dislike,
# 8-9 (can't choose / no answer) -> 4 (don't know).
suppressMessages({
  library(gssr)
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(tibble)
})

data(gss_all)

# Strip haven labels but keep the tagged missings as their original numeric
# codes (8 = can't say, 9 = no answer), which the taste recode maps to "dk".
zap <- function(df) {
  df[] <- lapply(df, function(x) {
    if (!inherits(x, "haven_labelled")) return(x)
    tags <- haven::na_tag(x)
    v <- as.numeric(unclass(x))
    v[!is.na(tags) & tags == "d"] <- 8
    v[!is.na(tags) & tags == "n"] <- 9
    v
  })
  df
}

gss93 <- gss_all |>
  filter(year == 1993) |>
  select(
    degree, age, sex, race,
    blugrass, country, blues, musicals, classicl, folk, gospel,
    jazz, latin, moodeasy, opera, rap, reggae, conrock, hvymetal
  ) |>
  rename(
    bluegtaste = blugrass, blurbtaste = blues,
    bwaysttaste = musicals, classicaltaste = classicl, moodeztaste = moodeasy,
    latspsaltaste = latin, raphiphoptaste = rap, hymgostaste = gospel,
    operataste = opera, countrytaste = country, folktaste = folk, jazztaste = jazz,
    reggaetaste = reggae, controcktaste = conrock, hvymtltaste = hvymetal
  ) |>
  zap()

taste_names <- c(
  "classical", "opera", "jazz", "bwayst", "moodez", "country", "blueg",
  "folk", "hymgos", "latspsal", "raphiphop", "blurb", "reggae",
  "controck", "hvymtl"
)

# Recode tastes: like=1, dislike=2, mixed=3, dk=4; everything else -> NA
gss93 <- gss93 |>
  mutate(across(ends_with("taste"), ~ case_when(
    .x %in% c(1, 2) ~ 1,
    .x == 3 ~ 3,
    .x %in% c(4, 5) ~ 2,
    .x %in% c(8, 9) ~ 4,
    TRUE ~ NA
  )))

# Like / dislike / mixed / don't-know dummies per genre.
# Stata semantics: gen x = taste == 1 yields 0 (not missing) when taste is
# missing, so missings map to 0 in all four dummies.
dummies <- map(taste_names, function(g) {
  t <- gss93[[paste0(g, "taste")]]
  tibble(
    "{g}like" := as.numeric(!is.na(t) & t == 1),
    "{g}dis" := as.numeric(!is.na(t) & t == 2),
    "{g}meh" := as.numeric(!is.na(t) & t == 3),
    "{g}dk" := as.numeric(!is.na(t) & t == 4)
  )
}) |>
  bind_cols()

# Age bands (Stata recode age 18/19=2 20/24=3 ... 80/100=15); recode degree 8/9=.
gss93 <- gss93 |>
  bind_cols(dummies) |>
  transmute(
    year = 1993,
    degree = ifelse(degree %in% c(8, 9), NA, as.numeric(degree)),
    agecat = as.numeric(as.character(cut(age, breaks = c(17, 19, 24, 29, 34, 39, 44, 49,
                            54, 59, 64, 69, 74, 79, 100), labels = 2:15))),
    sex, race,
    across(all_of(unlist(lapply(taste_names, function(g) paste0(g, c("like", "dis", "meh", "dk"))))), as.numeric)
  )

fs::dir_create("data")
saveRDS(gss93, "data/gss-working.rds")
cat("GSS 1993 processed:", nrow(gss93), "rows\n")
