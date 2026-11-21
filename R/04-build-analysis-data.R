# Build the merged GSS 1993 / SSI 2012 analysis dataset.
# R port of the merge half of dataproc-gss-ssi-merge.do.
suppressMessages({
  library(dplyr)
})

gss <- readRDS("data/gss-working.rds")
ssi <- readRDS("data/ssi-working.rds")

merged <- bind_rows(gss, ssi)

# Cohort midpoints per agecat (Stata: local mids 18.5 22 27 ... 77 85)
agemid_map <- setNames(c(18.5, 22, 27, 32, 37, 42, 47, 52, 57, 62, 67, 72, 77, 85),
                       as.character(2:15))

merged <- merged |>
  mutate(
    # cohort computed from the ORIGINAL agecat, before the agecat 2 -> 3 recode
    agemid = unname(agemid_map[as.character(agecat)]),
    # Stata round() is half-away-from-zero; R's is banker's rounding
    cohort_raw = floor(year - agemid + 0.5),
    # Stata: egen cohort2 = cut(cohort), at(1905(5)1995); values outside
    # [1905, 1995] are missing
    cohort = cut(cohort_raw, breaks = seq(1905, 1995, by = 5),
                 labels = seq(1905, 1990, by = 5), right = FALSE),
    cohort = as.numeric(as.character(cohort)),
    # Stata recode cohort 1900/1935=1 1936/1954=2 1955/1972=3 1973/2000=4
    cohortrec4 = cut(cohort, breaks = c(-Inf, 1935.5, 1954.5, 1972.5, Inf),
                     labels = 1:4),
    # Stata recode cohort 1900/1935=1 1936/1946=2 1947/1964=3 1965/1975=4 1975/2000=5
    cohortrec5 = cut(cohort, breaks = c(-Inf, 1935.5, 1946.5, 1964.5, 1975, Inf),
                     labels = 1:5),
    # Stata recode cohort 1900/1935=1 1936/1946=2 1947/1954=3 1955/1964=4
    #                       1965/1975=5 1975/2000=6
    cohortrec6 = cut(cohort, breaks = c(-Inf, 1935.5, 1946.5, 1954.5, 1964.5, 1975, Inf),
                     labels = 1:6),
    # Stata: recode agecat 2 = 3 (applied to the merged data)
    agecat = ifelse(agecat == 2, 3, agecat),
    # Stata semantics: a missing degree still satisfies "> 2" (missing is a
    # large value), so the 4 GSS cases with missing degree get college = 1
    college = ifelse(is.na(degree), 1, as.numeric(degree > 2)),
    numlikes = rowSums(across(ends_with("like")), na.rm = FALSE),
    numdislikes = rowSums(across(ends_with("dis")), na.rm = FALSE),
    nummeh = rowSums(across(ends_with("meh")), na.rm = FALSE),
    numdk = rowSums(across(ends_with("dk")), na.rm = FALSE)
  ) |>
  select(-agemid, -cohort_raw) |>
  mutate(across(c(cohortrec4, cohortrec5, cohortrec6), ~ as.numeric(as.character(.x))))

fs::dir_create("data")
saveRDS(merged, "data/gss-ssi-merged.rds")
cat("Merged analysis data:", nrow(merged), "rows\n")
