use portfolio_project

select location,date,total_cases,total_deaths,population
from covid_deaths


--- Percentage of poeple that died compared to the number of total cases
select 
	location,
	cast(date as date) as date,
	total_cases,
	new_cases,
	total_deaths,
	cast(total_deaths as float)/nullif(cast(total_cases as float),0) * 100 as death_percentage
from covid_deaths
order by 1,2

--- Death percentage in the US
select
	location,cast(date as date) as date, 
	total_cases,
	new_cases,
	total_deaths, 
	cast(total_deaths as float)/nullif(cast(total_cases as float),0) * 100 as death_percentage
from covid_deaths
where location like '%states%'
order by 1,2

--- Death percentage in nigeria
select
	location,cast(date as date) as date, 
	total_cases,
	new_cases,
	total_deaths, 
	cast(total_deaths as float)/nullif(cast(total_cases as float),0) * 100 as death_percentage
from covid_deaths
where location like '%nigeria%'

--- date when highest new cases was recorded in the us
select
	location,cast(date as date) as date, 
	total_cases,
	new_cases,
	total_deaths, 
	cast(total_deaths as float)/nullif(cast(total_cases as float),0) * 100 as death_percentage
from covid_deaths
where location like '%states%'
order by 4 desc


--- date when highest new cases was recorded in nigeria
select
	location,cast(date as date) as date, 
	total_cases,
	new_cases,
	total_deaths, 
	cast(total_deaths as float)/nullif(cast(total_cases as float),0) * 100 as death_percentage
from covid_deaths
where location like '%nigeria%'
order by 4 desc

--- Total cases vs total population

select
	location,
	cast(date as date) date,
	population,
	total_cases,
	(cast(total_cases as float)/ nullif(cast(population as float),0)) * 100 as cases_by_population
from [dbo].[covid_deaths]

order by 1,2

---Country with highest infection rate
select location,
	cast(population as float) as population,
	max(cast(total_cases as float)) as HighestInfection
from
	covid_deaths
where continent != ' '
group by location, population
order by HighestInfection desc

--- The country with the highest infection rate compared to their total population

select
	location,
	cast(population as float) as population,
	max(cast(total_deaths as float))as total_deaths,
	max(cast(total_cases as float)) as HighestInfectionCount,
	max((cast(total_cases as float)/nullif(cast(population as float), 0))*100) as PercentPopulationInfected
from 
covid_deaths
where continent != ' '
group by location, population
order by 5 desc

---Countries with the highest Death count

select
	location, population, max(cast(total_deaths as float)) as HighestDeathCount
from covid_deaths
where continent != ' '
group  by location, population
order by 3 desc

---Countries with the highest Death count per population

select location,
	cast(population as float) as population,
	max(cast(total_deaths as float)) as HighestDeathCount,
	max((cast(total_deaths as float)/nullif(cast(population as float),0))*100) as PercentPopulationDead

from
	covid_deaths
where continent != ' '
group by 
	location, population
order by 4 desc

--- Highest Death count by continent
select continent,
	max(cast(total_deaths as float)) as HighestDeathCount
from
	covid_deaths
where continent != ' '
group by continent
order by HighestDeathCount desc

---Global Death vs Infected
select distinct(location),
	max(cast(total_cases as float)) as total_cases,
	max(cast(total_deaths as float)) as total_deaths,
	(max(cast(total_deaths as float))/nullif(max(cast(total_cases as float)),0))*100 as PercentDeathvsInfected
from covid_deaths
where continent != ' '
group by location

---
select distinct(location),
	sum(cast(new_cases as float)) as total_cases,
	sum(cast(new_deaths as float)) as total_deaths,
	(sum(cast(new_deaths as float))/nullif(sum(cast(new_cases as float)),0))*100 as PercentDeathvsInfected
from covid_deaths
where continent != ' '
group by location
order by 4 desc

---
select
	sum(cast(new_cases as float)) as total_cases,
	sum(cast(new_deaths as float)) as total_deaths,
	(sum(cast(new_deaths as float))/nullif(sum(cast(new_cases as float)),0))*100 as PercentDeathvsInfected
from covid_deaths
where continent != ' '

--- What is the amount of People that were vaccination wrt total population
select *
from
	covid_vaccination
---
select cd.continent, cd.location, cast(cd.date as date) as date, cd.population, cv.new_vaccinations
from covid_deaths as cd
join covid_vaccination as cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent != ' ' 
order by 1,2,3

---using rolling count
select cd.continent,
	cd.location,
	cast(cd.date as date) as date, 
	cd.population, 
	cv.new_vaccinations, 
	sum(cast(cv.new_vaccinations as float)) over (partition by cd.location order by cd.location,cast(cd.date as date)) as cummulativeVaccCount
from covid_deaths as cd
join covid_vaccination as cv
	on cd.location=cv.location
	and cd.date=cv.date
where cd.continent != ' '
and cd.location like '%albania%'
order by 2,3

--- Using CTE to calculate Vaccination by total population
With cumm_table(continent, location, date, population, new_vaccinations,cumm_vac_count)
as
(select cd.continent,
	cd.location,
	cast(cd.date as date) as date, 
	cast(cd.population as float) as population, 
	cv.new_vaccinations, 
	sum(cast(cv.new_vaccinations as float)) over (partition by cd.location order by cd.location,cast(cd.date as date)) as cummulativeVaccCount
from covid_deaths as cd
join covid_vaccination as cv
	on cd.location=cv.location
	and cd.date=cv.date
where cd.continent != ' '
--and cd.location like '%united states%'
)
select *,(cumm_vac_count/nullif(population,0))*100
from cumm_table
order by 1,2,3

---Use Temp Table
drop table if exists #Percent_PeopleVaccinated
create table #Percent_PeopleVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date date,
population float,
new_vaccination float,
cumm_people_vaccinated float
)

insert into #Percent_PeopleVaccinated
select cd.continent,
	cd.location,
	cast(cd.date as date) as date, 
	cast(cd.population as float) as population, 
	cv.new_vaccinations, 
	sum(cast(cv.new_vaccinations as float)) over (partition by cd.location order by cd.location,cast(cd.date as date)) as cummulativeVaccCount
from covid_deaths as cd
join covid_vaccination as cv
	on cd.location=cv.location
	and cd.date=cv.date
where cd.continent != ' '

select *, (cumm_people_vaccinated/nullif(population,0)*100) as PercentPopulationVaccinated
from #Percent_PeopleVaccinated
order by 2,3

--- creating view to store data for Visualization

create view PercentPopulationVaccinated as

select cd.continent,
	cd.location,
	cast(cd.date as date) as date, 
	cast(cd.population as float) as population, 
	cv.new_vaccinations, 
	sum(cast(cv.new_vaccinations as float)) over (partition by cd.location order by cd.location,cast(cd.date as date)) as cummulativeVaccCount
from covid_deaths as cd
join covid_vaccination as cv
	on cd.location=cv.location
	and cd.date=cv.date
where cd.continent != ' '

select *
from PercentPopulationVaccinated