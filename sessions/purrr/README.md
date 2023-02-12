purrr
================
Jake Riley - 1/14/2022

## Agenda

-   [slides](https://rjake.github.io/analytics-deep-dive/sessions/purrr/README.html#1)
    \|
    [code](https://www.github.com/rjake/analytics-deep-dive/blob/main/sessions/purrr/README.md)

-   Features of `purrr` - **what & how**

-   In practice - **when & why**

-   Other goodies

------------------------------------------------------------------------

## What is `map()`

``` r
library(tidyverse)
```

`map()` comes from `purrr` and most closely relates to `lapply()`

``` r
lapply(X = 1:2, FUN = rnorm, n = 3)
map(.x = 1:2, .f = rnorm, n = 3)
```

but `purrr` allows twiddle / tilde notation

``` r
lapply(X = 1:2, FUN = function(x) rnorm(x, n = 3))
map(.x = 1:2,   .f = ~rnorm(.x, n = 3))
#                       ~fn(.x, ...)
```

------------------------------------------------------------------------

## twiddle / tilde notation

this notation is used throughout the tidyverse

``` r
# subset data in ggplot
ggplot(mpg, aes(cty, hwy)) +
  geom_point() +
  geom_point(
    data = ~head(.x, 10),
    size = 4, color = "blue"
  )

# convert to km and grab mean
mpg |>
  summarise(
    across(
      .cols = c(cty, hwy), 
      .fns = ~mean(.x * 1.6)
    )
  )
```

------------------------------------------------------------------------

## There are many Variants

More than one argument

-   `map2()` - .x, .y
-   `imap()` - use indexes ..1, ..2, etc
-   `pmap()` - pass a list or tibble with columns as argument names

Vectors (lapply + unlist)

-   `map_chr()`, `map_dbl()`, `map_int()`, etc – return a vector (use
    `map_dbl()` for dates)

Do an action

-   `walk()`, `walk2()`, `iwalk()`, `pwalk()` – doesn’t return anything,
    ex. save a series of plots
-   `dplyr` has `group_walk()` and others

Iterate and bind to a data frame

-   `map_dfr()`, `map_dfc()` - will bind rows / columns to a table in
    each iteration

------------------------------------------------------------------------

## How to replace loops

Loops look like this

``` r
for ( some_constant_name    in        some_vector   ) {
    # made here only     not %in%  existing vector/list
  do this
}
```

``` r
for (i in 1:3) {
  print(paste("This is line", i))
}
```

    ## [1] "This is line 1"
    ## [1] "This is line 2"
    ## [1] "This is line 3"

------------------------------------------------------------------------

## Loops can have several steps

``` r
for (dept in unique(cohort$department_name)) {
  df <- 
    cohort |>
    filter(department_name == dept)
  
  title <- paste("There were", nrow(df), "visits in", dept)
  
  ggplot(df, aes(month)) +
    geom_bar() +
    labs(title = title)
}
```

------------------------------------------------------------------------

## Why I don’t like loops

Re-running a loop can produce unwanted effects.

If I accidentally re-run this for-loop without re-running `df <-` it
will re-append more data to the data frame and duplcate my data

``` r
csv_list <- list.files(pattern = "csv$")
df <- data.frame()

for (i in 1:length(csv_list)) {
  x <- read_csv(csv_list[i], na = "NULL")
  df <- bind_rows(df, x)
}
```

------------------------------------------------------------------------

## How to replace loops with `purrr`

If we take our earlier example:

``` r
csv_list <- list.files(pattern = "csv$")
df <- data.frame()

for (i in 1:length(csv_list)) {
  x <- read_csv(csv_list[i], na = "NULL")
  df <- bind_rows(df, x)
}
```

There is a `map_*()` variant that does it all at once, read each csv and
bind the rows.

There is no need for the `csv_list` object and no need to set up an
empty data frame `df`

``` r
df <- 
  map_dfr(
    .x = list.files(pattern = "csv$"),
    .f = read_csv,
    na = "NULL"
  )
```

------------------------------------------------------------------------

## Break loops into functions + iteration

If you’ve written loops like this, you’ve done the heavy lifting

``` r
for (file in csv_list) {
  x <-
    read_csv(file, na = NULL) |> 
    head(3) |> 
    mutate_if(is.numeric, floor) |>
    mutate(id = row_number())

  df <- bind_rows(df, x)
}
```

You can put the body of the loop into the body of a function. `file` now
becomes the argument of the function.

``` r
simplify_data <- function(file) {
  read_csv(file, na = NULL) |> 
    head(3) |> 
    mutate_if(is.numeric, floor) |>
    mutate(id = row_number())
}
```

------------------------------------------------------------------------

## How it simplifies

With the new function, you can run try out different inputs to check
that it works

``` r
simplify_data(file = "my_data.csv")
```

Now the loop is simpler

``` r
for (file in csv_list) {
  x <- simplify_data(file)
  df <- bind_rows(df, x)
}
```

or better yet can be completely eliminated with `map_dfr()`

``` r
df <-
  map_dfr(
    csv_list,
    simplify_data
  )
```

------------------------------------------------------------------------

## Errors

`purrr` also lets you catch errors with out the stopping with
`possibly()`

``` r
df <- 
  map_dfr(
    c("123", "my_data.csv", "456"),
    possibly(simplify_data, otherwise = NULL)
  )
```

    [1] "123"
    [1] "my_data.csv"
    [1] "456"
    Warning messages:
    1: In file(file, "rt") : cannot open file '123': No such file or directory
    2: In file(file, "rt") : cannot open file '456': No such file or directory

I can now troubleshoot one at a time

``` r
simplify_data(file = "123")
simplify_data(file = "my_data.csv")
```

------------------------------------------------------------------------

class: center, middle

# Putting it all together

------------------------------------------------------------------------

## Create one row per date

You might use `map2()` to create a vector of dates, this creates a list
column `days`

``` r
df <- 
  tibble(
    hospital_admit_date = Sys.Date() + 1:2,
    hospital_discharge_date = hospital_admit_date + 3:4
  ) |> 
  mutate(
    days = 
      map2(
        .x = hospital_admit_date, 
        .y = hospital_discharge_date, 
        .f = seq, 
        by = "1 day"
      )
  ) |> 
  print()
```

    ## # A tibble: 2 x 3
    ##   hospital_admit_date hospital_discharge_date days      
    ##   <date>              <date>                  <list>    
    ## 1 2022-03-10          2022-03-13              <date [4]>
    ## 2 2022-03-11          2022-03-15              <date [5]>

------------------------------------------------------------------------

## Unnest the values

Now use `unnest_longer()` to create one row per date (`unnest()` works
also)

``` r
df |> 
  unnest_longer(days)
```

    ## # A tibble: 9 x 3
    ##   hospital_admit_date hospital_discharge_date days      
    ##   <date>              <date>                  <date>    
    ## 1 2022-03-10          2022-03-13              2022-03-10
    ## 2 2022-03-10          2022-03-13              2022-03-11
    ## 3 2022-03-10          2022-03-13              2022-03-12
    ## 4 2022-03-10          2022-03-13              2022-03-13
    ## 5 2022-03-11          2022-03-15              2022-03-11
    ## 6 2022-03-11          2022-03-15              2022-03-12
    ## 7 2022-03-11          2022-03-15              2022-03-13
    ## 8 2022-03-11          2022-03-15              2022-03-14
    ## 9 2022-03-11          2022-03-15              2022-03-15

------------------------------------------------------------------------

## Nested JSON

``` r
df <- 
  tibble(
    all_procedures = '[{
      "cpt": "1234.5",
      "proc_id": "2022",
      "description": "spinal fusion",
      "laterality": "n/a",
      "panel_number": "1",
      "service": "Orthopedic",
      "surgeon_provider_id": "5555",
      "surgeon": "Jake Riley"
    }]'
  ) |> 
  mutate(all_procedures = map(all_procedures, jsonlite::fromJSON)) |> 
  print()
```

    ## # A tibble: 1 x 1
    ##   all_procedures
    ##   <list>        
    ## 1 <df [1 x 8]>

------------------------------------------------------------------------

## Unnested JSON

You can use `unnest()` here but `unnest_wider()` is more explicit

``` r
df |> 
  unnest_wider(all_procedures)
```

    ## # A tibble: 1 x 8
    ##   cpt    proc_id description   laterality panel_number service  surgeon_provide~
    ##   <chr>  <chr>   <chr>         <chr>      <chr>        <chr>    <chr>           
    ## 1 1234.5 2022    spinal fusion n/a        1            Orthope~ 5555            
    ## # ... with 1 more variable: surgeon <chr>

## Iterating with widgets

When using widgets like `plotly` or DT use `walk( )` then `tagList( )`

``` r
df_list <- 
  mpg |>
  group_split(class) |> # returns a list
  group_walk(DT::datatable)

htmltools::tagList(dt_tables)
```

------------------------------------------------------------------------

## Iterating with static plots

for `ggplot2` use `walk(..., print)`

``` r
mpg |> 
  head(20) |> 
  group_by(class) |> 
  group_walk(
    ~{
      p <- 
        ggplot(x, aes(cty, hwy)) +
        labs(title = .y[[1]])
      
      print(p)
    }
  )
```

When `group_by()` is used in `group_map()` or `group_walk()` you can
find it’s group name with `.y[[1]]`.

See [this SO post](https://stackoverflow.com/a/54755352/4650934) for
more info about group titles

------------------------------------------------------------------------

## `keep()` and `discard()`

retain values with `keep()`

``` r
sentences[1:5] |> 
  keep(str_detect, "^The")
```

    ## [1] "The birch canoe slid on the smooth planks."
    ## [2] "These days a chicken leg is a rare dish."

remove values with `discard()`

``` r
sentences[1:5] |> 
  discard(str_detect, "^The")
```

    ## [1] "Glue the sheet to the dark blue background."
    ## [2] "It's easy to tell the depth of a well."     
    ## [3] "Rice is often served in round bowls."

------------------------------------------------------------------------

## `keep()` and `discard()`

you can also use the twiddle with these

``` r
sentences[1:5] |> 
  keep(~nchar(.x) < 40)
```

    ## [1] "It's easy to tell the depth of a well."
    ## [2] "Rice is often served in round bowls."

so much easier to read

``` r
cohort |> 
  pull(department_name) |>
  discard(str_detect, "BGR") |>
  sort()
```

compare this with

``` r
sort(cohort$department_name[!grepl("BGR", cohort$department_name)])

# or
sort(grep("BGR", cohort$department_name, value = TRUE, invert = TRUE))
```

------------------------------------------------------------------------

## `pluck()`

`pluck()` will grab the nth element. I use it often with `json`. It can
use numeric positions or names

``` r
my_list <- 
  list(
    list(x = "abc", name = "Jake"), 
    list(name = "Cody")
  )
```

``` r
# by name
my_list |> 
  map_chr(pluck, "name")
```

    ## [1] "Jake" "Cody"

``` r
#by index (1 = first)
my_list |> 
  map_chr(pluck, 1)
```

    ## [1] "abc"  "Cody"

------------------------------------------------------------------------

## `map2()`

`map2( )` works with 2 inputs of the same length

``` r
map2(
  .x = c("a", "b"),
  .y = c(3, 4), 
  .f = rep    # ex: rep(x = "a", times = 3)
)
```

    ## [[1]]
    ## [1] "a" "a" "a"
    ## 
    ## [[2]]
    ## [1] "b" "b" "b" "b"

------------------------------------------------------------------------

## Simplifying

Since `map()` functions return a list, you need to keep using `map()`
functions until it is no longer a list object

``` r
map2(1:2, 8:9, ~.x/.y) |> # list
  map(mean) |>            # list
  map(round, 3) |>        # list
  map_dbl(pluck)          # vector
```

you can often convert to a vector with the `map_*()` helpers

``` r
map2(1:2, 8:9, ~.x/.y) |> # list
  map_dbl(mean) |>        # vector
  round(3)                # vector
```
