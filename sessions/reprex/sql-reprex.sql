-- can use select alone, no 'from' statement
select 123
;
-- mock-up date differences
select
    current_date - 2 as encounter_date,
    current_timestamp as surgery_time, -- also now()
    surgery_time::date - encounter_date as n_days,
    datetime(timezone(now(),  'UTC', 'America/New_York')) as time_utc    
;
-- mock-up note_text
select
    'I want the second word' as note_text,
    regexp_extract(note_text, '\w+', 1, 2) as second_word
;
-- complex regex
with 
    clinic_list as (
              select '555-123-4567' as phone_number
        union select '555.123.4567'
        union select '(555)123-4567'
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
;    
-- put subset in qmr_dev for someone to help you
-- if it does require a few CTEs to get to your output
create table abc as 
with
    x as (
       select 
       from
    )

    , y as (
       select 
       from
    ) -- select * from y;

    , z as (
       select 
       from
    )

select *
from ...


drop table abc;


--



;
-- not using  
select --* from clinical_concept limit 10;
    -- rename categories
    data_type as surgical_service, 
    count(distinct upd_by) as n_panel,
    count(*) as n_cases,
    -- use keys to mimic numeric values
    avg(concept_key/1000) as mean, 
    percentile_cont(0.5) within group (order by concept_key/1000) as median,
    -- date fields you can use
    max(create_dt)::date as encounter_date, 
    year(add_months(encounter_date, 6)) as first_fy
from cdwuat.admin.clinical_concept
group by data_type 
order by encounter_date
;