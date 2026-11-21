# Validate the remotely built merged dataset against the original Stata
# analysis file shipped with the paper (original-stata/gss-ssi-merged.dta).
#
# The original file lists the 2,276 SSI 2012 records first, then the 1,606 GSS
# 1993 records. The public SSI release has one record fewer, so the SSI blocks
# are matched row-by-row on their full content instead of by position.
suppressMessages({
  library(haven)
  library(dplyr)
  library(purrr)
})

# The shipped Stata analysis file (original-stata/gss-ssi-merged.dta) is kept
# out of the public repo; validation runs only when it is present locally.
if (!file.exists("original-stata/gss-ssi-merged.dta")) {
  cat("original-stata/gss-ssi-merged.dta not found; skipping validation.\n")
  cat("The pipeline is complete; run 06-lr-tests.R and 07-figures.R.\n")
  quit("no", status = 0)
}
rebuilt <- readRDS("data/gss-ssi-merged.rds")
orig <- as.data.frame(read_dta("original-stata/gss-ssi-merged.dta"))

strip <- function(df) {
  df[] <- lapply(df, function(x) if (inherits(x, "haven_labelled")) as.numeric(x) else x)
  as.data.frame(df)
}
orig <- strip(orig)

cat("Original:", nrow(orig), "rows | Rebuilt:", nrow(rebuilt), "rows\n")
common <- intersect(names(orig), names(rebuilt))
cat("Only in original:", paste(setdiff(names(orig), common), collapse = ", "), "\n")
cat("Only in rebuilt:  ", paste(setdiff(names(rebuilt), common), collapse = ", "), "\n\n")

compare_block <- function(a, b, label) {
  stopifnot(nrow(a) == nrow(b))
  mism <- map_int(common, function(v) {
    x <- a[[v]]; y <- b[[v]]
    sum(xor(is.na(x), is.na(y)) | (!is.na(x) & !is.na(y) & abs(x - y) > 1e-6))
  })
  cat(label, ": max per-column mismatches =", max(mism),
      "(columns affected:", paste(common[mism > 0], collapse = ", "), ")\n")
  invisible(mism)
}

# GSS 1993: same row count on both sides, compare by position
compare_block(orig[orig$year == 1993, common],
              rebuilt[rebuilt$year == 1993, common], "GSS 1993")

# SSI 2012: match on full content (one record missing from the public release)
o12 <- orig[orig$year == 2012, setdiff(common, c("income", "inc"))] |> distinct()
r12 <- rebuilt[rebuilt$year == 2012, setdiff(common, c("income", "inc"))] |> distinct() |> mutate(.rn = row_number())
key <- function(df) do.call(paste, c(df[setdiff(names(df), ".rn")], sep = "|"))
m <- match(key(o12), key(r12))
cat("SSI 2012: distinct original rows:", nrow(o12),
    "| matched to rebuilt:", sum(!is.na(m)),
    "| unmatched in rebuilt:", sum(is.na(m)), "\n")
r12m <- r12[m[!is.na(m)], ]
o12m <- o12[!is.na(m), ]
compare_block(o12m, r12m, "SSI 2012 (matched)")

# Which record(s) of the rebuilt SSI data are not in the original?
extra <- anti_join(r12, o12, by = setdiff(names(r12), ".rn"))
if (nrow(extra) > 0) {
  cat("\nRecord(s) present in rebuilt but not in original (expected: the one\n")
  cat("record dropped between the internal 2,276-row file and the public release):\n")
  print(extra)
}
