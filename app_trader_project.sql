-- Tables:
SELECT DISTINCT(primary_genre)
FROM app_store_apps;

SELECT *
FROM play_store_apps;

-- Assumptions:
	-- 1. App Trader will purchase app rights for 10,000X store listing price.
	-- 2. Min purchase price is $25K.
	-- 3. Apps earn 5K per month per store they are listed on.
	-- 4. App Trader will spend $1K in marketing cost regardless of app that is purchased (even if listed in both stores)
	-- 5. Apps earn money monthly until no longer existing.
		-- Min lifespan is 1 year
			-- Every 0.25 the rating of the app increases, the lifespan of the app increases by 6 months.
				-- (0 rating = 1 year. 0.25 rating = 1.5 years...)

-- Objectives:
	-- A. Develop general recommendations about the price range, genre, content rating, or any other app characteristics that we should target.
	-- B. Develop a Top 10 list of the apps with the best ROI assuming we act as a sole propriotor.
	-- C. Develop a top 4 list of the apps that we should buy that are profitable and thematically appropriate for the 4th of July campaign.
	-- D. Submit a report with both the preceding findings as well as analysis of their cost and potential profits.
	-- E. Prepare a five minute presentation as a slideshow with charts.

-- Using only those apps listed on both stores will give us double monthly revenue.
SELECT *
FROM(SELECT DISTINCT(p.name), 
       p.category, 
	   p.price::money AS play_price, 
	   a.price::money AS apple_price, 
	   ROUND(((a.review_count::money::numeric*a.rating)+(p.review_count::text::money::numeric*p.rating))/(p.review_count::text::money::numeric + a.review_count::text::money::numeric), 2) AS true_average_rating
	   	FROM play_store_apps AS p
			INNER JOIN app_store_apps AS a USING(name)
			WHERE p.price::money::numeric <=2.50 AND a.price::money::numeric <=2.50)
ORDER BY true_average_rating DESC
LIMIT 10;

-- 4th of July top 4. 
SELECT *
FROM (SELECT DISTINCT(p.name), 
       p.category, 
	   primary_genre,
	   p.price::money AS play_price, 
	   a.price::money AS apple_price, 
	   ROUND(((a.review_count::money::numeric*a.rating)+(p.review_count::text::money::numeric*p.rating))/(p.review_count::text::money::numeric + a.review_count::text::money::numeric), 2) AS true_average_rating
	   	FROM app_store_apps AS a
		INNER JOIN play_store_apps AS p USING (name))
WHERE primary_genre ILIKE 'weather' OR primary_genre ILIKE 'travel' OR primary_genre ILIKE 'food & drink' OR primary_genre ILIKE 'photo & video' OR primary_genre ILIKE 'navigation'
ORDER BY true_average_rating DESC
LIMIT 4;

--Mahi work:
WITH joined_apps AS(
SELECT DISTINCT LOWER(a.name) AS app_name, REPLACE(a.price::text,'$',''):: numeric AS apple_price,
REPLACE(p.price::text,'$',''):: numeric AS play_price,
ROUND(a.rating/.25)*.25 AS apple_rating,
ROUND(p.rating/.25)*.25 AS play_rating,
a.primary_genre AS genre
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p 
ON LOWER(TRIM(a.name))=LOWER(TRIM(p.name))
WHERE a.rating IS NOT NULL
AND a.primary_genre ILIKE '%weather%' OR a.primary_genre ILIKE '%travel%' OR primary_genre ILIKE 'food & drink' OR primary_genre ILIKE 'photo & video' OR primary_genre ILIKE 'navigation')
,
both_apps AS (
SELECT app_name,genre, COUNT(*) AS store_count, GREATEST(MAX(apple_price),MAX(play_price)) AS max_price, LEAST(MIN(apple_rating),MIN(play_rating)) AS min_rating
FROM joined_apps
GROUP BY app_name, genre
),
both_apps_profits AS(
SELECT app_name,
--store_count,
max_price,
min_rating,
genre,
---PURCHASE COST... x$10,000 for max_price but x25,000 for free
CASE
	WHEN max_price *10000 <25000 THEN 25000
	ELSE max_price *10000
END as purchase_price,
5000*2 AS monthly_profit,
1000 AS marketing_cost,
---store count * app's life span in months
---Total Profit= monthly profit over app's lifespan - purchase cost- total marketing cost
(5000*2-1000) * (12+((min_rating/.25)*6)) -
---PURCHASE COST---
CASE
	WHEN max_price *10000 <25000 THEN 25000
	ELSE max_price *10000
END AS total_profit



FROM both_apps
)
SELECT *
FROM both_apps_profits
WHERE app_name = 'starbucks' OR app_name = 'instagram' OR app_name = 'yahoo weather' OR app_name = 'airbnb'
ORDER BY total_profit DESC
-- LIMIT 4;








WITH joined_apps AS(
SELECT DISTINCT LOWER(a.name) AS app_name,a.primary_genre AS genre,a.content_rating AS content_rating, REPLACE(a.price::text,'$',''):: numeric AS apple_price,
REPLACE(p.price::text,'$',''):: numeric AS play_price,
----Ratings should be rounded to the nearest 0.25 to evaluate an app's likely longevity--
ROUND(a.rating/.25)*.25 AS apple_rating,
ROUND(p.rating/.25)*.25 AS play_rating
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p 
ON LOWER(TRIM(a.name))=LOWER(TRIM(p.name))
WHERE a.rating IS NOT NULL AND p.rating IS NOT NULL)
,
both_apps AS (
SELECT app_name, genre,content_rating,
---if the price is different between Apple App Store and Google play store choose the higher price--
CASE
WHEN MAX(apple_price)>MAX(play_price) THEN MAX(apple_price)
ELSE MAX(play_price)
END AS max_price,
CASE 
WHEN MIN(apple_rating) < MIN (play_rating) THEN MIN(apple_rating)
ELSE MIN(play_rating)
END AS min_rating
FROM joined_apps
GROUP BY app_name,genre,content_rating
),
both_apps_profits AS(
SELECT app_name,genre,content_rating,
max_price,
min_rating,
---PURCHASE COST: minimum price to purchase the rights to an app is $25,000;App Trader will purchase the rights to apps for 10,000 times the list price
CASE
	WHEN max_price *10000 <25000 THEN 25000
	ELSE max_price *10000
END as purchase_price,
--5,000 per month, per platform (5000 *store count)
5000*2 AS monthly_profit,
---market the app for both stores for a single cost of $1000 per month
1000 AS marketing_cost,
---The minimum longevity for an app is 1 year and for every quarter-point that an app gains in rating, its projected lifespan increases by 6 months.
---store count * app's life span in months
---Total Profit= monthly profit over app's lifespan - purchase cost- total marketing cost
(5000*2-1000) * (12+((min_rating/.25)*6)) -
---PURCHASE COST---
CASE
	WHEN max_price *10000 <25000 THEN 25000
	ELSE max_price *10000
END AS total_profit

FROM both_apps
)
SELECT *
FROM both_apps_profits
ORDER BY total_profit DESC;