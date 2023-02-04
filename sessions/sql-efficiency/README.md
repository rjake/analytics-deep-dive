SQL Efficiency
================
Jake Riley 9/9/2022

## Agenda

-   [slides](https://www.github.com/pages/rjake/analytics-deep-dive/sessions/sql-efficiency/README.html#1)
    \|
    [code](https://www.github.com/rjake/analytics-deep-dive/blob/main/sessions/sql-efficiency/README.md)
-   
-   

## Why are we here?

-   morning runtime
-   tech debt
-   professional development

## Some new terms

#### “optimizer”

even though you wrote a nice logical piece of code, the optimizer will
rearrange things to be more efficient <br><br>

#### “cost”

the computational cost of a query, usually \< 1M but can get into the
octillions (28 zeros) :scream: <br><br>

#### “plans”

the number of routes the optimizer has to assess to find the fastest
route <br><br>

#### “snippets”

the pieces of code that are run independently (???)

## The optimizer

Even though your query seems logical, the optimizer assesses different
ways to run it (ex. different join order) and picks the “cheapest” plan
to return the data <br>

``` mermaid

%%{init: {'flowchart':{ 'nodeSpacing': 20, 'rankSpacing': 30} } }%%

flowchart LR
  q([Your Nice Query]) --- o([The Optimizer])
  o ---- p1([Costly Plan]) ---- s1([Snippet]) & s2([Snippet]) & s3([Snippet])
  o ---- p2([Cheaper Plan]) ---- s4([Snippet]) & s5([Snippet]) ---- r([Result])
  
  classDef default fill:black, color:#999, stroke:grey, stroke-width:0px;
  classDef chosen fill:goldenrod, color:#333, stroke:#333, stroke-width:1px;
  class q,o,p2,s4,s5,r chosen;

  linkStyle default stroke-width:2px, fill:none, stroke:goldenrod;
  linkStyle 1,2,3,4 stroke-width:2px, fill:none, stroke:grey;

```

“the optimizer should never take more time to optimize a query than it
will take to execute it”
[source](https://www.red-gate.com/simple-talk/databases/sql-server/performance-sql-server/join-reordering-and-bushy-plans/)

<div class="aside">

[editor](https://mermaid.live)

</div>

## Why are things slow?

#### Not enough memory

-   too much is being computed (large materialized tables???)
-   costly queries (full table scans???)
-   too many plans/snippets

<br><br>

#### No available sessions (slots???) for your query to run

-   often your query is stuck in a queue and has not run yet :scream:

## order

-   `FROM` & `JOIN` determine & filter rows
-   `WHERE` more filters on the rows
-   `GROUP BY` combines those rows into groups
-   `HAVING` filters groups
-   `SELECT` returns and modifies columns
-   `DISTINCT` removes duplicates
-   `ORDER BY` arranges the remaining rows/groups
-   `LIMIT` filters on the remaining rows/groups

## Why staging tables?

-   CTEs aren’t separate tables stored in an environment like in R
-   The tables are run as sub-queries (???) in subsequent select
    statements (ex. other CTEs)
    -   need to be materialized
-   They have little (no?) difference in performance
-   Biggest benefit is readability & succinctness

## Why `group by` instead of `distinct`?

You can accidentally return duplicate records with `distinct` +
`row_number()`

<div class="columns">

<div class="column">

This can have duplicates

``` sql
select distinct
  visit_key,
  row_number() over (
    partition by visit_key 
    order by record_date
  ) as seq_num
from flowsheet_all
```

This is because the `distinct` happens <br>after the `select` statement

</div>

<div class="column">

Instead use

``` sql
select
  visit_key,
  row_number() over (
    partition by visit_key 
    order by record_date
  ) as seq_num
from encounter_all
group by visit_key
```

or less desirable

``` sql
select distinct
  visit_key,
  dense_rank() over (
    partition by visit_key 
    order by record_date
  ) as seq_num
from flowsheet_all
```

</div>

</div>

<div class="aside">

https://stackoverflow.com/questions/15476391/fetch-distinct-record-with-join/15477305#15477305

</div>

## About `group by`

<div class="columns">

<div class="column">

Try not to repeat the same fields over and over

``` sql
with ip_visits as (
  select 
    visit_key,
    patient_name,
    mrn,
    encounter_date,
    hospital_admission_date,
    count(*) as n_records
  from 
    encounter_inpatient
    join flowsheet_all
  group by
    visit_key,
    patient_name,
    mrn,
    encounter_date,
    hospital_admission_date
)

select
  visit_key,
  patient_name,
  mrn,
  encounter_date,
  hospital_admission_date,
  etc
)
from 
  ip_visits
  join some_other_table
```

</div>

<div class="column">

keep CTEs as short as possible & join dimensions later

``` sql
with ip_visits as (
  select 
    visit_key,
    count(*) as n_records
  from 
    encounter_inpatient
    join flowsheet_all
  group by
    visit_key
)

select
  visit_key,
  patient_name,
  mrn,
  encounter_date,
  hospital_admission_date,
  n_records
from 
  ip_visits
  join encounter_inpatient
  join some_other_table
```

</div>

</div>

## CTEs

-   Better to put a complicated CTE in a staging table
    -   CTE results are not stored to the side like in R or python
    -   Snippets are run in parallel and CTE is calculated each time it
        is called
-   Keep as short as possible
    -   add filters here rather than in final `select` statement ex.
        don’t do `select * from note_text`
-   `order by` in a CTE just adds cost and does not affect final results

## Full Table Scans

## Avoid using functions in predicates (`where` & `on`)

### Slower

``` sql
-- cost = 244
select * 
from chop_analytics.admin.encounter_office_visit_all
where hour(appointment_date) = 10 
```

### Faster

We added `scheduled_appointment_time_of_day` as a numeric field so it is
easier to plot but also easier to query

``` sql
-- cost =  59
select * 
from chop_analytics.admin.encounter_office_visit_completed
where scheduled_appointment_time_of_day between 10 and 10.99 
```

### Suggestion

Put these transformations in the in your staging tables

## www.techagilist.com

-   [source](https://www.techagilist.com/mainframe/db2/db2-predicates-performance-tuning-db2-queries/)
-   stage 1 - no table scan
    -   indexable - **first**
        -   column + operator such as `=`, `>`, `<`, `>=`, `<=`
        -   `between`, `in` and `like 'abc%'` (no leading wildcard)
    -   non-indexable - **second**
        -   column + `!=`, `not between` and `not like`
-   stage 2 - **third** - has full table scan
    -   functions on column `substr(x, 1, 1) = 'B'`
    -   if field is varchar(8) and you ask it to evaluate a string of
        length 10
-   order within stages
    -   equality & `in (one_value)`
    -   ranges and `x is not null`
    -   all others
-   compound predicates will take the higher stage
    -   `x = 'y' or x <> 'z'` -\> stage 1, non-indexable
    -   `x = 'y' or substr(x, 1, 1) = 'z'` -\> stage 2
-   `x between y and z` is more efficient than `x <=y and x >= z`

## www.informit.com

-   [source](https://www.informit.com/articles/article.aspx?p=27015&seqNum=5)
-   These will invalidate indexing
    -   Comparing columns in the same table
    -   Choosing columns with low-selectivity indexes (maybe not
        applicable?)
    -   Doing math on a column before comparing it to a constant
    -   Applying a function to column data before comparing it to a
        constant
    -   Finding ranges with BETWEEN
    -   Matching with LIKE
    -   Comparing to NULL
    -   Negating with NOT
    -   Converting values
    -   Using OR
    -   Finding sets of values with IN
    -   Using multicolumn indexes

## nasis.sc.egov.usda.gov

-   [source](https://nasis.sc.egov.usda.gov/NasisReportsWebSite/limsreport.aspx?report_name=SDA-Tips)
-   `GROUP BY` or `ORDER BY` are not used unnecessarily
-   It is fast or faster to `SELECT` by actual column name(s) than to
    use an asterisk. The larger the table, the more likely you will save
    time.
-   Perform functions instead of comparisons on the data objects
    referenced in the `WHERE` clause. (`x > 0` rather than `x != 0`)
-   Make the table with the least number of rows the driving table. Do
    this by making it first in the `FROM` clause.
-   The `OVER` clause with an aggregate function is similar to, but more
    efficient than, a subquery.

## www.ibm.com

-   [source](https://www.ibm.com/docs/en/db2-for-zos/12?topic=queries-coding-sql-statements-avoid-unnecessary-processing)
-   stage 1 (before returned) vs stage 2 (after returned)
-   [selection-stage-1-stage-2-predicates](https://www.ibm.com/docs/en/db2-for-zos/12?topic=selection-stage-1-stage-2-predicates)
    -   predicates associated with columns or constants of the DECFLOAT
        data type are never treated as stage 1
-   [selection-examples-predicate-properties](https://www.ibm.com/docs/en/db2-for-zos/12?topic=selection-examples-predicate-properties)
-   [factors-default-filter-simple-predicates](https://www.ibm.com/docs/en/db2-for-zos/12?topic=factors-default-filter-simple-predicates)
-   [efficiently-adding-extra-predicates-improve-access-paths](https://www.ibm.com/docs/en/db2-for-zos/12?topic=efficiently-adding-extra-predicates-improve-access-paths)
-   [manipulation-removal-pre-evaluated-predicates](https://www.ibm.com/docs/en/db2-for-zos/12?topic=manipulation-removal-pre-evaluated-predicates)
    -   Db2 does not remove OR 0=1 or OR 0\<\>0 predicates. Predicates
        of these forms can be used to prevent index access.
-   [queries-making-predicates-eligible-expression-based-indexes](https://www.ibm.com/docs/en/db2-for-zos/12?topic=queries-making-predicates-eligible-expression-based-indexes)
    -   subquery for `upper()`?

## www.ibm.com

-   [list of stage 1 vs stage
    2](https://www.ibm.com/docs/en/db2-for-zos/12?topic=efficiently-summary-predicate-processing)

    -   see also
        [explanation](https://www.ibm.com/docs/en/db2-for-zos/11?topic=efficiently-summary-predicate-processing#db2z_summarypredicateprocessing__bkn9pred1187154)

## Predicates

imported via CSV example

    ── Attaching packages ─────────────────────────────────────── tidyverse 1.3.1 ──

    ✔ ggplot2 3.3.6     ✔ purrr   0.3.4
    ✔ tibble  3.1.8     ✔ dplyr   1.0.9
    ✔ tidyr   1.2.0     ✔ stringr 1.4.0
    ✔ readr   2.1.2     ✔ forcats 0.5.1

    Warning: package 'tibble' was built under R version 4.2.1

    ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
    ✖ dplyr::filter() masks stats::filter()
    ✖ dplyr::lag()    masks stats::lag()

    Rows: 86 Columns: 7
    ── Column specification ────────────────────────────────────────────────────────
    Delimiter: ","
    chr (7): predicate, indexable, stage_1, logic, stage, note, reason

    ℹ Use `spec()` to retrieve the full column specification for this data.
    ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
    `summarise()` has grouped output by 'logic'. You can override using the `.groups` argument.

<div id="vpaoncftyb" style="overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>html {
  font-family: Courier;
}

#vpaoncftyb .gt_table {
  display: table;
  border-collapse: collapse;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 11px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}

#vpaoncftyb .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#vpaoncftyb .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}

#vpaoncftyb .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 0;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}

#vpaoncftyb .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#vpaoncftyb .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}

#vpaoncftyb .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}

#vpaoncftyb .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}

#vpaoncftyb .gt_column_spanner_outer:first-child {
  padding-left: 0;
}

#vpaoncftyb .gt_column_spanner_outer:last-child {
  padding-right: 0;
}

#vpaoncftyb .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}

#vpaoncftyb .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
}

#vpaoncftyb .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}

#vpaoncftyb .gt_from_md > :first-child {
  margin-top: 0;
}

#vpaoncftyb .gt_from_md > :last-child {
  margin-bottom: 0;
}

#vpaoncftyb .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}

#vpaoncftyb .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}

#vpaoncftyb .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}

#vpaoncftyb .gt_row_group_first td {
  border-top-width: 2px;
}

#vpaoncftyb .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#vpaoncftyb .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}

#vpaoncftyb .gt_first_summary_row.thick {
  border-top-width: 2px;
}

#vpaoncftyb .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#vpaoncftyb .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}

#vpaoncftyb .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}

#vpaoncftyb .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}

#vpaoncftyb .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}

#vpaoncftyb .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#vpaoncftyb .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-left: 4px;
  padding-right: 4px;
  padding-left: 5px;
  padding-right: 5px;
}

#vpaoncftyb .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}

#vpaoncftyb .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}

#vpaoncftyb .gt_left {
  text-align: left;
}

#vpaoncftyb .gt_center {
  text-align: center;
}

#vpaoncftyb .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

#vpaoncftyb .gt_font_normal {
  font-weight: normal;
}

#vpaoncftyb .gt_font_bold {
  font-weight: bold;
}

#vpaoncftyb .gt_font_italic {
  font-style: italic;
}

#vpaoncftyb .gt_super {
  font-size: 65%;
}

#vpaoncftyb .gt_two_val_uncert {
  display: inline-block;
  line-height: 1em;
  text-align: right;
  font-size: 60%;
  vertical-align: -0.25em;
  margin-left: 0.1em;
}

#vpaoncftyb .gt_footnote_marks {
  font-style: italic;
  font-weight: normal;
  font-size: 75%;
  vertical-align: 0.4em;
}

#vpaoncftyb .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}

#vpaoncftyb .gt_slash_mark {
  font-size: 0.7em;
  line-height: 0.7em;
  vertical-align: 0.15em;
}

#vpaoncftyb .gt_fraction_numerator {
  font-size: 0.6em;
  line-height: 0.6em;
  vertical-align: 0.45em;
}

#vpaoncftyb .gt_fraction_denominator {
  font-size: 0.6em;
  line-height: 0.6em;
  vertical-align: -0.05em;
}
</style>
<table class="gt_table">
  
  <thead class="gt_col_headings">
    <tr>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">logic</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">indexible</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">stage 1</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1">stage 2</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td class="gt_row gt_left"><div class='gt_from_md'><p>between</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'><p>col between value1 and value2<br>col between noncol expr1 and noncol expr2<br>value between col1 and col2<br>col between expression1 and expression2</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'><p>col not between value1 and value2<br>col not between noncol expr1 and noncol expr2</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'><p>col between col1 and col2<br>value not between col1 and col2</p>
</div></td></tr>
    <tr><td class="gt_row gt_left"><div class='gt_from_md'><p>distinct</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'><p>col is not distinct from value<br>col is not distinct from noncol expr<br>t1.col1 is not distinct from t2.col2<br>t1.col1 is not distinct from t2 col expr</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'><p>col is distinct from value<br>col is distinct from noncol expr<br>t1.col1 is distinct from t2 col expr</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'><p>t1.col1 is distinct from t2.col2</p>
</div></td></tr>
    <tr><td class="gt_row gt_left"><div class='gt_from_md'><p>equality</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'><p>col = value<br>col = noncol expr<br>t1.col = t2 col expr<br>t1.col1 = t1.col2<br>substr(col, 1, n)=value<br>date(col) = value<br>year(col) = value</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'></div></td>
<td class="gt_row gt_left"><div class='gt_from_md'><p>expression = value</p>
</div></td></tr>
    <tr><td class="gt_row gt_left"><div class='gt_from_md'><p>in</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'><p>col in (list)</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'><p>col not in(list)</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'></div></td></tr>
    <tr><td class="gt_row gt_left"><div class='gt_from_md'><p>inequality</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'></div></td>
<td class="gt_row gt_left"><div class='gt_from_md'><p>col &lt;&gt; value<br>col &lt;&gt; noncol expr<br>t1.col &lt;&gt; tc col expr</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'><p>t1.col1 &lt;&gt; t1.col2<br>expression &lt;&gt; value</p>
</div></td></tr>
    <tr><td class="gt_row gt_left"><div class='gt_from_md'><p>like</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'><p>col like ‘pattern’<br>col like host variable<br>col like upper(‘pattern’)<br>col like upper(host-variable)<br>col like upper(global-variable)<br>col like upper(cast(host-variable as data-type)<br>col like upper(cast(sql-variable as data-type)<br>col like upper(cast(global-variable as data-type)</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'><p>col not like ‘char’<br>col like ‘%char’<br>col like ‘_char’</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'></div></td></tr>
    <tr><td class="gt_row gt_left"><div class='gt_from_md'><p>null</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'><p>col is null<br>col is not null</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'></div></td>
<td class="gt_row gt_left"><div class='gt_from_md'></div></td></tr>
    <tr><td class="gt_row gt_left"><div class='gt_from_md'><p>operator</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'><p>col op value<br>col op noncol expr<br>t1.col op t2 col expr<br>t1.col1 op t1.col2<br>substr(col, 1, n) op value<br>date(col) op value<br>year(col) op value</p>
</div></td>
<td class="gt_row gt_left"><div class='gt_from_md'></div></td>
<td class="gt_row gt_left"><div class='gt_from_md'><p>expression op value</p>
</div></td></tr>
  </tbody>
  
  
</table>
</div>

## Predicates

manually curated

<table style="width:100%;">
<colgroup>
<col style="width: 13%" />
<col style="width: 35%" />
<col style="width: 23%" />
<col style="width: 28%" />
</colgroup>
<thead>
<tr class="header">
<th>Type</th>
<th>Fastest (indexable)</th>
<th>Slower (stage 1)</th>
<th>Slowest (stage 2)</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td><code>in</code></td>
<td>col in ()</td>
<td></td>
<td></td>
</tr>
<tr class="even">
<td><code>between</code></td>
<td>col between 5 and 10<br />
5 between col_1 and col_2<br />
</td>
<td>col not between 5 and 10</td>
<td>col between col_2 and col_3<br />
5 not between col_1 and col_2</td>
</tr>
<tr class="odd">
<td><code>null</code></td>
<td></td>
<td>is null<br />
is not null</td>
<td></td>
</tr>
<tr class="even">
<td><code>like</code></td>
<td>like ‘abc%’<br />
like lower(‘abc%’)</td>
<td>like ‘%abc%’<br />
not like ‘abc%’</td>
<td></td>
</tr>
<tr class="odd">
<td>equality</td>
<td>col = 123<br />
col = noncol expr<br />
col = lower(‘abc’)<br />
col &gt; 123</td>
<td>col &lt;&gt; 123</td>
<td>col &lt;&gt; col_2</td>
</tr>
</tbody>
</table>

## www.ibm.com

-   [source](https://www.ibm.com/docs/en/db2-for-zos/12?topic=processing-using-non-column-expressions-efficiently)
-   Where possible, use a non-column expression (put the column on one
    side of the operator and all other values on the other)

``` sql
where (x * 2) < 20

-- preferred
where x < 20 / 2
```

## www.sisense.com

-   [source](https://www.sisense.com/blog/8-ways-fine-tune-sql-queries-production-databases/)
-   use `where` instead of `having` - doesn’t require a full index
    search
-   wildcards at the end only preferred `'abc%'` instead of `'%abc%'`

## arctype.com

-   [source](https://arctype.com/blog/optimize-sql-query/)
-   the larger the number of rows, the higher the probability of slow
    performance.
-   The run time of an SQL query increases every time a table join is
    implemented. This is because joins increase the number of rows—and
    in many cases, columns—in the output. To rectify this situation, the
    size of the table should be reduced (as previously suggested) before
    joining.
-   `limit` + a `group by` happens after and won’t affect runtime

## blog.jooq.org

-   [source](https://blog.jooq.org/avoid-using-count-in-sql-when-you-could-use-exists/)
-   use `exists()` instead of `count()`

``` sql
-- slower, cost = 123
select 
 a.name,
 count(*) > 10 as n_film
from actor      a
join film_actor f on f.actor_id = a.actor_id
;

-- faster, cost = 3.4
select 
  a.name,
  exists (
    select * 
    from actor      a
    join film_actor f on f.actor_id = a.actor_id
    where a.last_name = 'WAHLBERG'
  ) as n_film
;
```

-   rationale

``` js
// EXISTS
if (!collection.isEmpty())
    doSomething();
 
// COUNT(*)
if (collection.size() == 0)
    doSomething();
```

## www.metabase.com

-   [source](https://www.metabase.com/learn/sql-questions/sql-best-practices#sql-best-practices-for-from)
-   adding table alias to column is faster, prevents column name search
-   filter `WHERE` before `HAVING`
-   `||` is a function -\> stage 2 bad:
    `hero || sidekick = 'BatmanRobin'` good:
    `hero = 'Batman' AND sidekick = 'Robin'`
-   use `EXISTS` vs `IN`
-   order `GROUP BY` columns by more unique values first (descending
    cardinality)
-   `UNION ALL` vs `UNION`
-   Use `CREATE INDEX` ?

## sqlmaestros.com

-   [source](https://sqlmaestros.com/sargability-cast-convert-more/)
-   sargable predicates (conditions) can be filtered before results are
    returned
    -   **`S`**earch **`ARG`**ument **`ABLE`**
-   sargable
    -   `where x between '2021/01/01' and '2021/12/31'`
-   non-sargable
    -   `where year(x) = 2021`

## towardsdatascience.com

-   [source](https://towardsdatascience.com/14-ways-to-optimize-bigquery-sql-for-ferrari-speed-at-honda-cost-632ec705979)
-   `exists` better than `count` better than `count distinct`
-   avoid self joins with window functions like `lead()` & `lag()`
-   join on integers better than strings
-   anti-join best as `except distinct` better than `not exists` better
    than `left join` better than `not in`
-   trim data early and often
-   `where` order should be most filtered first (optimizer might handle
    this)
-   use `CREATE TABLE xyz PARTITIONED BY abc CLUSTER BY`
-   only use `ORDER BY` at the final query (if at all) (optimizer might
    handle this)
-   use functions at the end rather than in CTEs (ex.
    `regexp_replace()`)

## www.sqlshack.com

-   [source](https://www.sqlshack.com/query-optimization-techniques-in-sql-server-tips-and-tricks/)
-   replace `join on x or y` with `union all`
-   over-indexing write is slow
-   under-indexing read is slow
-   fewer tables = less cost -\> blocks better than base
-   “left-deep tree” (linear) better than “bushy tree”
    -   bushy: `A join B, A join C, B join D, C join E`
        -   With 12 tables in a bushy query, the math would work out to:
        -   (2n-2)! / (n-1)! = (2\*12-1)! / (12-1)! = 28,158,588,057,600
            possible execution plans.
    -   deep-tree: `A join B, B join C, C join D, D join E`
        -   If the query had been more linear in nature, then we would
            have:
        -   n! = 12! = 479,001,600 possible execution plans.
-   joins that are used to return a single constant can be moved to a
    parameter or variable
-   query hints (SQL server only?)

## bushy vs deep-tree

??? Does this mean we should write our joins a particular way? Does this
apply to Netezza?

<div class="columns">

<div class="column">

Bushy

``` mermaid

%%{init: {'theme': 'base', 'themeVariables': { 'edgeLabelBackground': '#444'}}}%%
flowchart TD
  A1[A] -- visit_key--- B1[B] -- order_key ---C1[C]
  A1 -- pat_key--- D1[D] -- zip_code--- E1[E]
  
  classDef default color:black, fill:white, stroke:black, stroke-width:1px;
  linkStyle default color:#aaa, fill:none, stroke:white, stroke-width:1px;
```

</div>

<div class="column">

Deep Tree

``` mermaid

%%{init: {'theme': 'base', 'themeVariables': { 'edgeLabelBackground': '#444'}}}%%
flowchart TD
  A2[A] --visit_key--- B2[B] -- order_key --- C2[C] -- pat_key --- D2[D] -- zip_code --- E2[E]
  
  classDef default color:black, fill:white, stroke:black, stroke-width:1px;
  linkStyle default color:#aaa, fill:none, stroke:white, stroke-width:1px;
```

</div>

</div>

## www.sqlshack.com

-   [source](https://www.sqlshack.com/query-optimization-techniques-in-sql-server-the-basics/)

    -   `where x like 'abc%'` better than `where left(x, 3) = 'abc'`

-   don’t rely on implcit conversion as it converts everything then
    filters use `where x = '123'` better than `where x = 123`

-   [source](https://www.sqlshack.com/query-optimization-in-sql-server-for-beginners/)

-   trace flags? (not sure what these are)

## www.idug.org

-   [article](https://www.idug.org/browse/blogs/blogviewer?blogkey=bd88bb79-dc28-4b73-be0b-bea9858513f3)
-   [youtube](https://www.youtube.com/watch?v=FIVDmEIjBZA)

## hosteddocs.ittoolbox.com

-   [source](http://hosteddocs.ittoolbox.com/Questnolg22106sqltips.pdf)

## checking

-   you can check with
-   this only holds the last 5K queries in the CDW (can go by quickly)
-   you can explore plans with `show planfile 12345678`

``` sql
select
    qh_tsubmit,
    qh_tstart,
    qh_tend,
    qh_tend::timestamp - qh_tstart::timestamp 
        as runtime_s,           -- > 180s
    qh_estcost,                 -- > 1,000,000
    qh_snippets,                -- > 20
    length(qh_sql) as n_char,  -- > 6000
    qh_resrows,
    qh_resbytes,
    qh_user,
    qh_database,
    qh_sql,
    qh_sessionid,
    qh_planid --planfile id
from 
    _v_qryhist 
where
    qh_user = current_user
order by 
    1 desc
```

## Suggestions for users

-   do transforms in staging table to make `where` statements faster

``` sql
-- faster (stage 1)
where hour_start < 7

-- slower (stage 2)
where hour(query_start_date) < 7
```

-   

## Suggestions for blocks

-   change all mixed case to lower case to avoid
    `where lower(procedure_name) in ()`
-   add fiscal year to applicable blocks

## Record size

-   explain [Record size exceeds internal limit of 65535
    bytes](https://www.ibm.com/support/pages/record-size-exceeds-internal-limit-65535-bytes)

## Resources

You can learn more about SQL optimization here:

-   [Mayank’s
    Tutorial](https://github.research.chop.edu/sardanam/sql-best-practices/blob/master/sql-performance/sql_best_practices.md)

-   

## Appendix

-   group by vs distinct
    https://sqlstudies.com/2017/03/06/using-group-by-instead-of-distinct/
    https://sqlperformance.com/2017/01/t-sql-queries/surprises-assumptions-group-by-distinct

## Open questions

-   do we use indexing?
    -   does stage 1 indexable only work if table is indexed or is
        indexable something that happens at runtime?  
        ex: col between 5 and 10
-   would
    [this](https://dba.stackexchange.com/questions/111584/how-to-increase-etl-performance-in-informatica-for-netezza-as-a-source-and-sql-s)
    help re: informatica?
-   can we use [zone
    maps](https://medium.com/@rleishman/netezza-zone-maps-theyre-the-same-as-indexes-right-fb3249f01cea)

## –END–

``` r
knitr::knit_exit()
```
