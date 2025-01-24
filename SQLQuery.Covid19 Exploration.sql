/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

select count(*)
from PortfolioProject..CovidDeaths

select count(*)
from PortfolioProject..CovidVaccinations

select *
from PortfolioProject..CovidDeaths
where continent is not null
order by 3,4

select *
from PortfolioProject..CovidVaccinations
where continent is not null
order by 3,4

-- Select Data that we are going to be starting with

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in 'United States' or 'China'


select Location, date, total_cases, total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0))*100 as DeathPercentage
from PortfolioProject..CovidDeaths
order by 1,2

select location, date, total_cases, total_deaths,
(CONVERT(float, total_deaths) / nullif(CONVERT(float, total_cases), 0))*100 as DeathPertage
from PortfolioProject..CovidDeaths
where location like '%states%'
and continent is not null
order by 1,2

select location, date, total_cases, total_deaths, 
(convert(float,total_deaths)/nullif(convert(float,total_cases),0))*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%China%'
and continent is not null
order by 1,2

select location, date, total_cases, total_deaths, 
round(total_deaths/nullif(total_cases,0)*100,2) as DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%China%'
and continent is not null
order by 1,2

select location, date, total_cases, total_deaths, 
(cast(total_deaths as float)/nullif(cast(total_cases as int),0))*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%China%'
and continent is not null
order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

select location, date, total_cases, population,
round((total_cases / population)*100,2) as PercentPopulationInfected
from PortfolioProject..CovidDeaths
--where location like '%states%'
order by 1,2

-- Countries with Highest Infection Rate compared to Population

select location, population,max(total_cases) as HighestInfectionCount,
max(round((total_cases/population)*100,2)) as PercentPopulationInfected
from PortfolioProject..CovidDeaths
--where location like '%states%'
group by location, population
order by PercentPopulationInfected desc


-- Countries with Highest Deaths Rate compared to Population

select location, population, max(total_deaths) as HighestDeathCount,MAX(cast(Total_deaths as int)) as TotalDeathCount,
max((convert(float,total_deaths)/population)*100) as PercentPopulationDeath
from PortfolioProject..CovidDeaths
group by location, population
order by PercentPopulationDeath desc


-- Countries with Highest Death Count per population

Select Location,population,MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location,population
order by TotalDeathCount desc

select location,max(convert(float,total_deaths)) as TotalDeathCount
from PortfolioProject..CovidDeaths
group by location
order by TotalDeathCount desc

select location,max(convert(float,total_deaths)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where location like '%india%'
group by location
order by TotalDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS

select continent, sum(cast(new_cases as float)) as total_cases, sum(cast(new_deaths as float)) as total_deaths,
sum(cast(new_deaths as float))/sum(cast(new_cases as float))*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null 
Group By continent
order by 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- What is the rolling count of people vaccinated, meaning after each day what is the total number of vaccinated people
-- using CTE

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingCountofPeopleVaccinated)
AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location order by dea.location, dea.date) AS RollingCountofPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location AND dea.date = vac.date
where dea.continent IS NOT NULL)

SELECT *, (RollingCountofPeopleVaccinated*1.0/population) * 100 AS PercentageofVaccinatedPeople
FROM PopVsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentagePopulationVaccinated

Create Table #PercentagePopulationVaccinated
(continent NVARCHAR(255),
location NVARCHAR(255),
date DATE,
population NUMERIC,
new_vaccinations NUMERIC,
RollingCountofPeopleVaccinated NUMERIC
)

INSERT INTO #PercentagePopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(new_vaccinations AS BIGINT))
OVER (PARTITION BY dea.location order by dea.location, dea.date) AS RollingCountofPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac 
    ON dea.location = vac.location AND dea.date = vac.date
where dea.continent IS NOT NULL

--Create views to store our results and later use for visualizations 

Create view MortalityRate AS
select continent, location,date, total_cases,total_deaths,(total_deaths/total_cases)*100 as Mortality_Rate
from PortfolioProject..CovidDeaths
where continent is not null

Create View PercentagePopulationInfected AS 
SELECT continent, location, date, total_cases, population, (total_cases /population) * 100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE Continent is not NULL

Create View HighestInfectedCountry AS 
SELECT continent, location, population, Max(total_cases) as highestInfectionCount, MAX((total_cases * 1.0/population)*100) as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE Continent is not NULL
Group by continent, location, population

Create View HighestDeathperPopulation AS 
SELECT continent, location, population, MAX(total_deaths) as hightestDeathCount, MAX((total_deaths * 1.0/population)*100) as PercentPopulationDied
FROM PortfolioProject..CovidDeaths
WHERE Continent is not NULL
Group by continent, location, population

Create View hightestDeathCountLocation AS 
SELECT continent, location, MAX(total_deaths) as hightestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE CONTINENT IS NOT NULL 
Group by continent, location

Create View HighestDeathCountContinent AS 
SELECT continent, MAX(total_deaths) as hightestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE CONTINENT IS NOT NULL 
Group by continent

Create View GlobalCasesPerDay AS 
SELECT date, sum(cast(new_cases as float)) as total_cases, sum(cast(new_deaths as float)) as total_deaths,
    case
        WHEN sum(cast(new_cases as float)) <> 0 THEN sum(cast(new_deaths as float))*1.0/sum(cast(new_cases as float))*100 
        ELSE NULL
    END AS death_rate
FROM PortfolioProject..CovidDeaths
WHERE Continent is not NULL
GROUP BY DATE

Create View RollingCountofPeopleVaccinated AS 
WITH PopVsVac (continent, location, date, population,  new_vaccinations, RollingCountofPeopleVaccinated)
AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(new_vaccinations AS BIGINT))
OVER (PARTITION BY dea.location order by dea.location, dea.date) AS RollingCountofPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac 
    ON dea.location = vac.location AND dea.date = vac.date
where dea.continent IS NOT NULL)
SELECT *, (RollingCountofPeopleVaccinated*1.0/population) * 100 AS PercentageofVaccinatedPeople
FROM PopVsVac

