-- 1)Populate missing property address data
-- 2) Standardize “Sold as Vacant” field (from Y/N to Yes and No)
-- 3)Parsing long-formatted address into individual columns (Address, City, State)
-- 4)Standardize date format
-- 5)Remove Duplicates
-- 6) DROP unnecessary columns


use portfolioproject;

select PropertyAddress from nashvilledata

-- Populate Property Address Data --

select PropertyAddress from nashvilledata
where Propertyaddress is null;

Select n1.ParcelID, n1.PropertyAddress, n2.ParcelID, n2.PropertyAddress, ISNULL(n1.PropertyAddress , n2.PropertyAddress)
From Nashvilledata n1
JOIN Nashvilledata n2
	on n1.ParcelID =  n2.ParcelID
	AND n1.UniqueID  <> n2.UniqueID 
Where a.PropertyAddress is null;

Update n1
SET PropertyAddress = ISNULL(n1.PropertyAddress , n2.PropertyAddress)
From Nashvilledata n1
JOIN Nashvilledata n2
	on n1.ParcelID = n2.ParcelID
	AND n1.UniqueID  <> n2.UniqueID 
Where n1.PropertyAddress is null;

-- Change y and n to yes and no in "Multiple parcels involved in sale" field --

select 
case when MultipleparcelsInvolvedInSale = 'y' then 'Yes'
      when MultipleparcelsInvolvedInSale = 'n' then 'No'
      else MultipleparcelsInvolvedInSale 
      end 
      from nashvilledata;
      
      update nashvilledata
      set MultipleparcelsInvolvedInSale = case 
      when MultipleparcelsInvolvedInSale = 'y' then 'Yes'
      when MultipleparcelsInvolvedInSale = 'n' then 'No'
      else MultipleparcelsInvolvedInSale 
      end
      
      -- Parsing long-formatted address into individual columns (Address, City, State)--

SELECT
  Unique_id,
  SUBSTRING_INDEX(owneraddress, ',', 1) AS address,
  SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', 2), ',', -1) AS address,
  SUBSTRING_INDEX(owneraddress, ',', -1) AS address
FROM nashvilledata;

alter table nashvilledata
add OwnerUpdatedAddress nvarchar(255) after ownerName;

update  nashvilledata
set OwnerUpdatedAddress = SUBSTRING_INDEX(owneraddress, ',', 1)
where OwnerUpdatedAddress = ''
;

alter table nashvilledata
add OwnerUpdatedCity nvarchar(255) AFTER ownerupdatedaddress;

update nashvilledata
set OwnerUpdatedCity = SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', 2), ',', -1)
where OwnerUpdatedCity = 'null';

alter table nashvilledata
add OwnerUpdatedState varchar(50) after OwnerUpdatedCity;

update nashvilledata
set OwnerUpdatedState = SUBSTRING_INDEX(owneraddress, ',', -1);


       -- Remove Duplicates --

WITH Temp as (
select *,
ROW_NUMBER() over(PARTITION BY Parcel_id,  PropertyAddress, Propertycity, SaleDate, SalePrice, LegalReference
                  order by Unique_id) as rownum
		from nashvilledata
        )
DELETE from Temp      
   where rownum >1;  
   
   -- Alternative way to delete the duplicate values --
   
   DELETE from nashvilledata
WHERE (Parcel_id, PropertyAddress, Propertycity, SaleDate, SalePrice, LegalReference, Unique_id) IN
(SELECT Parcel_id, PropertyAddress, Propertycity, SaleDate, SalePrice, LegalReference, Unique_id
FROM (SELECT *, ROW_NUMBER() over(PARTITION BY Parcel_id, PropertyAddress, Propertycity, SaleDate, SalePrice, LegalReference
order by Unique_id) as rownum
FROM nashvilledata) temp
WHERE rownum >1);

-- Standardize Date Format field --

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate);


   -- Drop Unnecessary columns--
   
   ALTER table nashvilledata
   DROP OwnerAddress ;
   
    ALTER table nashvilledata
   DROP SaleDate;
   
    ALTER table nashvilledata
   DROP PropertyAddress;
   
   
