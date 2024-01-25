--CREATE DATABASE PortfolioProject;

--Took 2 Excels from main Data
--CovidDeath and CovidVacc.


--SELECT *
--FROM [dbo].[CovidDeaths]

--SELECT *
--FROM [dbo].[CovidVaccinations]

SELECT [location],[date],[total_cases],[new_cases],[total_deaths],[population]
FROM [dbo].[CovidDeaths]
ORDER BY 1,2

--Looking into Total cases VS Total Deaths
--Showing likelihood of dying if you contract covid in your country

SELECT [location],[date],[total_cases],[new_cases],[total_deaths],
TRY_CONVERT(FLOAT,total_deaths) / TRY_CONVERT(FLOAT,total_cases)*100 AS DeathPercentage
FROM [dbo].[CovidDeaths]
WHERE location LIKE 'INDIA'
ORDER BY 1,2

--Looking at the total cases VS population
--Show what percentage of population got Covid
SELECT [location],[date],[total_cases],[population],(total_deaths/population)*100 AS CovidPercentage
FROM [dbo].[CovidDeaths]
WHERE location LIKE 'INDIA' 
ORDER BY 1,2

--Looking at countries with higest infection rate campared to population
SELECT [location],[population],MAX([total_cases]) AS HighestInfectionCount,MAX((total_cases/population))*100 AS PercentagePopulationInfected
FROM [dbo].[CovidDeaths]
--WHERE location LIKE 'INDIA' 
GROUP BY location , population
ORDER BY PercentagePopulationInfected DESC

--Countries with higest death count per population
SELECT [location],MAX([total_deaths]) AS TotalDeaths--,MAX((total_deaths/population))*100 AS PercentagePopulationDied
FROM [dbo].[CovidDeaths]
--WHERE location LIKE 'INDIA' 
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeaths DESC --PercentagePopulationDied DESC


-- Lets break this down CONTINENT

SELECT continent,MAX(cast(total_deaths AS INT)) AS TotalDeaths
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeaths DESC

--GLOBAL Numbers
SELECT date,
    SUM(new_cases) AS Sumofnewcases,
    SUM(CAST(new_deaths AS INT)) AS SumofnewDeaths,
    SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY 1,2;

--Total Numbers
SELECT
    SUM(new_cases) AS Sumofnewcases,
    SUM(CAST(new_deaths AS INT)) AS SumofnewDeaths,
    SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL 
ORDER BY 1,2;


--Looking at total population by Vaccinations

SELECT 
    DEA.continent,
    DEA.locationn,
    DEA.datee,
    population,
    new_vaccinations,
    SUM(CONVERT(BIGINT, new_vaccinations)) 
	OVER (PARTITION BY DEA.locationn ORDER BY DEA.locationn,DEA.datee) AS Rolling_People_vaccinated
FROM CovidVaccinations DEA
JOIN CovidDeaths VAC 
ON DEA.locationn = VAC.location AND DEA.datee = VAC.date
WHERE DEA.continent IS NOT NULL AND new_vaccinations IS NOT NULL
ORDER BY DEA.locationn, DEA.datee;

--USE CTE  Common Table Expression


WITH PopvsVac AS (
    SELECT 
        DEA.continent,
        DEA.locationn AS Location,
        DEA.datee AS Date,
        population,
        new_vaccinations,
        SUM(CONVERT(BIGINT, new_vaccinations)) 
            OVER (PARTITION BY DEA.locationn ORDER BY DEA.datee) AS Rolling_People_vaccinated
    FROM CovidVaccinations DEA
    JOIN CovidDeaths VAC ON DEA.locationn = VAC.location AND DEA.datee = VAC.date
    WHERE DEA.continent IS NOT NULL AND new_vaccinations IS NOT NULL AND ISNUMERIC(new_vaccinations) = 1
)
-- Now you can use the PopvsVac CTE in subsequent parts of your query
SELECT *,(Rolling_People_vaccinated/population)*100 AS Percentage
FROM PopvsVac;




-- TEMP TABLE
DROP TABLE IF EXISTS #Percentagepopulationvaccinated
CREATE TABLE #Percentagepopulationvaccinated
(
    continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    new_vaccinations numeric,
    Rolling_People_vaccinated numeric
)

INSERT INTO #Percentagepopulationvaccinated
SELECT 
    DEA.continent,
    DEA.locationn,
    DEA.datee,
    population,
    new_vaccinations,
    SUM(CONVERT(BIGINT, new_vaccinations)) 
	OVER (PARTITION BY DEA.locationn ORDER BY DEA.locationn, DEA.datee) AS Rolling_People_vaccinated
FROM CovidVaccinations DEA
JOIN CovidDeaths VAC ON DEA.locationn = VAC.location AND DEA.datee = VAC.date
WHERE DEA.continent IS NOT NULL AND new_vaccinations IS NOT NULL
ORDER BY DEA.locationn, DEA.datee;

SELECT *, (Rolling_People_vaccinated / population) * 100 AS Percentage
FROM #Percentagepopulationvaccinated;


--Creating VIEW to sotre the data for the later view

CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    DEA.continent,
    DEA.locationn,
    DEA.datee,
    population,
    new_vaccinations,
    SUM(CONVERT(BIGINT, new_vaccinations)) 
	OVER (PARTITION BY DEA.locationn ORDER BY DEA.locationn, DEA.datee) AS Rolling_People_vaccinated
FROM CovidVaccinations DEA
JOIN CovidDeaths VAC ON DEA.locationn = VAC.location AND DEA.datee = VAC.date
WHERE DEA.continent IS NOT NULL AND new_vaccinations IS NOT NULL


SELECT *
FROM PercentPopulationVaccinated