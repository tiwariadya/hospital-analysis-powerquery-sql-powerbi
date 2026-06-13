# OBJECTIVE 1: ENCOUNTERS OVERVIEW
# a. How many total encounters occurred each year?

select year(str_to_date(start, '%d-%m-%Y %H:%i')) as encounter_year,
       count(*) as total_encounters
from encounters
group by year(str_to_date(start, '%d-%m-%Y %H:%i'))
order by encounter_year;


# b. For each year, what percentage of all encounters belonged to each encounter class
# (ambulatory, outpatient, wellness, urgent care, emergency, and inpatient)?

select year(str_to_date(start,'%d-%m-%Y %H:%i'))  as encounter_year,
       encounter_class,
       count(*) as total_encounters, 
       round (
              count(*) * 100.0/sum(count(*)) over ( 
           partition by year(str_to_date(start,'%d-%m-%Y %H:%i'))
           ),2
	   ) as percentage_of_year
from encounters
group by year(str_to_date(start,'%d-%m-%Y %H:%i')), encounter_class
order by encounter_year, percentage_of_year desc;
           
# c. What percentage of encounters were over 24 hours versus under 24 hours?

select case when
           timestampdiff(
           hour,
           str_to_date(start,'%d-%m-%Y %H:%i'),
           str_to_date(stop,'%d-%m-%Y %H:%i')
           ) > 24
           then "over 24 Hours"
           else "under 24 Hours"
           end as encounter_category,
       count(*) as encounter_count,
       round(
             count(*)*100.0 / sum(count(*)) over(),2
       ) as percentage 
       from encounters 
       group by encounter_category;
       
# OBJECTIVE 2: COST & COVERAGE INSIGHTS
# a. How many encounters had zero payer coverage and what percentage of total encounters does this represent?

select count(*) as zero_coverage_encounter,
round (
       count(*) * 100.0 / 
       (select count(*) from encounters),2
       ) as percentage_of_total
from encounters 
where payer_coverage = 0;

# b. What are the top 10 most frequent procedures performed and the average base cost for each?
 
select description,
        count(*) as procedure_frequency,
        round( avg(base_cost),2) as avg_base_cost
from procedures
group by description
order by procedure_frequency desc limit 10;

# c. What are the top 10 procedures with the highest average base cost and the number of times they were performed?

select description,
       round(avg(base_cost), 2) as avg_base_cost,
       count(*) as times_performed
from procedures
group by description
order by avg_base_cost desc limit 10;

#d. What is the average total claim cost for encounters, broken down by payer?

select payer,
	   round(avg(total_claim_cost), 2) as average_total_claim_cost
from encounters 
group by payer
order by average_total_claim_cost desc;

# OBJECTIVE 3: PATIENT BEHAVIOR ANALYSIS
# a. How many unique patients were admitted each quarter over time?

select 
	   year(str_to_date(start, '%d-%m-%Y %H:%i')) as encounter_year,
       quarter(str_to_date(start, '%d-%m-%Y %H:%i')) as encounter_quarter,
       count(distinct patient) as unique_patient
from encounters 
group by encounter_year, encounter_quarter
order by encounter_year, encounter_quarter;

# b. How many patients were readmitted within 30 days of a previous encounter?

with encounter_history as (
     select patient,
			str_to_date(start,'%d-%m-%Y %H:%i') as encounter_date,
            lag(str_to_date(start,'%d-%m-%Y %H:%i'))
            over(
                 partition by patient 
                 order by str_to_date(start,'%d-%m-%Y %H:%i')
		    ) as previous_encounter_date
	from encounters)
select count(distinct patient) AS readmitted_patients
from encounter_history
where datediff(encounter_date, previous_encounter_date) <=30;
    
# c. Which patients had the most readmissions?
with encounter_history as (
     select patient,
            str_to_date(start,'%d-%m-%Y %H:%i') as encounter_date,
            lag(str_to_date(start,'%d-%m-%Y %H:%i'))
	 over (partition by patient
	      order by str_to_date(start,'%d-%m-%Y %H:%i')
        ) as previous_encounter_date
    from encounters
)
select patient,
       count(*) as readmission_count
from encounter_history
where datediff(
	   encounter_date,
	   previous_encounter_date
      ) <= 30
group by patient
order by readmission_count desc;




