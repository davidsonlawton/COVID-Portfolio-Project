SELECT *
FROM [Portfolio Project]..CovidDeaths$
WHERE continent is not null
ORDER BY 3, 4


--Select *
--From [Portfolio Project]..CovidVaccinations$
--order by 3, 4

-- select data that will be used

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project]..CovidDeaths$
ORDER BY 1, 2

--Look at total cases vs total deaths (shows liklihood of dying if you contract COVID in your country)

SELECT Location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT))*100 AS DeathPercentage
FROM [Portfolio Project]..CovidDeaths$
WHERE location like '%states%'
ORDER BY 1, 2

-- look at total cases vs population (shows what percent of population got covid)

SELECT Location, date, total_cases, population, (CAST(total_cases AS FLOAT) / CAST(population AS FLOAT))*100 AS PercentagePopulationInfected
FROM [Portfolio Project]..CovidDeaths$
WHERE location like '%states%'
ORDER BY 1, 2

 --look at countries with highest infection rate compared to population

SELECT
    Location,
    MAX(total_cases) as HighestInfectionCount,
    MAX(CAST(total_cases AS FLOAT) / CAST(population AS FLOAT)) * 100 AS COVIDPercentage
FROM
    [Portfolio Project]..CovidDeaths$
GROUP BY
    location, Population
ORDER BY
    COVIDPercentage desc


-- showing countries with highest death count per population

SELECT
	Location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM
	[Portfolio Project]..CovidDeaths$
WHERE
	Continent is not null
GROUP BY
	Location
ORDER BY
	TotalDeathCount desc

--break things down by continent

--showing  continents with the highest death counts

SELECT
	continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM
	[Portfolio Project]..CovidDeaths$
WHERE
	Continent is not null
GROUP BY
	continent
ORDER BY
	TotalDeathCount desc

--global numbers


SELECT
	SUM(new_cases), SUM(CAST(new_deaths AS INT)), 
    SUM(CAST(new_deaths AS INT)) / NULLIF(SUM(new_cases), 0) * 100 as DeathPercentage
FROM
	[Portfolio Project]..CovidDeaths$
WHERE
	Continent IS NOT NULL
--GROUP BY
	--date
ORDER BY
	1, 2;

--total population vs vaccinations

SELECT
    dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER 
	(PARTITION BY dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated,
FROM
    [Portfolio Project]..CovidDeaths$ dea
    JOIN [Portfolio Project]..CovidVaccinations$ vac
        ON dea.location = vac.location
        AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
ORDER BY
    2, 3;

-- Using CTE to perform Calculation on Partition By in previous query


WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
    SELECT
        dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
    FROM
        [Portfolio Project]..CovidDeaths$ dea
        JOIN [Portfolio Project]..CovidVaccinations$ vac
            ON dea.location = vac.location
            AND dea.date = vac.date
    WHERE
        dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / Population) * 100
FROM PopvsVac;

--TEMP Table


DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated BIGINT
);

INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM
    [Portfolio Project]..CovidDeaths$ dea
    JOIN [Portfolio Project]..CovidVaccinations$ vac
        ON dea.location = vac.location
        AND dea.date = vac.date;

SELECT *, (RollingPeopleVaccinated / Population) * 100
FROM #PercentPopulationVaccinated;

--creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT
    dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM
    [Portfolio Project]..CovidDeaths$ dea
    JOIN [Portfolio Project]..CovidVaccinations$ vac
        ON dea.location = vac.location
        AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
