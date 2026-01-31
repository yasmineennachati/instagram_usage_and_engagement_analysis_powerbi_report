--Créer la base de STAGING
CREATE DATABASE Instagram_Staging;
GO

USE Instagram_Staging;
GO
Select Count(user_id)  Nbr_Users  from  stg_instagram_raw
CREATE TABLE stg_instagram_raw (
    user_id INT,
    app_name VARCHAR(50),

    age INT,
    gender VARCHAR(20),
    country VARCHAR(100),
    urban_rural VARCHAR(20),
    income_level VARCHAR(50),
    employment_status VARCHAR(50),
    education_level VARCHAR(50),
    relationship_status VARCHAR(50),
    has_children BIT,

    exercise_hours_per_week FLOAT,
    sleep_hours_per_night FLOAT,
    diet_quality VARCHAR(50),
    smoking VARCHAR(20),
    alcohol_frequency VARCHAR(50),
    perceived_stress_score INT,
    self_reported_happiness INT,
    body_mass_index FLOAT,
    blood_pressure_systolic INT,
    blood_pressure_diastolic INT,
    daily_steps_count INT,

    weekly_work_hours INT,
    hobbies_count INT,
    social_events_per_month INT,
    books_read_per_year INT,
    volunteer_hours_per_month INT,
    travel_frequency_per_year INT,

    daily_active_minutes_instagram FLOAT,
    sessions_per_day FLOAT,
    posts_created_per_week FLOAT,
    reels_watched_per_day FLOAT,
    stories_viewed_per_day FLOAT,
    likes_given_per_day FLOAT,
    comments_written_per_day FLOAT,
    dms_sent_per_week FLOAT,
    dms_received_per_week FLOAT,
    ads_viewed_per_day FLOAT,
    ads_clicked_per_day FLOAT,

    time_on_feed_per_day FLOAT,
    time_on_explore_per_day FLOAT,
    time_on_messages_per_day FLOAT,
    time_on_reels_per_day FLOAT,

    followers_count INT,
    following_count INT,

    uses_premium_features BIT,
    notification_response_rate FLOAT,

    account_creation_year INT,
    last_login_date DATE,
    average_session_length_minutes FLOAT,

    content_type_preference VARCHAR(50),
    preferred_content_theme VARCHAR(50),
    privacy_setting_level VARCHAR(50),
    two_factor_auth_enabled BIT,
    biometric_login_used BIT,
    linked_accounts_count INT,
    subscription_status VARCHAR(20),

    user_engagement_score FLOAT,

    -- Colonnes techniques ETL
    batch_id INT,                                   -- Numéro du chargement
    source_file VARCHAR(255),                        -- Nom du fichier source
    load_date DATETIME DEFAULT GETDATE()           -- Date de chargement
    
);
SELECT * FROM stg_instagram_raw
--Cleaning et nettoyage

ALTER TABLE stg_instagram_raw
ADD load_date DATETIME DEFAULT GETDATE();

UPDATE stg_instagram_raw
SET load_date = GETDATE()
WHERE load_date IS NULL;

--La suppression des colonnes inutiles pour mon analyse.
ALTER TABLE stg_instagram_raw
DROP COLUMN 
 has_children,
 smoking,
    alcohol_frequency,
    biometric_login_used,
    diet_quality;

DELETE
FROM stg_instagram_raw
WHERE gender NOT IN ('Male', 'Female')
   OR gender IS NULL;

UPDATE stg_instagram_raw
SET country = 'Morocco'
WHERE country = 'Other';


--Créer la base DATA WAREHOUSE
CREATE DATABASE Instagram_DataWarehouse;
GO

USE Instagram_DataWarehouse;
GO
--Creation des dimentions 

CREATE TABLE dim_user (
    user_key INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT,
    age INT,
    gender NVARCHAR(10),
    income_level NVARCHAR(50),
    employment_status NVARCHAR(50),
    education_level NVARCHAR(50),
    relationship_status NVARCHAR(50),
    hobbies_count INT,
    books_read_per_year INT
);

CREATE TABLE dim_location (
    location_key INT IDENTITY(1,1) PRIMARY KEY,
    country NVARCHAR(50),
    urban_rural NVARCHAR(20)
);

CREATE TABLE dim_lifestyle (
    lifestyle_key INT IDENTITY(1,1) PRIMARY KEY,
    exercise_hours_per_week FLOAT,
    sleep_hours_per_night FLOAT,
    perceived_stress_score FLOAT,
    self_reported_happiness FLOAT,
    body_mass_index FLOAT,
    blood_pressure_systolic INT,
    blood_pressure_diastolic INT,
    daily_steps_count INT,
    weekly_work_hours INT,
    social_events_per_month INT,
    volunteer_hours_per_month INT,
    travel_frequency_per_year INT
);

CREATE TABLE dim_content_preference (
    content_pref_key INT IDENTITY(1,1) PRIMARY KEY,
    content_type_preference NVARCHAR(50),
    preferred_content_theme NVARCHAR(50),
    privacy_setting_level NVARCHAR(50)
);


CREATE TABLE dim_subscription (
    subscription_key INT IDENTITY(1,1) PRIMARY KEY,
    subscription_status NVARCHAR(50),
    uses_premium_features NVARCHAR(50),
    two_factor_auth_enabled NVARCHAR(50),
    linked_accounts_count INT
);

CREATE TABLE dim_date (
    time_key INT IDENTITY(1,1) PRIMARY KEY,
    calendar_date DATE NOT NULL,
    year INT,
    quarter INT,
    month INT,
    month_name NVARCHAR(20),
    day INT,
    day_of_week INT,
    day_name NVARCHAR(10),
    is_weekend BIT
);

--Création de la table de faits 

CREATE TABLE fact_instagram_engagement (
    engagement_key INT IDENTITY(1,1) PRIMARY KEY,

    -- Clés étrangères
    user_key INT NOT NULL,
    location_key INT NOT NULL,
    lifestyle_key INT NOT NULL,

    -- Clés temporelles vers dim_date
   time_key_creation INT NOT NULL,       -- pour account_creation_year
   time_key_login INT NOT NULL,     -- pour last_login_date

    content_pref_key INT NOT NULL,
    subscription_key INT NOT NULL,

    -- Mesures Instagram (KPIs)
    daily_active_minutes_instagram INT,
    sessions_per_day INT,
    posts_created_per_week INT,
    reels_watched_per_day INT,
    stories_viewed_per_day INT,
    likes_given_per_day INT,
    comments_written_per_day INT,
    dms_sent_per_week INT,
    dms_received_per_week INT,
    ads_viewed_per_day INT,
    ads_clicked_per_day INT,
    time_on_feed_per_day FLOAT,
    time_on_explore_per_day FLOAT,
    time_on_messages_per_day FLOAT,
    time_on_reels_per_day FLOAT,
    followers_count INT,
    following_count INT,
    average_session_length_minutes FLOAT,
    user_engagement_score FLOAT,


    -- Contraintes de clés étrangères
    CONSTRAINT fk_fact_user FOREIGN KEY (user_key)
        REFERENCES dim_user(user_key),

    CONSTRAINT fk_fact_location FOREIGN KEY (location_key)
        REFERENCES dim_location(location_key),

    CONSTRAINT fk_fact_lifestyle FOREIGN KEY (lifestyle_key)
        REFERENCES dim_lifestyle(lifestyle_key),

    CONSTRAINT fk_fact_time_creation FOREIGN KEY (time_key_creation)
        REFERENCES dim_date(time_key),

    CONSTRAINT fk_fact_time_last_login FOREIGN KEY (time_key_login)
        REFERENCES dim_date(time_key),


    CONSTRAINT fk_fact_content FOREIGN KEY (content_pref_key)
        REFERENCES dim_content_preference(content_pref_key),

    CONSTRAINT fk_fact_subscription FOREIGN KEY (subscription_key)
        REFERENCES dim_subscription(subscription_key)
);

--L'insertion dans les dimensions depuis la base de staging
INSERT INTO dim_user (
    user_id, age, gender, income_level,
    employment_status, education_level,
    relationship_status, hobbies_count, books_read_per_year
)
SELECT DISTINCT
    user_id,
    age,
    gender,
    income_level,
    employment_status,
    education_level,
    relationship_status,
    hobbies_count,
    books_read_per_year
FROM Instagram_Staging.dbo.stg_instagram_raw;

UPDATE dim_location
SET country = 'France'
WHERE country = 'Morocco';

Select Count(user_id)  Nbr_Users  from  dim_user
Select Count(user_key)  Nbr_Users  from fact_instagram_engagement

INSERT INTO dim_location (country, urban_rural)
SELECT DISTINCT
    country,
    urban_rural
FROM Instagram_Staging.dbo.stg_instagram_raw;


INSERT INTO dim_lifestyle (
    exercise_hours_per_week,
    sleep_hours_per_night,
    perceived_stress_score,
    self_reported_happiness,
    body_mass_index,
    blood_pressure_systolic,
    blood_pressure_diastolic,
    daily_steps_count,
    weekly_work_hours,
    social_events_per_month,
    volunteer_hours_per_month,
    travel_frequency_per_year
)
SELECT DISTINCT
    exercise_hours_per_week,
    sleep_hours_per_night,
    perceived_stress_score,
    self_reported_happiness,
    body_mass_index,
    blood_pressure_systolic,
    blood_pressure_diastolic,
    daily_steps_count,
    weekly_work_hours,
    social_events_per_month,
    volunteer_hours_per_month,
    travel_frequency_per_year
FROM Instagram_Staging.dbo.stg_instagram_raw;


INSERT INTO dim_content_preference (
    content_type_preference,
    preferred_content_theme,
    privacy_setting_level
)
SELECT DISTINCT
    content_type_preference,
    preferred_content_theme,
    privacy_setting_level
FROM Instagram_Staging.dbo.stg_instagram_raw;


INSERT INTO dim_subscription 
( subscription_status, 
uses_premium_features, 
two_factor_auth_enabled, 
linked_accounts_count )
SELECT DISTINCT 
subscription_status,
uses_premium_features, 
two_factor_auth_enabled, 
linked_accounts_count 
FROM Instagram_Staging.dbo.stg_instagram_raw;

-- Insertion des dates sur plusieurs années
DECLARE @StartDate DATE = '2010-01-01';
DECLARE @EndDate DATE = '2030-12-31';

WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO dim_date (calendar_date, year, quarter, month, month_name, day, day_of_week, day_name, is_weekend)
    VALUES (
        @StartDate,
        YEAR(@StartDate),
        DATEPART(QUARTER, @StartDate),
        MONTH(@StartDate),
        DATENAME(MONTH, @StartDate),
        DAY(@StartDate),
        DATEPART(WEEKDAY, @StartDate),
        DATENAME(WEEKDAY, @StartDate),
        CASE WHEN DATEPART(WEEKDAY, @StartDate) IN (1,7) THEN 1 ELSE 0 END
    );
    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END;
 
INSERT INTO fact_instagram_engagement (
    user_key,
    location_key,
    lifestyle_key,

    time_key_creation,   -- account_creation_year
    time_key_login,      -- last_login_date

    content_pref_key,
    subscription_key,

    daily_active_minutes_instagram,
    sessions_per_day,
    posts_created_per_week,
    reels_watched_per_day,
    stories_viewed_per_day,
    likes_given_per_day,
    comments_written_per_day,
    dms_sent_per_week,
    dms_received_per_week,
    ads_viewed_per_day,
    ads_clicked_per_day,
    time_on_feed_per_day,
    time_on_explore_per_day,
    time_on_messages_per_day,
    time_on_reels_per_day,
    followers_count,
    following_count,
    average_session_length_minutes,
    user_engagement_score
)
SELECT
    u.user_key,
    l.location_key,
    ls.lifestyle_key,

    -- 🔹 Date de création du compte → 01/01/YYYY
    dc.time_key AS time_key_creation,

    -- 🔹 Dernière date de login → date exacte
    dl.time_key AS time_key_login,

    cp.content_pref_key,
    s.subscription_key,

    r.daily_active_minutes_instagram,
    r.sessions_per_day,
    r.posts_created_per_week,
    r.reels_watched_per_day,
    r.stories_viewed_per_day,
    r.likes_given_per_day,
    r.comments_written_per_day,
    r.dms_sent_per_week,
    r.dms_received_per_week,
    r.ads_viewed_per_day,
    r.ads_clicked_per_day,
    r.time_on_feed_per_day,
    r.time_on_explore_per_day,
    r.time_on_messages_per_day,
    r.time_on_reels_per_day,
    r.followers_count,
    r.following_count,
    r.average_session_length_minutes,
    r.user_engagement_score
FROM Instagram_Staging.dbo.stg_instagram_raw r

-- Dimensions classiques
JOIN dim_user u
    ON r.user_id = u.user_id

JOIN dim_location l
    ON r.country = l.country
   AND r.urban_rural = l.urban_rural

JOIN dim_lifestyle ls
    ON r.exercise_hours_per_week = ls.exercise_hours_per_week
   AND r.sleep_hours_per_night = ls.sleep_hours_per_night
   AND r.perceived_stress_score = ls.perceived_stress_score
   AND r.self_reported_happiness = ls.self_reported_happiness
   AND r.body_mass_index = ls.body_mass_index
   AND r.blood_pressure_systolic = ls.blood_pressure_systolic
   AND r.blood_pressure_diastolic = ls.blood_pressure_diastolic
   AND r.daily_steps_count = ls.daily_steps_count
   AND r.weekly_work_hours = ls.weekly_work_hours
   AND r.social_events_per_month = ls.social_events_per_month
   AND r.volunteer_hours_per_month = ls.volunteer_hours_per_month
   AND r.travel_frequency_per_year = ls.travel_frequency_per_year

JOIN dim_content_preference cp
    ON r.content_type_preference = cp.content_type_preference
   AND r.preferred_content_theme = cp.preferred_content_theme
   AND r.privacy_setting_level = cp.privacy_setting_level

JOIN dim_subscription s
    ON r.subscription_status = s.subscription_status
   AND r.uses_premium_features = s.uses_premium_features
   AND r.two_factor_auth_enabled = s.two_factor_auth_enabled
   AND r.linked_accounts_count = s.linked_accounts_count

-- 🔹 Mapping temporel CORRECT
JOIN dim_date dc
    ON dc.year = r.account_creation_year
   AND dc.month = 1
   AND dc.day = 1

JOIN dim_date dl
    ON dl.calendar_date = r.last_login_date;

--test pour valider que l'insertion dans fact table est correcte-----------------------------------------------------
select * from fact_instagram_engagement --user key 642  creation 1 login 5601
select * from dim_user where user_key = 642 -- user id 670
select  account_creation_year, last_login_date  from stg_instagram_raw where user_id = 670 --accountcreation 2010 last_login_date 2025-05-02
select * from dim_date where time_key = 5601

select * from fact_instagram_engagement --user key 764  creation 4019 login 5567
select * from dim_user where user_key = 764 -- user id 799
select  account_creation_year, last_login_date  from stg_instagram_raw where user_id = 799 --accountcreation 2021 last_login_date 2025-03-29
select * from dim_date where time_key = 5567  
select * from dim_date where calendar_date = '2021-01-01'
select * from dim_date where is_weekend = 1

--------------------------------------------------------------------------------------------------------------------------------------------------

--Création des indexes pour améliorer la performane et la recherche 

CREATE NONCLUSTERED INDEX idx_dim_user_userid
ON dim_user(user_id);

CREATE NONCLUSTERED INDEX idx_dim_location_country_urban
ON dim_location(country, urban_rural);

CREATE NONCLUSTERED INDEX idx_dim_lifestyle_exercise_sleep
ON dim_lifestyle(exercise_hours_per_week, sleep_hours_per_night, perceived_stress_score);

CREATE NONCLUSTERED INDEX idx_dim_subscription_status
ON dim_subscription(subscription_status, uses_premium_features, two_factor_auth_enabled);

CREATE NONCLUSTERED INDEX idx_dim_content_pref
ON dim_content_preference(content_type_preference, preferred_content_theme, privacy_setting_level);

CREATE UNIQUE NONCLUSTERED INDEX idx_dim_date_calendar_date
ON dim_date (calendar_date);

CREATE NONCLUSTERED INDEX idx_dim_date_year
ON dim_date (year); 

CREATE NONCLUSTERED INDEX idx_dim_date_is_weekend
ON dim_date (is_weekend);

 -- Supprimer la clé primaire existante dans la table fact
ALTER TABLE fact_instagram_engagement
DROP CONSTRAINT PK__fact_ins__6EAC6B4F684A2253;

--  Créer le Clustered Columnstore Index
CREATE CLUSTERED COLUMNSTORE INDEX cci_fact_instagram
ON fact_instagram_engagement;

-- 3 Recréer la clé primaire NON-CLUSTERED
ALTER TABLE fact_instagram_engagement
ADD CONSTRAINT PK_fact_instagram_engagement PRIMARY KEY NONCLUSTERED (engagement_key);

-- Index pour jointures vers les dimensions
CREATE NONCLUSTERED INDEX idx_fact_user
ON fact_instagram_engagement(user_key);

CREATE NONCLUSTERED INDEX idx_fact_location
ON fact_instagram_engagement(location_key);

CREATE NONCLUSTERED INDEX idx_fact_lifestyle
ON fact_instagram_engagement(lifestyle_key);

CREATE NONCLUSTERED INDEX idx_fact_time_creation
ON fact_instagram_engagement(time_key_creation);

CREATE NONCLUSTERED INDEX idx_fact_time_login
ON fact_instagram_engagement(time_key_login);

CREATE NONCLUSTERED INDEX idx_fact_content_pref
ON fact_instagram_engagement(content_pref_key);

CREATE NONCLUSTERED INDEX idx_fact_subscription
ON fact_instagram_engagement(subscription_key);
--Vérification des indexes sur la table fact
SELECT 
    i.name AS index_name,
    i.type_desc,
    i.is_primary_key,
    i.is_unique
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('fact_instagram_engagement');







