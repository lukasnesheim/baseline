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

# data wrangling (TODO: needs to be replaced with in-season code)
data <- tibble(
  rank = paste0(1:10, "."),
  club = c("Rebranded", "Silver Foxes", "Nabers Think I'm Selling Dope", "Summerhouse FC", "Shiesty Joe", "The Gabagools", "D. Jonestown Massacre", "Super ARich Kids", "Law of the Land", "Ash Can't Ketchum"), # nolint
  w = c(10, 9, 8, 8, 8, 7, 7, 6, 5, 2),
  l = c(4, 5, 6, 6, 6, 7, 7, 8, 9, 12),
  pf = c(2209.44, 1986.58, 2082.58, 2076.02, 1852.96, 2070.46, 2008.46, 1908.92, 1864.58, 1514.70), # nolint
  pa = c(1978.64, 1875.99, 1983.96, 1946.12, 1693.60, 2071.80, 1988.42, 2062.38, 1991.80, 1981.86), # nolint
  mpf = rep("-", 10),
  move = c("", "", "", "", "<sup><span style='color: #3f8f29;'>+3</span></sup>", "<sup><span style='color: #bf1029;'>-1</span></sup>", "<sup><span style='color: #bf1029;'>-1</span></sup>", "<sup><span style='color: #bf1029;'>-1</span></sup>", "", "") # nolint
) %>%
  mutate(club = paste0(club, move), ortg = pf / (current_week - 1), drtg = pa / (current_week - 1)) %>% # nolint
  select(-move, -pf, -pa, -mpf, mpf)

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
    "w" ~ "WIN",
    "l" ~ "LOSS",
    "ortg" ~ "OFF. RTG",
    "drtg" ~ "DEF. RTG",
    "mpf" ~ "MAX PTS"
  ) %>%
  fmt_number(
    columns = ortg:mpf,
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
    locations = cells_body(columns = w:mpf),
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
  ) %>%
  gt_save_crop(
    file = paste0("nfl/fantasy-league-table/league_table.png"),
    bg = color$background,
    whitespace = 20,
    zoom = 4
  )

table_image <- magick::image_read("nfl/fantasy-league-table/league-table.png")
final_image <- add_logo_gt(table_image, width = 1180, height = 1400)

magick::image_write(
  final_image,
  "nfl/fantasy-league-table/league_table.png",
  format = "png"
)