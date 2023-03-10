regex (.\*)
================
Jake Riley - 2/25/2022

<!-- Didn't work in YAML: <br> <a href="https://rjake.github.io/analytics-deep-dive/sessions/regex/README.html#1"style="color:#f8f8f8">slides</a> | <a href="https://www.github.com/rjake/analytics-deep-dive/blob/main/sessions/regex/README.md"style="color:#f8f8f8">code</a></p -->

## Agenda

-   [slides](https://rjake.github.io/analytics-deep-dive/sessions/regex/README.html#1)
    \|
    [code](https://www.github.com/rjake/analytics-deep-dive/blob/main/sessions/regex/README.md)

-   Searching for text in **R** & **SQL**

-   Regular expressions - **what & how**

-   Lots of examples - **when & why**

-   Notes & Gotchas

------------------------------------------------------------------------

### Looking for text in SQL

SQL has the `like` command to search for text and uses `%` and `_` as
wildcards

``` sql
select 'A95' like 'A%';
select 'B95' not like 'A%'
```

| pattern | description                                             |
|:-------:|:--------------------------------------------------------|
|  `A%`   | starts with “A”                                         |
|  `%A`   | ends with “A”                                           |
|  `%A%`  | has “A” in any position                                 |
|  `A%5`  | starts with “A” and ends with “5”                       |
| `%A_5%` | matches \[“A”\] - \[a character\] - \[“5”\]             |
|  `_A%`  | has “A” in the second position                          |
|  `A__`  | starts with “A” and is 3 characters in length           |
| `A__%`  | starts with “A” and are at least 3 characters in length |

------------------------------------------------------------------------

### Literals

If you need a literal `_` or `%` you can escape it with `%`,

``` sql
select 'uses_underscore ' like '%%_%';
-- [% = anything] [%_ = literal '_'] [% = anything]

select 'cases are 5% below' like '%cases are %%% %'; 
-- %%% = anything between 'cases are ' and literal '%'
```

All the percents can be hard to read, you can use the `escape` command
to specify the character to use when escaping

``` sql
select 'cases are 5% below'  like  '%#%%' escape '#'
--                            --
```

You can break up the pattern with `||`

``` sql
select 'cases are 5% below' like  '%'||'#%'||'%'  escape '#'
```

------------------------------------------------------------------------

### Regular expressions

Regular expressions let you compose a more expansive search criteria in
a single pass

Instead of

``` sql
select 
    'gel capsules' as medication_form,
    medication_form like '%cap%' or medication_form like '%tab%'
```

You can write

``` sql
select 
    'gel capsules' as medication_form,
    regexp_like(medication_form,  'cap|tab')
```

The `|` operator lets it know to look for `cap` or `tab`

------------------------------------------------------------------------

### Before we start

-   Regular expressions are an **art form**

    -   It is easy to be overwhelmed

    -   They are often easier to write then they are to read

<br> \* We’re going to **jump right in**

-   Use this guide as a reference

------------------------------------------------------------------------

### Wildcards, ‘or’ operators & capture groups

``` sql
select regexp_like('gel capsules',  'cap|tab')
```

|     pattern     | definition               |       example        | explanation                                     |
|:---------------:|:-------------------------|:--------------------:|:------------------------------------------------|
|       `.`       | a single character/space |        `ab.`         | `ab` then one character (can be a space)        |
| <code>\|</code> | or                       |  <code>ab\|c</code>  | `a` followed by `b` or `c`                      |
|      `[]`       | any of these characters  |       `a[bcd]`       | `a` followed by `b` or `c` or `d`               |
|      `[^]`      | none of these charaters  |      `a[^bcd]`       | `a` then a character that is not `b` `c` or `d` |
|      `()`       | pattern capture group    | <code>a(b\|c)</code> | `a` followed by `bc` or `cd`                    |

-   **Typos** find “sep**a**rate” or “sep**e**rate” with
    `separate|seperate`, `sep(a|e)rate` or `sep[ae]rate`

-   **Similar text** find “biweekly” or “bimonthly” with
    `bi(week|month)ly`

-   **All diagnoses like** “S52.2” except “S52.2\_**9**” use
    `S52.2.[^9]`

-   **A phrase in quotes** `"[^"]+"` this is 3 parts `"` `[^"]+` `"`

-   **Ranges** look for a alphanumeric ranges inside brackets like
    `[a-d]`, `[X-Z]` `[1-5]` or together `[_A-Z0-9]`

------------------------------------------------------------------------

### Anchors

| pattern | definition  |   example   | explanation                             |
|:-------:|:------------|:-----------:|:----------------------------------------|
|   `^`   | starts with |   `^The`    | any string that starts with `The`       |
|   `$`   | ends with   |   `end$`    | any string that ends with `end`         |
|  `^$`   | exactly     | `^The end$` | exactly `The end` no other text present |

-   **Starts with** “S**4**2” or “S**5**2” → `^S[45]2`

-   **Ends with** a number → `[0-9]$`

-   **Any codes in range** “S52.2 . . **A**” to “S52.2 . . **C**” →
    `S52.2..[A-C]$`

-   **Has an exact pattern** → `^return in [0-9] days$`

------------------------------------------------------------------------

### Character classes

| pattern | definition                                         | example | explanation                                                                     |
|---------|----------------------------------------------------|---------|---------------------------------------------------------------------------------|
| `\d`    | a digit                                            | `ab\d`  | `ab` then `0-9`                                                                 |
| `\w`    | a word character <br> (alphanumeric or underscore) | `ab\w`  | `ab` then `a-z` `0-9` or `_`                                                    |
| `\s`    | a whitespace character <br> (spaces or tabs)       | `ab\s`  | `ab` then `"  "`                                                                |
| `\b`    | a word boundary                                    | `\ba\b` | `a` surrounded by whitespace, punctuation <br> or the start/end of the sentence |

-   These can be **negated** with `\D` `\W` and `\S`

-   **Starts with** a digit → `^\d`

-   **Does not start with** a digit → `^\D`

-   **Anything like** “1 ml” or “5 mg” → `\d m[lg]`

-   **Exactly** “signed by” → `\bsigned by\b` using boundaries
    “de**signed** **by**” would not match

------------------------------------------------------------------------

### Quantifiers

| pattern | definition   | example | explanation                                         |
|:-------:|:-------------|:-------:|:----------------------------------------------------|
|   `?`   | maybe exists |  `o?`   | maybe an ‘o’                                        |
|   `+`   | once or more |  `\d+`  | one or more consecutive digits - min of 1           |
|   `*`   | zero or more |  `\d*`  | maybe several consecutive digits, maybe zero digits |

-   **First two words** <br>`^\w+ \w+` Note: `^\w \w` would look for
    something like `a b`

-   **Variations** on “post-op” <br>`post` `.?` `op` `(erative)?`

-   **Excessive white space** match <code>result:     neg</code> and
    `result: neg` <br> `result:\s+\w+`

-   **Dot star** <br>`.*` is very common and often described as
    “anything”. It is equivalent to `like '%'` in SQL

------------------------------------------------------------------------

### Quantifiers

| pattern | definition                   |  example  | explanation      |
|:-------:|:-----------------------------|:---------:|:-----------------|
|  `{2}`  | first 2 characters           |  `\d{2}`  | exactly 2 digits |
| `{1,2}` | 1 to 2 characters            | `\d{2,5}` | 2 to 5 digits    |
| `{2,}`  | 2 characters & any remaining | `\d{2,}`  | 2 or more digits |

<br> \* **Dates** find “1/1/22”, “1-1-22” or “01/01/2022” <br>`\d{1,2}`
`[/-]` `\d{1,2}` `[/-]` `\d{2,4}`

<br>

-   **Phone numbers** find “555-123-4567”, “555 123 4567” or
    “555.123.4567” <br>`\d{3}` `\D` `\d{3}` `\D` `\d{4}` <br>*This is
    overly simplified, there are more complicated patterns to watch out
    for*

------------------------------------------------------------------------

### Helpers

| pattern       | definition                 | replaces                    |
|---------------|:---------------------------|:----------------------------|
| `[[:digit:]]` | any digit                  | `[0-9]`                     |
| `[[:lower:]]` | lowercase letters          | `[a-z]`                     |
| `[[:upper:]]` | uppercase letters          | `[A-Z]`                     |
| `[[:alpha:]]` | any letter of the alphabet | `[a-zA-Z]`                  |
| `[[:alnum:]]` | alphanumeric characters    | `[a-zA-Z0-9]` (very common) |
| `[[:punct:]]` | punctuation                | `[\.,?!'\";:-]`             |

-   They only work inside `[ ]`

-   The helper is really `[: :]` not `[[: :]]` but `[[: :]]` is how
    you’ll usually see it

-   You can combine them inside one `[ ]`, ex. `[[:digit:][:punct:]]`

-   To negate any of these use `[^[ ]]`, ex. `[^[:alpha:]]`

------------------------------------------------------------------------

### Escaping

If you need to find these characters `^.[$()|*+?{\` you will need to
escape them with a backslash

<br>

-   **Line breaks** in flat files `\n` is used in flat files for line
    breaks to match it, you’ll need `\\n` <br> it is often combined with
    `\r` so you might need `\\n\\r`

<br>

-   **Text between parentheses** → `\(` `[^\)]+` `\)`

------------------------------------------------------------------------

### In practice

|  Action | SQL [link](https://www.ibm.com/docs/en/psfa/7.2.1?topic=functions-regular-expression) | R - stringr [link](https://cran.r-project.org/web/packages/stringr/vignettes/regular-expressions.html) | Base R [link](https://stringr.tidyverse.org/articles/from-base.html) |
|--------:|--------------------------------------------------------------------------------------:|-------------------------------------------------------------------------------------------------------:|:---------------------------------------------------------------------|
|  Detect |                                              `regexp_like()` <br> `not regexp_like()` |                                                                    `str_detect()` <br> `!str_detect()` | `grepl()` <br> `!grepl()`                                            |
| Extract |                                                                    `regexp_extract()` |                                                                                        `str_extract()` | `regmatches(regexpr())`                                              |
|  Remove |                                                                    `regexp_replace()` |                                                                 `str_remove()` <br> `str_remove_all()` | `sub()` <br> `gsub()`                                                |
| Replace |                                                                    `regexp_replace()` |                                                               `str_replace()` <br> `str_replace_all()` | `sub()` <br> `gsub()`                                                |
|   Count |                                                                `regexp_match_count()` |                                                                                          `str_count()` | `gregexpr()` + extra logic                                           |

Note:

-   R needs `\\` instead of `\`
    -   `\w+` becomes `\\w+`
    -   Finding a literal `\` becomes `\\\\` (escape-slash-escape-slash)

------------------------------------------------------------------------

### Detecting text

``` r
# SQL
regexp_like(
  string,    # where to look
  pattern,   # pattern to find
  start_pos, # which character to start on, defaults to 1
  flags      # g = stop at first search, i = case insensitive
)

# R
str_detect()
```

**Match** combinations of diagnoses, this replaces 15 combinations

``` sql
--sql
select regexp_like('M65.352', 'M65.3[1-5][129]') -- can negate with not regexp_like

--r
str_detect("M65.352",  "M65.3[1-5][129]") -- can negate as !str_detect()
```

------------------------------------------------------------------------

### Detecting text

**Filter** results

``` sql
--sql
where regexp_like(note_text, 'hoverboard')

--r
filter(str_detect(note_text, "hoverboard"))
```

------------------------------------------------------------------------

### Extracting text

``` r
# SQL
regexp_extract(
  string,
  pattern,
  start_pos,
  reference, # if multiple matches, which match to extract, defaults to 1
  flags
)

# R
str_extract()
```

**Extract** dosage (300mg)

``` sql
--sql
select regexp_extract('gabapentin 300mg', '\d+.?mg$') 

--r
str_extract("gabapentin 300mg",  "\\d+mg")
```

------------------------------------------------------------------------

### Extracting text

**Find** doctor’s name

``` sql
--sql
select regexp_extract('patient spoke with Dr. Flynn after xyz', 'Dr(\.)? \w+') 
                                                -- can also be: 'Dr.? \w+'
--r
str_extract("patient spoke with Dr. Flynn after xyz",  "Dr(\\.)? \\w+")
```

------------------------------------------------------------------------

### Extracting text

**Find** all the things

``` sql
select 
  array_combine( --like group_concat()
      regexp_extract_all( --creates an array
          'The dosage is 10.123 mg of medication_1 and 12.345mg of medication_2', 
          '[\d\.]+\s?mg'
        -- -------   --
      ),
      ',' -- delimiter, must be 1 character
  )
-- 10.123 mg,12.345mg
```

<br>

*\* Ask me or Jon M. about then flipping this into 1 row per value*

------------------------------------------------------------------------

### Extracting text

**Extract** nth word

``` sql
-- find 2nd word
select regexp_extract('first second third',  '\w+',  1,  2)
```

<br>

**R** has the helper function `word()`

``` r
# 2nd word
stringr::word("first second third", start = 2, sep = " ")

# last word
stringr::word("first second third", start = -1, sep = " ")
```

------------------------------------------------------------------------

### Positive look-around

|  pattern  | definition  |
|:---------:|:------------|
| `(?<=)__` | preceded by |
| `__(?=)`  | followed by |

<br>

<br>

The word **preceded by** (after) “second”

``` sql
select regexp_extract("first second third",  "(?<=second )\w+") # third
--                                             ----------
```

The word **followed by** (before) ” second”

``` sql
select regexp_extract("first second third",  "\w+(?= second)") # first
--                                                ---------
```

The look-around **pattern must be fixed width** you can use `\w` and
`\d` but you can’t use `*`, `+` or `?` here

------------------------------------------------------------------------

### Negative look-around

|    pattern    | definition           |
|:-------------:|:---------------------|
|   `(?<=)__`   | preceeded by         |
|   `__(?=)`    | followed by          |
| **`(?<!)__`** | **not preceeded by** |
| **`__(?!)`**  | **not followed by**  |

<br> The first word **not preceded** (not after) by a digit

``` sql
select regexp_extract("1a CHOP",  "(?<!\d)[[:alpha:]]+") # "CHOP"
--                                  -----
```

The first digit **not followed by** (not before) a space

``` sql
select regexp_extract("a1 2b 3c",  "\d+(?!\s)") -- "2"
--                                      ----
```

------------------------------------------------------------------------

### Replacing text

``` r
# SQL
regexp_replace(
  string,
  pattern,
  replacement,  # new string to use
  start_pos,
  reference     # if multiple matches, which match to replace, defaults to 0 (all)
)

# R
str_replace()   
str_replace_all()
```

**Replace** extra spaces between text with single space

``` sql
--sql
select regexp_replace('result:   neg',  '\s+',  ' ')

--r
str_replace_all("result:   neg",  "\\s+",  " ")
```

------------------------------------------------------------------------

### Removing text

``` r
regexp_replace( # same as above
  string,
  pattern,
  replacement,  # use '' to remove
  start_pos,
  reference
)

str_remove()
str_remove_all()
```

**Remove** the dosage

``` sql
--sql
select regexp_replace('gabapentin 300mg',  ' \d.*',  '')

--r
str_remove("gabapentin 300mg", " \\d.*")
```

------------------------------------------------------------------------

### Capture groups

``` sql
select regexp_replace('second first junk',  '(\w+) (\w+).*',  '\2 then \1' )
                 --    1----- 2----           1--   2--       'first then second'
                       
select regexp_replace('jake lives with cody',  '^(\w+)( .* )(\w+)$',  '\3\2\1')
                 --    1--- 2--------- 3---       1--  2---  3--      cody lives with jake
```

``` sql
with 
    clinic_list as (
              select '555-123-4567' as phone_number
        union select '555.123.4567'
        union select '(555)123-4567 ext. 9' 
        union select '1-555-123-4567'
    )
select 
    phone_number,
    regexp_replace(
        phone_number,
        '^1?\D*(\d{3})\D?(\d{3})\D(\d{4}).*',
        --      1----     2----    3----
        '\1-\2-\3' -- all return format 555-123-4567
    ) as clean_number
from clinic_list
```

------------------------------------------------------------------------

### Capture groups in the wild

``` r
c(
  "line1",                                 # line_1_name 
  "something_ln_8_days",                   # line_8_something_days 
  "lda_id_4",                              # line_4_lda_id
  "if_line_3_not_complete"                 # line_3_if_not_complete
) |> 
  str_replace_all("line(\\d+)$",            "line_\\1_name") |>
  str_replace_all("(.*)ln_(\\d+_)(.*)",     "line_\\2\\1\\3") |>
  str_replace_all("^(lda_id)_(\\d+)$",      "line_\\2_\\1") |>
  str_replace_all("(if_)(line_\\d+_)(.*)",  "\\2\\1\\3")
```

We turned this into a function, renamed all of our columns, then pivoted
the data

``` r
rename_line_numbers <- function(x) {
  x |>
    str_replace_all() |> 
    ...
}

redcap_data |> 
  rename_all(rename_line_numbers) |> 
  pivot_longer(starts_with("line_"))
```

------------------------------------------------------------------------

### Readability tips in SQL

Use `||` to build a readable list. It helps to alphabetize

``` sql
select 
    'Erythromycin-sulfisoxazole (200mg)/5mL' as generic_medication_name,
    regexp_extract(
        lower(generic_medication_name),
        '\b(amant\w+|erythro\w+(\-sulfisoxazole)?|polymyxi\w+|(praziqu|pyr)antel|(tazo|clav|sulb)\w+|\w+zolid)\b'
        --  -------- ---------------------------- ----------- ------------------ ------------------- -------- --
    ),
    regexp_extract(
        lower(generic_medication_name),
        '\b('
            || 'amant\w+|' -- can add comments here
            || 'erythro\w+(\-sulfisoxazole)?|' -- and here
            || 'polymyxi\w+|'
            || '(praziqu|pyr)antel|'
            || '(tazo|clav|sulb)\w+|'
            || '\w+zolid|'
            || ')\b'       
        ) as generic_abx_name
```

------------------------------------------------------------------------

### Readability tips in R

`regex(..., comments = TRUE)`

``` r
phone <- regex("
  \\(?     # maybe opening parens
  (\\d{3}) # area code
  [\\)-]?  # maybe closing parens, or dash
  \\s?     # maybe space (if parens)
  (\\d{3}) # another 3 numbers
  [ -]?    # optional space or dash
  (\\d{3}) # three more numbers
  ", 
  comments = TRUE
)

str_replace_all(
  string = "555-123-4567", 
  pattern = phone, 
  replacement = "(\\1) \\2-\\3"
)
# "(555) 123-4567"
```

------------------------------------------------------------------------

### Readability tips in R

Pass paired replacements with named vector

``` r
replacements <- c(
  # pattern           = replacement
  "line(\\d+)$"       = "line_\\1_name",
  "^(lda_id)_(\\d+)$" = "line_\\2_\\1"
)


c(
  "line1",             # line_1_name 
  "lda_id_4"           # line_4_lda_id
) |> 
  str_replace_all(replacements)
```

Or use `set_names()`

``` r
replacements <- set_names(
  names(some_vector),
  nice_display_names(some_vector)
)
```

------------------------------------------------------------------------

### Notes

**SQL** - nesting regex functions can cause this error:

``` sql
ERROR [HY000] ERROR:  Record size 112228 exceeds internal limit of 65535 bytes
```

You can get around this by casting the results as you go along:

``` sql
regexp_replace(
    regexp_extract(note_text, '(?<=note signed by )jake riley')::varchar(100),
    '^\w+ \w+',                --                              --------------
    '\2, \1'
)
```

<br>

**R** - differences

-   `stringr` - a simplified version of `stringi`, arguments consistent
    & pipeable (`x` is first), all start `str_`
-   `stringi` - more arguments, more functions, encoding conversions,
    all start `stri_`
-   base R - more variation in argument order, `x` is not the first
    argument see more
    [here](https://stringr.tidyverse.org/articles/from-base.html)

------------------------------------------------------------------------

### Notes

**Extended-ascii characters** - you can use regex here

``` sql
--sql
select regexp_replace('Â·Â°Line 1Â·Â°',  '[\x80-\xff]',  '')

--r
str_remove_all("Â·Â°Line 1Â·Â°", "[\\x80-\\xff]")
```

…or these built in helpers

``` sql
--sql
select translate('Â·Â°Line 1Â·Â°', 'Â·°', '')

--r
iconv("Â·Â°Line 1Â·Â°", "latin1", "ASCII", sub = "")
```

------------------------------------------------------------------------

### Gotchas

-   `^abc` vs `[^abc]` one means **starts with** one means **none of
    these**

<br> \* Not all languages treat regex the same. We already saw `\w` vs
`\\w+` <br> You might see references to using **Perl** for certain
operations. You do this in base R with `perl = TRUE`

``` r
sub(
  pattern = "^(.)",       # make first letter
  replacement = "\\U\\1", # uppercase
  x = "jake",             # note x is not the first argument
  perl = TRUE
)
```

------------------------------------------------------------------------

### Gotchas

-   **“greedy”** vs **“lazy”**

    ``` r
    # greedy - returns `"_"` because `.*` includes digits
    str_replace("abc1 def2",  ".*\\d",  "_") 
    ```

    ``` sql
    select regexp_replace('abc1 def2',  '.*\d',  '_')
    ```

    You can use one of these patterns instead

    ``` r
    # lazy - stop at first instance
    str_replace("abc1 def2",  ".*?\\d",  "_")
    str_replace("abc1 def2",  "\\D*\\d",  "_")
    ```

    ``` sql
    -- start on the first match and stop at the first match
    select regexp_replace('abc1 def2',  '.*?\d',  '_',  1,  1)
    select regexp_replace('abc1 def2',  '\D*\d',  '_',  1,  1) 
    ```

    ------------------------------------------------------------------------

### Resources

You can learn more about regular expressions here:

-   Short tutorial: [Regex tutorial A quick cheatsheet by examples \| by
    Jonny
    Fox](https://medium.com/factory-mind/regex-tutorial-a-simple-cheatsheet-by-examples-649dc1c3f285)
-   `stringr` vignette: [Regular expressions
    (r-project.org)](https://cran.r-project.org/web/packages/stringr/vignettes/regular-expressions.html)
-   regex101: [regex101 - build, test, and debug
    regex](https://regex101.com/)
