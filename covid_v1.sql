-- DATA EXPLORATION
SELECT top(5) *
FROM PortfolioProjects..CovidDeaths

SELECT top (5) *
FROM PortfolioProjects..CovidVaccinations

-- coverting nvarchar to float
-- finding the Total cases vs Total deaths
--probality of dying if you contact covid in Nigeria

--Total cases vs Total deaths
SELECT continent, location, date, total_cases, total_deaths, CEILING((cast(total_deaths AS float)/cast(total_cases as float))*100 * 100) / 100 as death_percentage
FROM PortfolioProjects..CovidDeaths
WHERE total_cases is not null and total_deaths is not null and continent is not null
ORDER BY 1,2,5 desc


--Total cases vs Total deaths in Nigeria_i.e likelihood of dying if covid 19 is contacted in Nigeria
SELECT location, date, total_cases, total_deaths, CEILING((cast(total_deaths as float) / CAST(total_cases as float)) * 100 * 100) / 100 as death_percentage
FROM PortfolioProjects..CovidDeaths
WHERE location = 'Nigeria'and total_cases is not null and total_deaths is not null and continent is not null
ORDER BY 1,2,5 desc;

--countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) as highest_infection_count, CEILING(MAX((cast(total_cases as float)/population))*100 * 100) / 100 as percentage_population_infected
FROM PortfolioProjects..CovidDeaths
where continent is not null and continent is not null
GROUP BY location, population
ORDER BY percentage_population_infected desc;

--countries with highest death count
SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM PortfolioProjects..CovidDeaths
where continent is not null
GROUP BY location
ORDER BY total_death_count desc;

--countries with highest death count per population
SELECT location, population, MAX(cast(total_deaths as int)) as total_death_count, CEILING(MAX((cast(total_deaths as int)/population))*100  * 100) / 100 as percentage_death_per_country
FROM PortfolioProjects..CovidDeaths
where continent is not null
GROUP BY location, population
ORDER BY total_death_count desc;


--countries percentage death rate to population
SELECT location, population, max(total_deaths) as total_death_count, max((cast(total_deaths as int)/population))*100 as percentage_death_per_country
FROM PortfolioProjects..CovidDeaths
where continent is not null
GROUP BY location, population
ORDER BY percentage_death_per_country desc;

--showing continents with the highest death count
SELECT continent, MAX(cast(total_deaths as int)) as total_death_count
FROM PortfolioProjects..CovidDeaths
where continent is not null
GROUP BY continent
ORDER BY total_death_count desc;

--showing continents & countries with the highest death count
SELECT continent, location,  MAX(cast(total_deaths as int)) as total_death_count
FROM PortfolioProjects..CovidDeaths
where continent is not null and total_deaths is not null
GROUP BY location, continent
ORDER BY total_death_count desc;


--showing continents & countries with the highest infection count
SELECT continent, location,  MAX(cast(total_cases as int)) as total_infection_count
FROM PortfolioProjects..CovidDeaths
where total_cases is not null and continent is not null
GROUP BY continent, location
ORDER BY total_infection_count desc;

--global numbers (not using ">0" didn't work - divide by zero error)
--total daily global new cases to percentage death
SELECT date, SUM(new_cases) as total_new_cases, SUM(new_deaths) as total_deaths, CEILING((SUM(new_deaths)/SUM(new_cases))*100 * 100) / 100 as global_death_percentage
FROM PortfolioProjects..CovidDeaths
WHERE --continent is not null
new_cases >0
and new_deaths >0
GROUP BY date
ORDER BY 1,2;

--looking at total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM  PortfolioProjects..CovidDeaths as dea
JOIN PortfolioProjects..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 1,2,3;

--partition by simple implies break up by
-- to change date type, use CAST(variable as int) or CONVERT(int, variable)


--Analysing the total percentage vaccinated
--using convert function instead of cast function to change data type
-- cannot use a created column as an aggregate variable, i.e cumm_vaccinations can't be used as an aggregate except in CTE or temp tables


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, sum(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location
, dea.date) as cumm_vaccinations
--, (cumm_vaccinations/population)*100
FROM  PortfolioProjects..CovidDeaths as dea
JOIN PortfolioProjects..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
and vac.new_vaccinations is not null
ORDER BY 2,3;

--creating CTE CTE, NB: number of columns must be same

with PopvsVac (continent, location, date, population, new_vaccinations, cumm_vaccinations)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, sum(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location
, dea.date) as cumm_vaccinations
--, (cumm_vaccinations/population)*100
FROM  PortfolioProjects..CovidDeaths as dea
JOIN PortfolioProjects..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
and vac.new_vaccinations is not null
--ORDER BY 2,3
)
SELECT *, (cumm_vaccinations/population)*100 as per_vaccinated
FROM PopvsVac

--using a TEMP TABLE to same new column aggregation.NB: #stands for TEMP TABLE

DROP table if exists #perPopulationVaccinnated
CREATE TABLE #perPopulationVaccinnated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
cumm_vaccinations numeric
)
insert into #perPopulationVaccinnated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, sum(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location
, dea.date) as cumm_vaccinations
--, (cumm_vaccinations/population)*100
FROM  PortfolioProjects..CovidDeaths as dea
JOIN PortfolioProjects..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
and vac.new_vaccinations is not null
--ORDER BY 2,3

SELECT *, (cumm_vaccinations/population)*100
FROM #perPopulationVaccinnated

--creating view for later visualization

CREATE view perPopulationVaccinnated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, sum(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location
, dea.date) as cumm_vaccinations
--, (cumm_vaccinations/population)*100
FROM  PortfolioProjects..CovidDeaths as dea
JOIN PortfolioProjects..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
and vac.new_vaccinations is not null
--ORDER BY 2,3

SELECT *
FROM perPopulationVaccinnated