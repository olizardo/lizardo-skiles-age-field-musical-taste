# Likelihood-ratio tests reported in Tables 1-3 of the paper.
#
# Table 1: does the probability of disliking a genre differ between 1993 and
#          2012 at all? Base model: age-group indicators; test adds a survey
#          year dummy. All 15 styles.
# Table 2: does the age pattern of the year effect vary across age groups?
#          Base: cubic in agecat + year; test: cubic x year interaction.
#          12 styles (Showtunes, Blues, Reggae excluded in the original).
# Table 3: does the age pattern of the year effect vary with education?
#          Base models alternate per style (see `alt'); test adds the full
#          cubic x year x degree interaction (degree enters linearly).
#          Restricted to respondents with non-missing degree.
suppressMessages({
  library(dplyr)
  library(purrr)
  library(tibble)
})

merged <- readRDS("data/gss-ssi-merged.rds")
merged$year <- factor(merged$year, levels = c(1993, 2012))

taste_names <- c(
  "classical", "opera", "jazz", "bwayst", "moodez", "country", "blueg",
  "folk", "hymgos", "latspsal", "raphiphop", "blurb", "reggae",
  "controck", "hvymtl"
)
taste12 <- setdiff(taste_names, c("bwayst", "blurb", "reggae"))

lrtest <- function(m1, m2) {
  chisq <- 2 * (logLik(m2) - logLik(m1))[1]
  df <- attr(logLik(m2), "df") - attr(logLik(m1), "df")
  pval <- pchisq(chisq, df, lower.tail = FALSE)
  tibble(chi2 = chisq, df = df, p = pval)
}

prep <- function(genre, need_degree = FALSE) {
  y <- paste0(genre, "dis")
  d <- merged |>
    rename(.y = all_of(y)) |>
    filter(!is.na(.y), !is.na(agecat), !is.na(year))
  if (need_degree) d <- filter(d, !is.na(degree))
  d
}

# Table 1: age-group indicators vs + year (all 15 styles)
tab1 <- map_dfr(taste_names, function(g) {
  d <- prep(g)
  lrtest(glm(.y ~ factor(agecat), binomial, d),
         glm(.y ~ factor(agecat) + year, binomial, d)) |>
    mutate(genre = g, .before = 1)
})

# Table 2: cubic age + year vs cubic x year (12 styles)
tab2 <- map_dfr(taste12, function(g) {
  d <- prep(g)
  lrtest(glm(.y ~ poly(agecat, 3) + year, binomial, d),
         glm(.y ~ poly(agecat, 3) * year, binomial, d)) |>
    mutate(genre = g, .before = 1)
})

# Table 3: base alternates per the original `alt' vector (0: base includes the
# year x cubic-age interaction; 1: base is additive in year); test adds the
# cubic x year x degree interaction
alt <- c(0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0)
tab3 <- map_dfr(seq_along(taste12), function(i) {
  g <- taste12[i]
  d <- prep(g, need_degree = TRUE)
  base <- if (alt[i] == 0) .y ~ poly(agecat, 3) * year else .y ~ poly(agecat, 3) + year
  lrtest(glm(base, binomial, d),
         glm(.y ~ poly(agecat, 3) * year * degree, binomial, d)) |>
    mutate(genre = g, base_has_year_interaction = alt[i], .before = 1)
})

fs::dir_create("output/tables")
write.csv(tab1, "output/tables/table1-lrtest-year.csv", row.names = FALSE)
write.csv(tab2, "output/tables/table2-lrtest-year-age.csv", row.names = FALSE)
write.csv(tab3, "output/tables/table3-lrtest-year-age-degree.csv", row.names = FALSE)
cat("LR tests written to output/tables/\n")
print(tab1); print(tab2); print(tab3)
