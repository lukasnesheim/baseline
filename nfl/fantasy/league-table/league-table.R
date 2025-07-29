# tidyverse
library(tidyverse)

# baseline
library(baseliner)

# other
library(gt)
library(gtUtils)
library(jsonlite)
library(scales)

# global variables
style <- read_json(system.file("style.json", package = "baseliner"))
color <- read_json(system.file("color.json", package = "baseliner"))

season <- 2024
current_week <- 15

data <- read_csv("podiums.csv") %>%
  mutate(
    move = c("", "", "", "", "<sup><span style='color: #3f8f29;'>+3</span></sup>", "<sup><span style='color: #bf1029;'>-1</span></sup>", "<sup><span style='color: #bf1029;'>-1</span></sup>", "<sup><span style='color: #bf1029;'>-1</span></sup>", "", ""), # nolint
    club = paste0(club_name, move),
    ortg = pf / (current_week - 1),
    drtg = pa / (current_week - 1)
  ) %>%
  select(rank, club, win, loss, ortg, drtg, max, -move, -club_name, -pf, -pa)

min_ortg <- min(data$ortg)
max_ortg <- max(data$ortg)

min_drtg <- min(data$drtg)
max_drtg <- max(data$drtg)

# league table
table <- data %>%
  gt() %>%
  theme_baseline_gt() %>%
  tab_header(
    title = "League Table",
    subtitle = paste0("Week ", current_week, " Standings")
  ) %>%
  tab_source_note(
    source_note = "Table: Lukas Nesheim"
  ) %>%
  cols_label(
    "rank" ~ "",
    "club" ~ "CLUB",
    "win" ~ "WIN",
    "loss" ~ "LOSS",
    "ortg" ~ "OFF. RTG",
    "drtg" ~ "DEF. RTG",
    "max" ~ "MAX PTS"
  ) %>%
  fmt_number(
    columns = ortg:max,
    decimals = 2,
    use_seps = FALSE
  ) %>%
  tab_style(
    locations = cells_column_labels(columns = club),
    style = cell_text(align = "left")
  ) %>%
  tab_style(
    locations = cells_body(columns = rank:club),
    style = cell_text(weight = style$table$font$weight$label)
  ) %>%
  tab_style(
    locations = cells_body(columns = win:max),
    style = cell_text(align = "center")
  ) %>%
  tab_style(
    locations = cells_body(rows = 6),
    style = cell_borders(
      sides = "bottom",
      color = color$london[[5]],
      weight = px(0.5),
      style = "solid"
    )
  ) %>%
  fmt_markdown(columns = club) %>%
  data_color(
    columns = ortg,
    fn = col_numeric(
      domain = c(min_ortg, max_ortg),
      palette = c(color$london[[6]], color$london[[3]])
    ),
    alpha = 0.7
  ) %>%
  data_color(
    columns = drtg,
    fn = col_numeric(
      domain = c(min_drtg, max_drtg),
      palette = c(color$london[[3]], color$london[[6]])
    ),
    alpha = 0.7
  )

# save the table with logo
gtsave_with_logo(table, "league_table.png")