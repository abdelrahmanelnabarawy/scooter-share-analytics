select * from rides

select * from stations

select * from users

-- get count of rows per table

;with count_rides AS(

select count (*) AS total_rides from rides),
     count_stations AS(
select count (*) AS total_stations from stations),
     count_users AS(
select count (*) AS total_users from users)

select * from count_rides, count_stations, count_users
 
-- count for missing values

;with missing_values AS(
   SELECT
        count(case when ride_id IS NULL then 1 END) AS null_ride_ids, 
        count(case when user_id IS NULL then 1 END) AS null_user_ids ,
        count(case when start_time IS NULL then 1 END) AS null_station_ids, 
        count(case when end_time IS NULL then 1 END) AS null_user_idss 

  from rides
)
select * from missing_values

-- Summary Statistics for rides table

;with summary_stat AS(
 select

 MIN(distance_km) AS min_dis,
 MAX(distance_km) AS max_dis,
 AVG(distance_km) AS avg_dis,
 MIN(DATEDIFF(MINUTE, start_time, end_time)) AS min_duration_min,
 MAX(DATEDIFF(MINUTE, start_time, end_time)) AS max_duration_min,
 AVG(DATEDIFF(MINUTE, start_time, end_time)) AS avg_duration_min

from rides
)
select * from summary_stat

-- checking for the false starts in the rides

;with false_rides AS(

select *,
DATEDIFF(MINUTE, start_time, end_time) AS ride_duration
from rides
)
select
 sum(case when ride_duration <2 then 1 else 0 END) AS short_rid,
 sum(case when distance_km =0 then 1 else 0 END) AS zero_dis_rid
 from false_rides


-- different memberhip

;with diff_membership AS(
select
 u.membership_level,
 count(r.ride_id) AS total_rides,
 AVG(r.distance_km) AS avg_distance,
 AVG(DATEDIFF(MINUTE, r.start_time, r.end_time)) AS avg_duration_min
from rides r JOIN users u
ON r.user_id = u.user_id
group by u.membership_level
)

select *
from diff_membership
order by total_rides DESC

-- peak hours
;with peak_hour AS(
select 
  DATEPART(HOUR, start_time) AS hour_of_day,
  COUNT(*) AS count_rides
from rides
group by DATEPART(HOUR, start_time)

)
select * from peak_hour
order by hour_of_day

-- check for popular stations

;with popular_stat AS(

select 
s.station_name,
COUNT(r.ride_id) AS total_starts 
from rides r JOIN stations s
ON r.start_station_id = s.station_id
group by s.station_name
)

select top 10 *
from popular_stat
order by total_starts DESC

-- categorizing rides into Short, Medium and Long

;with ride_cat AS(
select *,
   case
   when DATEDIFF(MINUTE, start_time, end_time) <=10 then 'Short (<10m)'
   when DATEDIFF(MINUTE, start_time, end_time) between 11 and 30 then 'Medium (11-30m)'
   else 'Long'
   END AS ride_category
from rides

)
select 
count(*) AS ride_count,  
ride_category,
AVG(DATEDIFF(MINUTE, start_time, end_time)) AS avg_duration_min
from ride_cat
group by ride_category
order by ride_count DESC

--- net flow for each stations

;with departures AS(
 
 select start_station_id, COUNT(*) AS total_departures
  from rides
 group by start_station_id
 ),
 
 arrivals AS(
 select end_station_id, COUNT(*) AS total_arrivals
   from rides
 group by end_station_id
 )

 select
 s.station_name,
 d.total_departures,
 a.total_arrivals,
 (a.total_arrivals - d.total_departures) AS net_flow
 from stations s
 join departures d on s.station_id = d.start_station_id
 join arrivals a on s.station_id = a.end_station_id

order by net_flow ASC

--- user retention

;with monthly_signups AS(

 SELECT DATETRUNC(MONTH, created_at) AS signup_month,
 COUNT(user_id) AS new_user_count
 from users
group by  DATETRUNC(MONTH, created_at)
)

select
signup_month,
new_user_count,
LAG(new_user_count) over (order by signup_month) AS previous_month_count,

(CAST(new_user_count - LAG(new_user_count) OVER (ORDER BY signup_month) AS FLOAT)
        / NULLIF(LAG(new_user_count) OVER (ORDER BY signup_month), 0)) * 100 AS mom_growth
from monthly_signups
order by signup_month DESC