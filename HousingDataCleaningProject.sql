SELECT *
FROM HousingAnalysis..Housing$

--- Adjust Date format from datetime to date 
 
 SELECT saleDateConverted, CONVERT(Date,SaleDate)
 FROM HousingAnalysis..Housing$

 UPDATE HousingAnalysis..Housing$
 SET SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE HousingAnalysis..Housing$
ADD SaleDateConverted Date;

UPDATE HousingAnalysis..Housing$
SET SaleDateConverted = CONVERT(Date,SaleDate)

--Populate Property address data
 SELECT *
 FROM HousingAnalysis..Housing$
 WHERE PropertyAddress is Null

 SELECT *
 FROM HousingAnalysis..Housing$
 ORDER BY ParcelID

 SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
 FROM HousingAnalysis..Housing$ A
 JOIN HousingAnalysis..Housing$ B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress is NULL

UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM HousingAnalysis..Housing$ A
 JOIN HousingAnalysis..Housing$ B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress is NULL

-- Breaking out Address into individual columns 

SELECT PropertyAddress
FROM HousingAnalysis..Housing$


SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address 
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1 , LEN(PropertyAddress)) AS Address 

FROM HousingAnalysis..Housing$

ALTER TABLE HousingAnalysis..Housing$
ADD PropertySplitAddress Nvarchar(255);

UPDATE HousingAnalysis..Housing$
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE HousingAnalysis..Housing$
ADD PropertySplitCity Nvarchar(255);

UPDATE HousingAnalysis..Housing$
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1 , LEN(PropertyAddress))

SELECT *
FROM HousingAnalysis..Housing$


SELECT OwnerAddress
FROM HousingAnalysis..Housing$

SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),3)
,PARSENAME(REPLACE(OwnerAddress,',','.'),2)
,PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM HousingAnalysis..Housing$

ALTER TABLE HousingAnalysis..Housing$
ADD OwnerSplitAddress Nvarchar(255);

UPDATE HousingAnalysis..Housing$
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE HousingAnalysis..Housing$
ADD OwnerSplitCity Nvarchar(255);

UPDATE HousingAnalysis..Housing$
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE HousingAnalysis..Housing$
ADD OwnerSplitState Nvarchar(255);

UPDATE HousingAnalysis..Housing$
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

SELECT *
FROM HousingAnalysis..Housing$

-- Change Y and N to Yes and No in "Sold as Vacant" Field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM HousingAnalysis..Housing$
GROUP BY SoldAsVacant
ORDER BY COUNT(SoldAsVacant)

SELECT SoldAsVacant 
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM HousingAnalysis..Housing$

UPDATE HousingAnalysis..Housing$
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END

-- Check table 
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM HousingAnalysis..Housing$
GROUP BY SoldAsVacant
ORDER BY COUNT(SoldAsVacant)


---Check for duplicates 
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
				 UniqueID
				 )ROW_NUM
FROM HousingAnalysis..Housing$
)
SELECT *
FROM RowNumCTE
WHERE ROW_NUM > 1
ORDER BY PropertyAddress

--Delete Duplicates 

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
				 UniqueID
				 )ROW_NUM
FROM HousingAnalysis..Housing$
)
DELETE 
FROM RowNumCTE
WHERE ROW_NUM > 1

--Check that duplicates where deleted
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
				 UniqueID
				 )ROW_NUM
FROM HousingAnalysis..Housing$
)
SELECT *
FROM RowNumCTE
WHERE ROW_NUM > 1
ORDER BY PropertyAddress

--- Delete unused columns 

SELECT *
FROM HousingAnalysis..Housing$

ALTER TABLE HousingAnalysis..Housing$
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

SELECT *
FROM HousingAnalysis..Housing$

-- The difference between the total house value and the price it was sold for. 
SELECT (SalePrice - TotalValue) AS SalePriceDifference 
FROM HousingAnalysis..Housing$


-- Select for land sold in 2016 in which saleprice was less than total value of the house. 

SELECT *, (SalePrice - TotalValue) AS SalePriceDifference 
FROM HousingAnalysis..Housing$
WHERE SaleDateConverted LIKE '2016%' AND SalePrice < TotalValue
ORDER BY SalePriceDifference 

-- View the different types of land types 
SELECT DISTINCT *
FROM HousingAnalysis..Housing$


-- Create temp table of only single family properties 
CREATE TABLE #temp_Housing (
UniqueID float, ParcelID nvarchar(255),
SalePrice float, Acreage float, LandValue float, BuildingValue float, 
TotalValue float, YearBuilt float, Bedrooms float, FullBath float, HalfBath float
)

INSERT INTO #temp_Housing
SELECT UniqueID, ParcelID ,
SalePrice, Acreage, LandValue, BuildingValue, 
TotalValue, YearBuilt, Bedrooms, FullBath, HalfBath
FROM HousingAnalysis..Housing$
WHERE LandUse = 'SINGLE FAMILY'

SELECT *
FROM #temp_Housing

-- list the 10 single family houses sold at highest price 
SELECT TOP 10 *
FROM HousingAnalysis..Housing$ 
WHERE LandUse = 'SINGLE FAMILY'
ORDER BY SalePrice DESC 

-- or 
SELECT TOP 10 *
FROM #temp_Housing
ORDER BY SalePrice DESC

-- list the 10 Single Family houses sold at lowest price 
SELECT TOP 10 *
FROM HousingAnalysis..Housing$
WHERE LandUse = 'SINGLE FAMILY'
ORDER BY SalePrice ASC

-- or 
SELECT TOP 10 *
FROM #temp_Housing
ORDER BY SalePrice




