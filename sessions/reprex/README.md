reprex
================
Jake Riley - 2/4/2022

## Agenda

-   [slides](https://rjake.github.io/analytics-deep-dive/sessions/reprex/README.html#1)
    \|
    [code](https://www.github.com/rjake/analytics-deep-dive/blob/main/sessions/reprex/README.md)

-   Examples in R

-   Examples in SQL

-   Recap

------------------------------------------------------------------------

## Getting help in R

**Pointers**

-   use built-in datasets

-   `dput()` + `datapasta` to recreate data

-   `set.seed()` for random-generating functions

-   always include libraries, the reprex package can help

<br>

The following examples will use these libraries

``` r
library(rocqi)
library(tidyverse)
```

------------------------------------------------------------------------

## Use built-in dates

Use `Sys.time()` and `Sys.Date()`

``` r
tibble(
  date_requested = Sys.time() + (1:6 * 60),
  surgery_date = Sys.Date() + (1:6 * 7),
  date_dist = surgery_date - as.Date(date_requested)
)
```

    ## # A tibble: 6 x 3
    ##   date_requested      surgery_date date_dist
    ##   <dttm>              <date>       <drtn>   
    ## 1 2022-03-09 18:08:41 2022-03-16    7 days  
    ## 2 2022-03-09 18:09:41 2022-03-23   14 days  
    ## 3 2022-03-09 18:10:41 2022-03-30   21 days  
    ## 4 2022-03-09 18:11:41 2022-04-06   28 days  
    ## 5 2022-03-09 18:12:41 2022-04-13   35 days  
    ## 6 2022-03-09 18:13:41 2022-04-20   42 days

I like starting with a `tibble()` instead of `data.frame()` since you
can use columns made at the time

------------------------------------------------------------------------

## Use built-in `letters`

``` r
tibble(
  surgeon = rep(LETTERS[1:3], each = 2),
  location = rep(letters[1:3], times = 2),
  op_note = sentences[1:6] # comes from stringr
)
```

    ## # A tibble: 6 x 3
    ##   surgeon location op_note                                    
    ##   <chr>   <chr>    <chr>                                      
    ## 1 A       a        The birch canoe slid on the smooth planks. 
    ## 2 A       b        Glue the sheet to the dark blue background.
    ## 3 B       c        It's easy to tell the depth of a well.     
    ## 4 B       a        These days a chicken leg is a rare dish.   
    ## 5 C       b        Rice is often served in round bowls.       
    ## 6 C       c        The juice of lemons makes fine punch.

------------------------------------------------------------------------

## Use `sentences` for regex

This comes from `stringr`

``` r
tibble(
  note_text = sentences[1:5],
  last_word = str_extract(note_text, "\\w+\\.$") # don't want "."
)
```

    ## # A tibble: 5 x 2
    ##   note_text                                   last_word  
    ##   <chr>                                       <chr>      
    ## 1 The birch canoe slid on the smooth planks.  planks.    
    ## 2 Glue the sheet to the dark blue background. background.
    ## 3 It's easy to tell the depth of a well.      well.      
    ## 4 These days a chicken leg is a rare dish.    dish.      
    ## 5 Rice is often served in round bowls.        bowls.

------------------------------------------------------------------------

## Mock up missing values from scratch

``` r
tibble(
  x = c(1, NA, 2),
  y = c(NA, "a", NA)
)
```

    ## # A tibble: 3 x 2
    ##       x y    
    ##   <dbl> <chr>
    ## 1     1 <NA> 
    ## 2    NA a    
    ## 3     2 <NA>

------------------------------------------------------------------------

## Mock up missing values using existing data

``` r
head(mtcars) |>
  select(1:5) |>
  mutate_all(# make NA if rows are in 2 or 4
    ~ifelse(row_number() %in% c(2, 4), NA, .x)
  )
```

    ##                    mpg cyl disp  hp drat
    ## Mazda RX4         21.0   6  160 110 3.90
    ## Mazda RX4 Wag       NA  NA   NA  NA   NA
    ## Datsun 710        22.8   4  108  93 3.85
    ## Hornet 4 Drive      NA  NA   NA  NA   NA
    ## Hornet Sportabout 18.7   8  360 175 3.15
    ## Valiant           18.1   6  225 105 2.76

------------------------------------------------------------------------

## Use `?fn` to get sharable examples

If you need help with an spc chart, look in the help page

Using `?spc` gives this example:

``` r
spc(
  data = sepsis,
  x = hospital_admit_date,
  y = abx_30_min_ind,
  chart = "p",
  part_dates = "2022-06-01"
)
```

------------------------------------------------------------------------

## Use built-in distribution functions

.pull-left\[ `rnorm()` gives a normal distribution\]

.pull-right\[ `rbeta()` gives a skewed distribution\]

------------------------------------------------------------------------

## Use built-in distribution functions

You can use this to mock up your data

``` r
tibble(
  # normal age distribution
  age = rnorm(n = 6, mean = 10, sd = 3),
  # skewed LOS distribution up to 2 weeks
  los_days = rbeta(n = 6, shape1 = 2, shape2 = 10) * 14
            # ---------------- 0 to 1 ------------ x 14 days
)
```

    ## # A tibble: 6 x 2
    ##     age los_days
    ##   <dbl>    <dbl>
    ## 1 12.9     1.59 
    ## 2  8.26    0.574
    ## 3  8.17    2.71 
    ## 4 10.0     1.22 
    ## 5  6.13    0.424
    ## 6 13.5     1.49

------------------------------------------------------------------------

## Use `set.seed()` for reproducible randomness

Without a “seed”, random number functions like `rnorm()` will give
different results each time

``` r
rnorm(5)
```

    ## [1] -0.2915631 -0.1060309 -0.4512201 -0.3298362  0.2148399

``` r
rnorm(5)
```

    ## [1]  1.8513452 -0.6200044  0.3322539  0.5725519 -0.0437465

------------------------------------------------------------------------

## Use `set.seed()` for reproducible randomness

Using `set.seed()` will make sure that the random number generator
starts at the same point each time. Note: it needs to be right before
random fn or in the right order

``` r
set.seed(2022) 
rnorm(5)
```

    ## [1]  0.9001420 -1.1733458 -0.8974854 -1.4445014 -0.3310136

``` r
set.seed(2022) 
rnorm(5)
```

    ## [1]  0.9001420 -1.1733458 -0.8974854 -1.4445014 -0.3310136

------------------------------------------------------------------------

## The `reprex` package

Copy to code to your clipboard then use `reprex::reprex_slack()` in
console or highlight code in source pane and use `reprex` add-in

``` r
mpg |>
  mutate(x = Sys.Date)
```

``` r
mpg |>
  mutate(x = Sys.Date)
#> Error in mutate(mpg, x = Sys.Date): could not find function "mutate"
```

------------------------------------------------------------------------

## `dput()`

Use `dput()` to “export” the structure of your data.

``` r
your_data <- head(ToothGrowth, 3)
dput(your_data)
```

    ## structure(list(len = c(4.2, 11.5, 7.3), supp = structure(c(2L, 
    ## 2L, 2L), .Label = c("OJ", "VC"), class = "factor"), dose = c(0.5, 
    ## 0.5, 0.5)), row.names = c(NA, 3L), class = "data.frame")

------------------------------------------------------------------------

## `structure()`

Assign the results of `dput()` to a new object

``` r
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
```

    ## [1] TRUE

------------------------------------------------------------------------

## `clipr` and `datapasta`

Copy data to your clipboard

``` r
your_data |> clipr::write_clip() 
```

Use add-ins: `datapasta` \> `paste as tribble`. Also works with data on
your clipboard from excel

``` r
tibble::tribble(
  ~len, ~supp, ~dose,
  4.2, "VC", 0.5,
  11.5, "VC", 0.5,
  7.3, "VC", 0.5
)
```

    ## # A tibble: 3 x 3
    ##     len supp   dose
    ##   <dbl> <chr> <dbl>
    ## 1   4.2 VC      0.5
    ## 2  11.5 VC      0.5
    ## 3   7.3 VC      0.5

------------------------------------------------------------------------

## Keep things minimal

Just select the colums you need and a minimal \# of rows

``` r
#   row  col
mpg[1:3, 1:2]
```

    ## # A tibble: 3 x 2
    ##   manufacturer model
    ##   <chr>        <chr>
    ## 1 audi         a4   
    ## 2 audi         a4   
    ## 3 audi         a4

A row of 1 is often enough

``` r
head(mpg, 1) |> #dput()
  mutate_if(is.character, toupper)
```

    ## # A tibble: 1 x 11
    ##   manufacturer model displ  year   cyl trans    drv     cty   hwy fl    class  
    ##   <chr>        <chr> <dbl> <int> <int> <chr>    <chr> <int> <int> <chr> <chr>  
    ## 1 AUDI         A4      1.8  1999     4 AUTO(L5) F        18    29 P     COMPACT

------------------------------------------------------------------------

## Built-in data

-   see all data sets with
    -   `data()`
    -   `data(package = "rocqi")`
-   base R
    -   `iris`
    -   `ToothGrowth`
    -   `quakes` - mapping
-   [`ggplot2`](https://ggplot2.tidyverse.org/reference/index.html#section-data) -
    all 3 good for plotting, mix of categorical & numeric
    -   `mpg`
    -   `diamonds`
    -   `msleep`
    -   `map_data` - map polygons ([see
        vignette](https://ggplot2.tidyverse.org/reference/map_data.html))

------------------------------------------------------------------------

## Built-in data

-   [`tidyr`](https://tidyr.tidyverse.org/reference/index.html#data)
    -   `us_rent_income` - pivoting
    -   `population` - longitudinal
-   [`dplyr`](https://dplyr.tidyverse.org/reference/index.html#section-data)
    -   `storms` - longitudinal
    -   `starwars` - lists, missingness, comma separated values

------------------------------------------------------------------------

## Built-in data

-   `sf`
    -   `st_read(system.file("shape/nc.shp", package="sf"))` - comes
        with install
-   [`rocqi`](https://github.research.chop.edu/pages/analytics/rocqi/reference/index.html#section-data-sets)
    -   `ed_fractures`
    -   `surgeries`

------------------------------------------------------------------------

## Getting help in SQL

**Pointers**

-   use `select` without a `from` statement

-   mock up CTEs with `select` + `union`

-   use reserved words like `current_date` to mock up data types

-   write a small sample to `qmr_dev` if all else fails

------------------------------------------------------------------------

## can use select alone, no ‘from’ statement

``` sql
select 123
```

------------------------------------------------------------------------

## Use built-in date values

`current_date` and `current_timestamp` are built in

``` sql
select
    current_date - 2 as encounter_date,
    current_timestamp as surgery_time, -- also now()
    surgery_time::date - encounter_date as n_days,
    datetime(timezone(now(),  'UTC', 'America/New_York')) as time_utc    
```

------------------------------------------------------------------------

## Mock-up note_text

``` sql
select
    'I want the second word' as note_text,
    regexp_extract(note_text, '\w+', 1, 2) as second_word
```

------------------------------------------------------------------------

## Set-up a small data set with a `union` CTE

``` sql
with 
    clinic_list as (
              select '555-123-4567' as phone_number
        union select '555.123.4567'
        union select '(555)123-4567'
        union select '1-555-123-4567' 
        union select '(555)123-4567 ext. 9' 
    )
select 
    phone_number,
    regexp_replace(
        phone_number,
        '^1?[^\d]*(\d{3})[^\d]*(\d{3})[^\d]*(\d{4}).*',
        '\1-\2-\3'
    ) as clean_number
from clinic_list
```

------------------------------------------------------------------------

## Put a subset of the data in `QMR_DEV`

Put subset in qmr_dev for someone to help you if it does require a few
CTEs to get to your output add a small helper `select` at the end of the
CTE

.pull-left\[\]

.pull-right\[ Remember to drop anything you don’t need long-term\]

------------------------------------------------------------------------

## Takeaways

**Always** \* give all code required to reproduce the problem \* remove
extraneous code \* include expected output if possible, use pictures,
arrows, etc.

**For R** \* use built-in datasets \* `dput()` + `datapasta` to recreate
data \* `set.seed()` for random-generating functions \* always include
libraries, the reprex package can help

**For SQL** \* use `select` without a `from` statement \* mock up CTEs
with `select` + `union` \* use reserved words like `current_date` to
mock up data types \* write a small sample to `qmr_dev` if all else
fails
