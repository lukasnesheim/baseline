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

season <- most_recent_season()

# load team data
teams <- load_teams()

# load base nflverse stats
rec_stats <- calculate_stats(
  seasons = season,
  summary_level = "season",
  stat_type = "player",
  season_type = "REG"
) %>%
  transmute(
    id = player_id,
    name = player_display_name,
    short = player_name,
    pos = position,
    team = recent_team,
    gp = games,
    tgt = targets,
    rec = receptions,
    td = receiving_tds,
    fum = receiving_fumbles,
    iay = receiving_air_yards,
    yac = receiving_yards_after_catch,
    fd = receiving_first_downs,
    racr,
    tgt_share = target_share,
    ay_share = air_yards_share,
    wopr,
    wopr_scaled = wopr * (17 / gp),
    fpts = fantasy_points_ppr + 0.5 * fd,
    fppg = fpts / gp,
    fppt = fpts / tgt,
    fppr = fpts / rec
  ) %>%
  group_by(pos) %>%
  arrange(desc(fpts), .by_group = TRUE) %>%
  mutate(rank = row_number()) %>%
  ungroup()

# load play-by-play stats
pbp_stats <- load_pbp(season) %>%
  filter(complete_pass == 1) %>%
  filter(air_yards < yardline_100) %>%
  filter(!is.na(xyac_epa)) %>%
  group_by(receiver_id) %>%
  summarize(
    epa_oe = mean(yac_epa - xyac_epa),
    xfd = mean(xyac_fd),
    fd_oe = mean(first_down - xyac_fd),
    yac_epa = sum(yac_epa),
    xyac = sum(xyac_mean_yardage),
    xyac_epa = sum(xyac_epa)
  ) %>%
  ungroup() %>%
  select(id = receiver_id, everything())

# merge base stats and play-by-play stats
stats <- pbp_stats %>%
  left_join(
    rec_stats,
    by = "id"
  ) %>%
  left_join(
    teams %>%
      select(
        team = team_abbr,
        team_pri = team_color,
        team_sec = team_color2
      ),
    by = "team"
  ) %>%
  filter(pos == "WR") %>%
  filter(rank <= 50)

# set dynamic axis limits
wopr_fppt_lims <- list(
  xlim = c(min(stats$wopr_scaled) - 0.01, max(stats$wopr_scaled) + 0.01),
  ylim = c(min(stats$fppt) - 0.01, max(stats$fppt) + 0.01)
)

# plot production (y-axis) by weighted opportunity (x-axis)
wopr_fppt <- ggplot(
  stats,
  aes(x = wopr_scaled, y = fppt)
) +
  geom_point(
    aes(
      fill = ifelse(team %in% flip_color, team_sec, team_pri),
      color = ifelse(team %in% flip_color, team_pri, team_sec)
    ),
    shape = 21,
    size = 1.5,
    stroke = 0.75
  ) +
  scale_fill_identity() +
  scale_color_identity() +
  geom_text_repel(
    aes(label = short),
    family = "montserrat_semibold",
    color = style$chart$font$color$body,
    size = 2.25,
    point.padding = 0.4,
    box.padding = 0.25,
    max.overlaps = Inf
  ) +
  scale_x_continuous(
    limits = wopr_fppt_lims$xlim,
    breaks = seq(0.4, 0.8, by = 0.2)
  ) +
  scale_y_continuous(
    limits = wopr_fppt_lims$ylim,
    breaks = seq(1.5, 2.5, by = 0.5)
  ) +
  annotate(
    "segment",
    x = wopr_fppt_lims$xlim[1] + 0.01,
    xend = wopr_fppt_lims$xlim[2] - 0.01,
    y = mean(stats$fppt, na.rm = TRUE),
    yend = mean(stats$fppt, na.rm = TRUE),
    color = color$london[[5]],
    linewidth = 0.5,
    linetype = "dashed"
  ) +
  annotate(
    "segment",
    x = median(stats$wopr_scaled, na.rm = TRUE),
    xend = median(stats$wopr_scaled, na.rm = TRUE),
    y = wopr_fppt_lims$ylim[1] + 0.01,
    yend = wopr_fppt_lims$ylim[2] - 0.01,
    color = color$london[[5]],
    linewidth = 0.5,
    linetype = "dashed"
  ) +
  labs(
    title = "Production Function",
    subtitle = "receiving production by weighted opportunity",
    caption = "Charting: Lukas Nesheim (data via nflverse)",
    x = "Weighted Opportunity",
    y = "Fantasy Points per Target"
  ) +
  theme_baseline_gg()

wopr_fppt <- wopr_fppt %>%
  add_logo_gg()

showtext::showtext_auto()

# save plot
ggsave(
  "nfl/production-opportunity/wopr_fppt.png",
  plot = wopr_fppt,
  width = 6,
  height = 6,
  dpi = 600,
  units = "in"
)