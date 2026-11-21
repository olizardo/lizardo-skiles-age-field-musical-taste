# The three published figures (Poetics 53, 2015).
#
# Each bar is the Stata `margins, dydx(year) over(agecat)' quantity: the
# average marginal effect of survey year (2012 minus 1993) on the probability
# of disliking a genre, at each age band, with 95% delta-method confidence
# intervals. Because the models include no covariates beyond age, year, and
# (for Figure 3) education, the margins are deterministic predictions.
#
#   Figure 1: additive year model (quadratic in agecat), 15 styles
#   Figure 2: cubic agecat x year interaction, 12 styles
#   Figure 3: cubic agecat x year x college, two education panels per style
suppressMessages({
  library(dplyr)
  library(purrr)
  library(ggplot2)
  library(fs)
})

merged <- readRDS("data/gss-ssi-merged.rds")
merged$year <- factor(merged$year, levels = c(1993, 2012))

taste_names <- c(
  "classical", "opera", "jazz", "bwayst", "moodez", "country", "blueg",
  "folk", "hymgos", "latspsal", "raphiphop", "blurb", "reggae",
  "controck", "hvymtl"
)
style_labels <- c(
  classical = "Classical", opera = "Opera", jazz = "Jazz", bwayst = "Showtunes",
  moodez = "Easy", country = "Country", blueg = "Bluegrass", folk = "Folk",
  hymgos = "Religious", latspsal = "Latin", raphiphop = "Rap", blurb = "Blues",
  reggae = "Reggae", controck = "Rock", hvymtl = "Metal"
)
# Age-band labels (after the agecat 2 -> 3 recode, bands run 3..15);
# the original figures label only three positions on the x axis
age_labels <- c("18-19", "20-24", "25-29", "30-34", "35-39", "40-44", "45-49",
                "50-54", "55-59", "60-64", "65-69", "70-74", "75-79", "80+")
names(age_labels) <- as.character(2:15)

# Fit the logit and compute the year effect (2012 - 1993) at each age band,
# with delta-method standard errors.
ame_year <- function(genre, rhs) {
  y <- paste0(genre, "dis")
  d <- merged |>
    rename(.y = all_of(y)) |>
    filter(!is.na(.y), !is.na(agecat), !is.na(year))
  m <- glm(as.formula(paste(".y ~", rhs)), family = binomial, data = d)
  V <- vcov(m)
  has_college <- grepl("college", rhs)
  # rows ordered so that each (agecat[, college]) block holds the adjacent
  # 1993 / 2012 pair (expand.grid varies the first factor fastest)
  grid <- if (has_college) {
    expand.grid(year = c("1993", "2012"), college = c(0, 1), agecat = 3:15)
  } else {
    expand.grid(year = c("1993", "2012"), agecat = 3:15)
  }
  grid$year <- factor(grid$year, c("1993", "2012"))

  X <- model.matrix(delete.response(terms(m)), grid)
  p <- plogis(as.vector(X %*% coef(m)))
  grad <- p * (1 - p) * X # d p / d beta

  rows <- seq(1, nrow(grid), by = 2) # 1993 row of each age x education pair
  map_dfr(rows, function(i) {
    gvec <- grad[i + 1, ] - grad[i, ] # gradient of p(2012) - p(1993)
    se <- sqrt(as.numeric(t(gvec) %*% V %*% gvec))
    tibble(agecat = grid$agecat[i],
           college = if (has_college) grid$college[i] else NA_real_,
           ame = p[i + 1] - p[i], se = se,
           lo = ame - 1.96 * se, hi = ame + 1.96 * se)
  }) |>
    mutate(genre = genre, .before = 1)
}

panel <- function(df, ncol, dodge = FALSE) {
  df <- df |>
    mutate(genre = factor(genre, levels = names(style_labels)),
           .x = factor(agecat, levels = names(age_labels)))
  p <- ggplot(df, aes(x = .x, y = ame))
  if (dodge) {
    p <- p + geom_col(aes(fill = college), width = 0.8, color = "red3",
                      position = position_dodge(0.9)) +
      geom_errorbar(aes(ymin = lo, ymax = hi, group = college), color = "green3",
                    width = 0.25, position = position_dodge(0.9))
  } else {
    p <- p + geom_col(width = 0.8, fill = "red3", color = "red3") +
      geom_errorbar(aes(ymin = lo, ymax = hi), color = "green3", width = 0.25)
  }
  p +
    geom_hline(yintercept = 0, linewidth = 0.4) +
    facet_wrap(~ genre, ncol = ncol, labeller = labeller(genre = style_labels)) +
    scale_x_discrete(breaks = c("4", "9", "14"),
                     labels = c("Young", "Middle", "Old")) +
    labs(y = "Pr. of Dislike", x = NULL, fill = NULL) +
    theme_bw() +
    theme(legend.position = "bottom", strip.background = element_blank())
}

save_fig <- function(p, file, w, h) {
  dir_create("output/figures")
  ggsave(file.path("output/figures", file), p, width = w, height = h, dpi = 200)
}

## Figure 1: additive year model, all 15 styles --------------------------------
fig1 <- map(taste_names, ~ ame_year(.x, "agecat + I(agecat^2) + year")) |>
  bind_rows()
save_fig(panel(fig1, ncol = 5), "figure1.png", 6.5, 4)

## Figure 2: cubic age x year, 12 styles ----------------------------------------
taste12 <- setdiff(taste_names, c("bwayst", "blurb", "reggae"))
fig2 <- map(taste12, ~ ame_year(.x, "poly(agecat, 3) * year")) |> bind_rows()
save_fig(panel(fig2, ncol = 4), "figure2.png", 8, 6)

## Figure 3: cubic age x year x college, 9 styles, two panels each --------------
taste9 <- c("classical", "opera", "jazz", "country", "folk", "latspsal",
            "raphiphop", "controck", "hvymtl")
fig3 <- map(taste9, ~ ame_year(.x, "poly(agecat, 3) * year * college")) |>
  bind_rows() |>
  mutate(college = factor(college, c(0, 1), c("No College", "College Degree")))

# Order panels: No College / College Degree pairs, genres in figure order
panel_keys <- as.vector(t(outer(taste9, c("No College", "College Degree"),
  function(g, c) paste0(g, "_", c))))
panel_labels <- as.vector(t(outer(taste9, c("No College", "College Degree"),
  function(g, c) paste0(style_labels[g], "\n", c))))
fig3 <- fig3 |>
  mutate(panel = factor(paste0(genre, "_", college), levels = panel_keys,
                        labels = panel_labels))

p3 <- ggplot(fig3, aes(x = factor(agecat, levels = names(age_labels)), y = ame)) +
  geom_col(fill = "red3", color = "red3", width = 0.8) +
  geom_errorbar(aes(ymin = lo, ymax = hi), color = "green3", width = 0.25) +
  geom_hline(yintercept = 0, linewidth = 0.4) +
  facet_wrap(~ panel, ncol = 6) +
  scale_x_discrete(breaks = c("4", "9", "14"),
                   labels = c("Young", "Middle", "Old")) +
  labs(y = "Pr. of Dislike", x = NULL) +
  theme_bw() +
  theme(strip.background = element_blank(), strip.text = element_text(face = "plain"))
save_fig(p3, "figure3.png", 6.5, 5)

cat("Figures written to output/figures/\n")
