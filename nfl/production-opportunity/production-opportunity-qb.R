# tidyverse
library(tidyverse)

# baseline
library(baseliner)

# nfl data
library(nflverse)

# other
library(here)
library(jsonlite)
library(ggrepel)

# source shared utilities
source(here("nfl", "shared", "nfl-utility.R"))

# global variables
style <- read_json(system.file("style.json", package = "baseliner"))
color <- read_json(system.file("color.json", package = "baseliner"))

current_week <- 0
season <- most_recent_season()
summary_level <- c("season", "week")

showtext::showtext_auto()
showtext::showtext_opts(dpi = 600)

# load team data
teams <- load_teams() %>%
  select(team = team_abbr, team_pri = team_color, team_sec = team_color2)

# load base nflverse stats
qb_stats <- calculate_stats(
  seasons = season,
  summary_level = summary_level[1],
  stat_type = "player",
  season_type = "REG"
) %>%
  filter(position == "QB") %>%
  transmute(
    id = player_id,
    name = player_display_name,
    short = player_name,
    pos = position,
    team = recent_team,
    gp = games,
    att = attempts,
    cmp = completions,
    yds = passing_yards,
    tds = passing_tds,
    int = passing_interceptions,
    sacks = sacks_suffered,
    sack_yds = sack_yards_lost,
    sack_fum = sack_fumbles,
    sack_fum_lost = sack_fumbles_lost,
    pass_ay = passing_air_yards,
    pass_yac = passing_yards_after_catch,
    pass_fd = passing_first_downs,
    pass_epa = passing_epa,
    cpoe = passing_cpoe,
    rush_att = carries,
    rush_yds = rushing_yards,
    rush_tds = rushing_tds,
    rush_fum = rushing_fumbles,
    rush_fum_lost = rushing_fumbles_lost,
    rush_epa = rushing_epa,
    fpts = fantasy_points_ppr + 2 * tds,
    fppg = fpts / gp,
    epa = pass_epa + rush_epa
  ) %>%
  arrange(desc(fpts)) %>%
  mutate(rank = seq_len(nrow(.))) %>%
  slice(1:35)

# calculate number of plays
plays <- load_pbp(seasons = season) %>%
  filter(play == 1) %>%
  filter(qb_dropback == 1 | play_type == "run") %>%
  mutate(id = coalesce(passer_id, rusher_id)) %>%
  inner_join(
    qb_stats %>% select(id),
    by = "id"
  ) %>%
  group_by(id) %>%
  summarize(plays = n())

# merge base stats and number of plays with team info
stats <- qb_stats %>%
  left_join(
    teams,
    by = "team"
  ) %>%
  left_join(
    plays,
    by = "id"
  ) %>%
  mutate(epa_play = epa / plays)

# set dynamic axis limits
cpoe_epa_lims <- list(
  xlim = c(min(stats$cpoe) - 0.01, max(stats$cpoe) + 0.01),
  ylim = c(min(stats$epa_play) - 0.01, max(stats$epa_play) + 0.01)
)

# plot epa (y-axis) by cpoe (x-axis)
cpoe_epa <- ggplot(
  stats,
  aes(x = cpoe, y = epa_play)
) +
  geom_point(
    aes(
      fill = ifelse(team %in% flip_color, team_sec, team_pri),
      color = ifelse(team %in% flip_color, team_pri, team_sec)
    ),
    shape = 21,
    size = 2,
    stroke = 1
  ) +
  scale_fill_identity() +
  scale_color_identity() +
  scale_size_continuous(range = c(2, 10)) +
  geom_text_repel(
    aes(label = short),
    family = style$chart$font$family$label,
    color = style$chart$font$color$label,
    size = 2.5,
    point.padding = 0.5,
    box.padding = 0.25,
    max.overlaps = Inf
  ) +
  scale_x_continuous(
    limits = cpoe_epa_lims$xlim
  ) +
  scale_y_continuous(
    limits = cpoe_epa_lims$ylim,
    breaks = seq(-0.2, 0.2, by = 0.1)
  ) +
  geom_vline(
    xintercept = 0,
    color = color$london[[3]]
  ) +
  annotate(
    "segment",
    x = cpoe_epa_lims$xlim[1] + 0.01,
    xend = cpoe_epa_lims$xlim[2] - 0.01,
    y = median(stats$epa_play, na.rm = TRUE),
    yend = median(stats$epa_play, na.rm = TRUE),
    color = color$london[[3]],
    linewidth = 0.5,
    linetype = "dashed",
    alpha = 0.6
  ) +
  labs(
    title = "Expected Points from Unexpected Throws",
    subtitle = "Quarterback Production in 2024",
    caption = "Charting: Lukas Nesheim (data via nflverse)",
    x = "Completion Percentage over Expected",
    y = "EPA per Play"
  ) +
  theme_baseline_gg()

# save the plot with logo
ggsave_with_logo(cpoe_epa, "nfl/production-opportunity/cpoe_epa.png")