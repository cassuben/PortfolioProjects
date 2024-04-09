SELECT * FROM CovidDeaths
WHERE continent is not null


-- SELECT * FROM CovidVaccinations
-- ORDER BY 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2


-- Looking at Total Cases vs Total Deaths
-- Show likelihood of dying if you contract covid in your country

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
Where location like '%states%'
ORDER BY 1,2


-- Looking at Total Case vs Population
-- Shows what percentage of population got Covid

SELECT Location, date, population, total_cases,	(total_cases/population)*100 as PercentofPopulationInfected
FROM PortfolioProject..CovidDeaths
Where location like '%states%'
ORDER BY 1,2


-- Looking at Countries with highest infection rate compared to Population

SELECT Location, population, MAX(total_cases) as HighestInfectionCount,	MAX((total_cases/population))*100 as PercentofPopulationInfected
FROM PortfolioProject..CovidDeaths
-- WHERE location like '%states%'
GROUP BY location, population
ORDER BY 4 DESC


-- Showing the Countries with the Highest Death Count per Population

SELECT location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC


 -- Let's break things down by Continent
 -- This syntax provides the ACTUAL Death Counts by Continent

SELECT location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC

 -- Let's break things down by Continent
 -- This syntax provides the Death Counts by Continent that were used in the model

SELECT continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC



-- Global Numbers

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2


-- THIS IS MY FIRST JOIN BETWEEN THE TWO TABLES - TAKE NOTE OF HOW THE TABLEs ARE JOINED AND WHAT FIELDS THEY REFERENCE
-- AFTER I RAN THE JOIN, I VERIFIED THE DATA WAS JOINED PROPERLY BY SCROLLING TO THE NEXT DATE FIELD AND VERIFYING A MATCH
-- The dea and vac are aliases created so we don't have to continually type the entire table name

SELECT *
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date;

-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 1,2,3

-- Looking at Total Population vs Vaccinations, adding a column that calcualtes the sum of all vaccinations
-- To add a sum column, I used the PARTITION BY function by location so the SUM would be parsed by country and not continue to add up all countries

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date)
 AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- Looking at total population vaccinated by dividing the Rolling SUM of vaccinations by total population
-- USE CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date)
 AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac;


-- TEMP TABLE

--DROP table if exists #PercentPopulationVaccinated
USE PortfolioProject
GO
Create Table PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert Into PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date)
 AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PercentPopulationVaccinated


-- CREATING A VIEW 

-- DROP VIEW if exists HighestDeathCountByContinent
USE PortfolioProject
GO
CREATE VIEW HighestDeathCountByContinent AS
SELECT continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
--ORDER BY TotalDeathCount DESC;


-- HIGHLY RECOMMEND CREATING A BUNCH OF DIFFERENT VIEWS SO THEY CAN BE USED IN TABLEAU PUBLIC
