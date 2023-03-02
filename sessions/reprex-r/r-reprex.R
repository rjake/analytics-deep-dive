library(rocqi)
library(tidyverse)


# dates
  tibble(
    date_requested = Sys.time() + (1:6 * 60),
    surgery_date = Sys.Date() + (1:6 * 7)
  )
  # I like starting with a tibble() instead of data.frame() since you can
  # use columns made at the time

# character data
  tibble(
    surgeon = rep(LETTERS[1:3], each = 2),
    location = rep(LETTERS[1:3], times = 2),
    op_note = sentences[1:6] # comes from stringr
  )


# regex isn't working ----
  tibble(
    note_text = sentences[1:5],
    last_word = str_extract(note_text, "\\w+\\.$") # don't want "."
  )

# need to fill in missing values ----
  tibble(
    x = c(1, NA, 2),
    y = c(NA, "a", NA)
  )

  surgeries |>
    head() |>
    select(1:5) |>
    mutate_all(
      ~ifelse(row_number() %in% c(2, 4), NA, .x)
    )


# need to expand dates between ----
  surgeries |>
    select(log_id, surgery_date, hospital_discharge_date)


  tibble(
    start = Sys.Date() + 1:5,
    end = start + 1:5
  )

# spc plot not working - see ?spc for examples ----
  spc(
    data = sepsis,
    x = hospital_admit_date,
    y = abx_30_min_ind,
    chart = "p",
    part_dates = "2022-06-01"
  )


# distribution ----
  tibble(
    # normal age distribution
    age = rnorm(5, mean = 10, sd = 3),
    # skewed LOS distribution  hist(rbeta(2000, 2, 10) * 14)
    los_days = (rbeta(n = 5, shape1 = 2, shape2 = 10) * 14)
  )

# use set.seed() ----
  set.seed(2022)
  rnorm(5, 10, 3)
  rnorm(5, 10, 3)

  set.seed(2022)
  rnorm(5, 10, 3) # NOTE: needs to be right before random fn or in the right order


# reprex ----
  # copy to clipbord then use reprex::reprex_slack() in console
  # or highlight and use add-in
  my_table |>
    mutate(x = Sys.Date)


# dput & structure ----
  your_data <- head(ToothGrowth, 3)
  dput(your_data)

  my_data <-
    structure(
      list(
        len = c(4.2, 11.5, 7.3),
        supp = structure(c(2L, 2L, 2L), .Label = c("OJ", "VC"), class = "factor"),
        dose = c(0.5, 0.5, 0.5)
      ),
      row.names = c(NA, 3L),
      class = "data.frame"
    )

  identical(your_data, my_data)

  dput(raw_data) |> clipr::write_clip() #datapasta paste tribble


# just select the colums you need and a minimal # of rows
  mpg[1:5, 1:3]

  head(mpg, 1) |> dput()
    mutate_if(is.character, toupper)


# built-in data ----
  # see all data sets with
    data()
    data(package = "rocqi")

  # base R
    iris
    ToothGrowth
    quakes # mapping

  # ggplot2 - https://ggplot2.tidyverse.org/reference/index.html#section-data
    mpg       # all 3 good for plotting, mix of categorical & numeric
    diamonds
    msleep
    map_data # map polygons, https://ggplot2.tidyverse.org/reference/map_data.html

  # tidyr - https://tidyr.tidyverse.org/reference/index.html#data
    us_rent_income  # pivoting
    population      # longitudinal

  # dplyr: https://dplyr.tidyverse.org/reference/index.html#section-data
    storms    # longitudinal
    starwars  # lists, missingness, comma separated values

  # sf
    st_read(system.file("shape/nc.shp", package="sf")) # comes with install


  # rocqi
    ed_fractures
    surgeries
