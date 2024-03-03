SELECT * FROM coviddeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

SELECT * FROM covidvaccinations
ORDER BY 3,4;

-- Select Data that we're gonna be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 DeathPercentage
FROM coviddeaths
WHERE location like '%orea%'
AND continent IS NOT NULL
ORDER BY total_cases DESC;

-- Looking at Total Cases vs Population
-- Shows what percentage of populaton got Covid
SELECT location, date, population, total_cases, (total_cases/population)*100 InfectionPercentage
FROM coviddeaths
-- WHERE location like '%state%'
ORDER BY total_cases DESC;

-- Looking at Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) HighestInfactionCount, MAX(total_cases/population)*100 PercentPopulationInfected
FROM coviddeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Showing Countries with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS SIGNED INTEGER)) TotalDeathCount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- LET'S BREAK THINGS DOWN BY COUNTINENT
SELECT continent, MAX(CAST(total_deaths AS SIGNED INTEGER)) TotalDeathCount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Showing continent with the highest death count per population
-- Change data type from text to integer
SELECT continent, MAX(CAST(total_deaths AS SIGNED INTEGER)) TotalDeathCount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Global Numbers
SELECT SUM(new_cases) Total_Cases, SUM(new_deaths) New_Deaths, SUM(new_deaths)/SUM(new_cases)*100 DeathPercentage
FROM coviddeaths
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1, 2;


-- Looking at Total Population vs Vacconations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location 
--     AND dea.continent = vac.continent
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.continent <> ''
ORDER BY 2,3;

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) OVER (partition by dea.location ORDER BY dea.location, dea.date) RollingPeopleVaccinated
-- ,(RollingPeopleVaccinated/population)*100
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location 
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.continent <> ''
ORDER BY 2,3;

-- Use CTE
WITH PopvsVac  (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) OVER (partition by dea.location ORDER BY dea.location, dea.date) RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location 
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.continent <> ''
ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac;

-- TEMP TABLE
DROP TABLE IF EXISTS Temp_PercentPopulationVaccinated;
CREATE TEMPORARY TABLE Temp_PercentPopulationVaccinated
(
Continent VARCHAR(255),
Location VARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_Vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
);
INSERT INTO Temp_PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) OVER (partition by dea.location ORDER BY dea.location, dea.date) RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location 
    AND dea.date = vac.date;
-- WHERE dea.continent IS NOT NULL AND dea.continent <> ''
-- ORDER BY 2, 3;

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM Temp_PercentPopulationVaccinated;

-- Creating View to store data for later visulization
CREATE View PercentagePopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) OVER (partition by dea.location ORDER BY dea.location, dea.date) RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location 
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.continent <> ''
ORDER BY 2, 3;

SELECT *
FROM PercentagePopulationVaccinated

