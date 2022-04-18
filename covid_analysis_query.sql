use portfolio_project

select location,date,total_cases,total_deaths,population
from covid_deaths

---We need to change the datatype of the data
alter table covid_deaths
alter column date date
go

alter table covid_deaths
alter column population float
go

alter table covid_deaths
alter column new_cases float
go

alter table covid_deaths
alter column new_deaths float
go

alter table covid_deaths
alter column total_cases float
go

alter table covid_deaths
alter column total_deaths float
go

--- Percentage of poeple that died compared to the number of total cases
select 
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	total_deaths/nullif(total_cases ,0) * 100 as death_percentage
from covid_deaths
order by 1,2

--- Death percentage in the US
select location, 
	date, 
	total_cases,
	new_cases,
	total_deaths, 
	(total_deaths/nullif(total_cases,0)) * 100 as death_percentage
from covid_deaths
where location like '%states%'
order by 1,2

--- Death percentage in nigeria
select location,
	date, 
	total_cases,
	new_cases,
	total_deaths, 
	(total_deaths /nullif(total_cases,0)) * 100 as death_percentage
from covid_deaths
where location like '%nigeria%'

--- date when highest new cases was recorded in the us
select location,
	date, 
	total_cases,
	new_cases,
	total_deaths, 
	(total_deaths /nullif(total_cases,0)) * 100 as death_percentage
from covid_deaths
where location like '%states%'
order by 4 desc


--- date when highest new cases was recorded in nigeria
select location,
	date,
	total_cases,
	new_cases,
	total_deaths, 
	(total_deaths/nullif(total_cases,0)) * 100 as death_percentage
from covid_deaths
where location like '%nigeria%'
order by 4 desc

--- Total cases vs total population

select
	location,
	date,
	population,
	total_cases,
	(total_cases / nullif(population,0)) * 100 as cases_by_population
from [dbo].[covid_deaths]

order by 1,2

---Country with highest infection rate
select location,
	population,
	max(total_cases) as HighestInfection
from
	covid_deaths
where continent != ' '
group by location, population
order by HighestInfection desc

--- The country with the highest infection rate compared to their total population
select
	location,
	population,
	max(total_cases) as HighestInfectionCount,
	max(total_cases/nullif(population, 0)*100) as PercentPopulationInfected
from 
covid_deaths
where continent != ' '
group by location, population
order by 4 desc

---Countries with the highest Death count
select
	location, population, max(total_deaths) as HighestDeathCount
from covid_deaths
where continent != ' '
group  by location, population
order by 3 desc

---Countries with the highest Death count per population
select location,
	population,
	max(total_deaths) as HighestDeathCount,
	max((total_deaths /nullif(population,0))*100) as PercentPopulationDead
from
	covid_deaths
where continent != ' '
group by 
	location, population
order by 4 desc

--- Highest Death count by continent
select continent,
	max(total_deaths) as HighestDeathCount
from
	covid_deaths
where continent != ' '
group by continent
order by HighestDeathCount desc

--- Death count vs Infected count
select (location),
	sum(new_cases) as total_cases,
	sum(new_deaths) as total_deaths,
	(sum(new_deaths)/nullif(sum(new_cases),0))*100 as PercentDeathvsInfected
from covid_deaths
where continent != ' '
group by location
order by 4 desc

--- What is the amount of People that were vaccination wrt total population
select *
from
	covid_vaccination
--- Changing the datatype of some columns in the dataset
alter table covid_vaccination
alter column date date
go

alter table covid_vaccination
alter column new_vaccinations float
go

---
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
from covid_deaths as cd
join covid_vaccination as cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent != ' ' 
order by 1,2,3

---using 'Partition by' to calculate the cummulative count of vaccinations by location
select cd.continent,
	cd.location,
	cd.date, 
	cd.population, 
	cv.new_vaccinations, 
	sum(cv.new_vaccinations) over (partition by cd.location order by cd.location,cd.date) as cummulativeVaccCount
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
	cd.date, 
	cd.population, 
	cv.new_vaccinations, 
	sum(cv.new_vaccinations) over (partition by cd.location order by cd.location, cd.date) as cummulativeVaccCount
from covid_deaths as cd
join covid_vaccination as cv
	on cd.location=cv.location
	and cd.date=cv.date
where cd.continent != ' '
--and cd.location like '%united states%'
)
select *,(cumm_vac_count/nullif(population,0)) *100 as PercentPopluationVaccinated
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
	cd.date, 
	cd.population, 
	cv.new_vaccinations, 
	sum(cv.new_vaccinations) over (partition by cd.location order by cd.location,cd.date) as cummulativeVaccCount
from covid_deaths as cd
join covid_vaccination as cv
	on cd.location=cv.location
	and cd.date=cv.date
where cd.continent != ' '

select *, (cumm_people_vaccinated/nullif(population,0)*100) as PercentPopulationVaccinated
from #Percent_PeopleVaccinated
order by 2,3


--- creating view to store data for Visualization

create view PercentPopVaccinated as

select cd.continent,
	cd.location,
	cd.date, 
	cd.population, 
	cv.new_vaccinations, 
	sum(cv.new_vaccinations) over (partition by cd.location order by cd.location,cd.date) as cummulativeVaccCount
from covid_deaths as cd
join covid_vaccination as cv
	on cd.location=cv.location
	and cd.date=cv.date
where cd.continent != ' '

select *
from PercentPopVaccinated
