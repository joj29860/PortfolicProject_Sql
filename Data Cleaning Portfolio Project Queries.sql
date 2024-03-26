CREATE TABLE NashvilleHousing
(
        UniqueID INTEGER,
        ParcelID TEXT NOT NULL,
        LandUse TEXT NOT NULL,
        PropertyAddress TEXT NOT NULL,
        SaleDate TEXT NULL,
        SalePrice INTEGER NOT NULL,
        LegalReference TEXT NOT NULL,
        SoldAsVacant TEXT NOT NULL,
        OwnerName TEXT NOT NULL,
        OwnerAddress TEXT NOT NULL,
        Acreage DOUBLE NOT NULL,
        TaxDistrict TEXT NOT NULL,
        LandValue INTEGER NOT NULL,
        BuildingValue INTEGER NOT NULL,
        TotalValue INTEGER NOT NULL,
        YearBuilt INTEGER NOT NULL,
        Bedrooms INTEGER NOT NULL,
        FullBath INTEGER NOT NULL,
        HalfBath INTEGER NOT NULL
);


LOAD DATA INFILE 'C:/Nashville Housing Data for Data Cleaning_encoding.csv' 
INTO TABLE NashvilleHousing
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM NashvilleHousing;

DROP TABLE IF EXISTS NashvilleHousing;

/* Cleaning Data in SQL Queries */
 SELECT * FROM NashvilleHousing;
 
/* Standardize Date Format */
SELECT SaleDate
FROM nashvillehousing;
-- Try the format you want
SELECT SaleDate, str_to_date(SaleDate, '%d-%b-%Y') AS Format_SaleDate
FROM nashvillehousing;
-- Update it on the table
UPDATE nashvillehousing
SET SaleDate = str_to_date(SaleDate, '%d-%b-%Y');

/*Populate Property Address data*/
-- Select the empty rows
SELECT *
FROM nashvillehousing
-- WHERE PropertyAddress = '';
ORDER BY ParcelID;

-- replace empty cells with NULL 
UPDATE nashvillehousing 
SET PropertyAddress = NULL WHERE PropertyAddress = '';

-- Check the address will show
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress, b.PropertyAddress) AS c
FROM nashvillehousing a
JOIN nashvillehousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- Upadte it to the table
-- In MySQL, the UPDATE statement doesn't support a direct FROM clause like in other databases such as SQL Server.
UPDATE nashvillehousing a
JOIN nashvillehousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

/* Breaking out Adress into Individual Columns(Address, City, State) */
SELECT PropertyAddress
FROM nashvillehousing;

-- In MySQL, the CHARINDEX function is not available.
-- '1' represents it's gonna start from the very first value and go until ','
-- LOCATE(',', PropertyAddress) is the number showing the position of ','
SELECT PropertyAddress, SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1) AS Address
FROM nashvillehousing;

-- Come out with the 'City'
SELECT PropertyAddress, LENGTH(PropertyAddress),
SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress)+1, LENGTH(PropertyAddress)) AS City
FROM nashvillehousing;

-- Create new columns
ALTER TABLE nashvillehousing
ADD PropertySpiltAddress NVARCHAR(255);

UPDATE nashvillehousing
SET PropertySpiltAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1);

ALTER TABLE nashvillehousing
ADD PropertySpiltCity NVARCHAR(255);

UPDATE nashvillehousing
SET PropertySpiltCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress)+1, LENGTH(PropertyAddress));

SELECT * FROM nashvillehousing;

-- Splite Owner Address
SELECT OwnerAddress FROM nashvillehousing;

-- SELECT OwnerAddress, 
-- SUBSTRING_INDEX(OwnerAddress, ',', -3),
-- SUBSTRING_INDEX(OwnerAddress, ',', -2),
-- SUBSTRING_INDEX(OwnerAddress, ',', -1)
-- FROM nashvillehousing;

SELECT 
	OwnerAddress,
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -3), ',', 1) AS Part1,
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1) AS Part2,
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -1), ',', 1) AS Part3
FROM 
    nashvillehousing;

-- Create new columns
ALTER TABLE nashvillehousing
ADD OwnerSpiltAddress NVARCHAR(255);

UPDATE nashvillehousing
SET OwnerSpiltAddress = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -3), ',', 1);

ALTER TABLE nashvillehousing
ADD OwnerSpiltCity NVARCHAR(255);

UPDATE nashvillehousing
SET OwnerSpiltCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1);

ALTER TABLE nashvillehousing
ADD OwnerSpiltState NVARCHAR(255);

UPDATE nashvillehousing
SET OwnerSpiltState = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -1), ',', 1);

SELECT * FROM nashvillehousing;

/*Change Y and N to Yes and No in "Sold as Vacant" field*/
-- Check the contents
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM nashvillehousing
GROUP BY SoldAsVacant
ORDER BY SoldAsVacant;

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END
FROM nashvillehousing;

-- Change the columns
UPDATE nashvillehousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END;
    
/*Remove Duplicates*/
-- By using CTE
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
    PARTITION BY ParcelID,
				 PropertyAddress,
                 SaleDate,
                 SalePrice,
                 LegalReference
                 ORDER BY
					UniqueID
                    ) Row_Num
FROM nashvillehousing
-- ORDER BY ParcelID
)
-- SELECT *
DELETE
FROM RowNumCTE
WHERE Row_Num > 1;

-- By using temporary table
CREATE TEMPORARY TABLE Temp_table_2 AS
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
           ORDER BY UniqueID
       ) AS Row_Num
FROM nashvillehousing;

-- Delete rows from temporary table where Row_Num > 1 and check if it's been deleted
-- DELETE
SELECT * 
FROM Temp_table_2 WHERE Row_Num > 1;

/*Delete Unused Columns*/
SELECT *
FROM nashvillehousing;

ALTER TABLE nashvillehousing
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress;