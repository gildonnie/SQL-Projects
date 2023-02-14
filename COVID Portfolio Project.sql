USE CovidPortfolio;
SELECT * 
FROM CovidPortfolio..CovidDeaths
ORDER BY 3,4;

--SELECT * FROM CovidPortfolio..CovidVaccanations
--ORDER BY 3,4;

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidPortfolio..CovidDeaths
ORDER BY 1, 2;

--total cases vs total deaths
--percentage of dying if contracting covid in your country
SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases) * 100, 1) AS DeathPercentage
FROM CovidPortfolio..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1, 2;

--looking at total cases vs population
--shows what percentage of the populatin got covid
SELECT location, date, total_cases, population, ROUND((total_cases/population) * 100, 1) AS DeathPercentage
FROM CovidPortfolio..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1, 2;

--countries with highest infection rate compared  by population
SELECT location, MAX(total_cases) AS HighestInfectionCount, population, ROUND(MAX((total_cases/population)) * 100, 1) AS PercentPopulationInfected
FROM CovidPortfolio..CovidDeaths
GROUP BY location, population
--WHERE location LIKE '%states%'
ORDER BY PercentPopulationInfected DESC;

--countries with the highest mortality per population
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidPortfolio..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC;

--Continent with the highest mortality per population
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidPortfolio..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC;

--global numbers/ removing date gives total cases, deaths and percentage since covid started
SELECT date, SUM(new_cases) AS TotalGlobalCases, SUM(CAST(new_deaths AS INT)) TotalGlobalDeaths, ROUND(SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100, 2) AS DeathPercentage
FROM CovidPortfolio..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1, 2;



--looking at total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
(RollingPeopleVaccinated/population) * 100
FROM CovidPortfolio..CovidDeaths dea
JOIN CovidPortfolio..CovidVaccanations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--AND dea.location LIKE '%states%'
ORDER BY 2, 3;

--using CTE
With PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population) * 100
FROM CovidPortfolio..CovidDeaths dea
JOIN CovidPortfolio..CovidVaccanations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--AND dea.location LIKE '%states%'
--ORDER BY 2, 3
)
SELECT *, ROUND((RollingPeopleVaccinated/population) * 100, 1)
FROM PopVsVac;



--temp table
DROP TABLE IF EXISTS #PercentPopulationsVaccinated
CREATE TABLE #PercentPopulationsVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationsVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population) * 100
FROM CovidPortfolio..CovidDeaths dea
JOIN CovidPortfolio..CovidVaccanations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--AND dea.location LIKE '%states%'
--ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated/population) * 100
FROM #PercentPopulationsVaccinated;


--creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population) * 100
FROM CovidPortfolio..CovidDeaths dea
JOIN CovidPortfolio..CovidVaccanations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--AND dea.location LIKE '%states%'
--ORDER BY 2, 3

SELECT *
FROM PercentPopulationVaccinated