
 --------------data cleaning in sql--------------------------------


 SELECT Count(*) FROM housings;

 SELECT * FROM housings;

--standardize date format ( change timestamp to date(yyyy-mm-dd)
 SELECT saledate, To_Char(saledate,'yyyy-mm-dd') AS std_saledate FROM housings;


---------------------------------------------------------------------------------------------------------------

--populate property address data


--A "parcel ID" or "parcel identification number" is a unique identifier assigned to a specific parcel of real estate or land.
SELECT * FROM housings
--WHERE propertyaddress IS NULL
  ORDER BY parcelid ;


SELECT DISTINCT a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress, NVL(a.propertyaddress, b.propertyaddress)
FROM housings a
JOIN housings b ON a.parcelid = b.parcelid AND a.uniqueid != b.uniqueid
WHERE a.propertyaddress IS NULL;

--update the null value with matching value
MERGE INTO housings a
USING (
  SELECT a.uniqueid, a.parcelid, MAX(b.propertyaddress) AS propertyaddress
  FROM housings a
  JOIN housings b ON a.parcelid = b.parcelid AND a.uniqueid != b.uniqueid
  WHERE a.propertyaddress IS NULL
  GROUP BY a.uniqueid, a.parcelid
) b
ON (a.uniqueid = b.uniqueid)
WHEN MATCHED THEN
UPDATE SET a.propertyaddress = b.propertyaddress;

SELECT * FROM housings WHERE parcelid = '093 08 0 054.00';

-----------------------------------------------------------------------------------------------------------

--breaking out propertyaddress into individual columns (address,city)


SELECT propertyaddress FROM housings;


SELECT SubStr(propertyaddress,1,InStr(propertyaddress,',')-1) AS propertysplitaddress ,
Trim(SubStr(propertyaddress,InStr(propertyaddress,',') + 1)) AS propertysplitcity
FROM housings;


ALTER TABLE housings ADD property_split_address VARCHAR2(200);
ALTER TABLE housings ADD property_split_city VARCHAR2(200);


UPDATE housings
SET
property_split_address = SubStr(propertyaddress,1,InStr(propertyaddress,',')-1);

UPDATE housings
SET property_split_city= (
Trim(SubStr(propertyaddress,InStr(propertyaddress,',') + 1))
);

SELECT propertyaddress,property_split_address,property_split_city FROM housings;

--- spliting owner address into (address,city,state)

SELECT owneraddress FROM housings;

SELECT owneraddress,
SubStr(owneraddress,1,InStr(owneraddress,',',1,1) - 1) AS owner_split_address  ,
Trim ( SubStr(owneraddress,InStr(owneraddress,',',1,1)+1,InStr(owneraddress,',',1,2) - InStr(owneraddress,',',1,1) -1 ) )  AS owner_split_city ,
SubStr(owneraddress,InStr(owneraddress,',',1,2) + 1 ) AS owner_split_state
FROM housings;

 ALTER TABLE housings ADD owner_split_address VARCHAR2(200);
 ALTER TABLE housings  ADD owner_split_city VARCHAR2(200);
 ALTER TABLE housings ADD owner_split_state VARCHAR2(200);

UPDATE housings
SET  owner_split_address= SubStr(owneraddress,1,InStr(owneraddress,',',1,1) - 1);

UPDATE housings
SET  owner_split_city = Trim ( SubStr(owneraddress,InStr(owneraddress,',',1,1)+1,InStr(owneraddress,',',1,2) - InStr(owneraddress,',',1,1) -1 ) );

UPDATE housings
SET owner_split_state = SubStr (owneraddress,InStr(owneraddress,',',1,2) + 1 );

SELECT owneraddress,owner_split_address,owner_split_city,owner_split_state FROM housings;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------


--change Y and N to yes and no in soldasvacant field

SELECT DISTINCT soldasvacant FROM housings
-- WHERE soldasvacant = 'Y';
SELECT  soldasvacant FROM housings
 WHERE soldasvacant = 'N' OR soldasvacant = 'Y';

SELECT
 CASE
      WHEN soldasvacant='Y' THEN  'Yes'
      WHEN soldasvacant='N' THEN  'No'
 END AS std_soldasvacant
FROM housings WHERE soldasvacant IN ('Y','N');

--or easy one
SELECT
 CASE
      WHEN soldasvacant='Y' THEN  'Yes'
      WHEN soldasvacant='N' THEN  'No'
      ELSE soldasvacant
 END AS std_soldasvacant
FROM housings


---updating the field
UPDATE housings
SET soldasvacant = (
 CASE
      WHEN soldasvacant='Y' THEN  'Yes'
      WHEN soldasvacant='N' THEN  'No'
 END
 )
 WHERE soldasvacant IN ('Y','N');

SELECT DISTINCT soldasvacant FROM housings;

SELECT soldasvacant ,Count(*) FROM housings GROUP BY soldasvacant;
--------------------------------------------------------------------------------------------------------------------------


-- remove duplicates

--so based on pracelid,propertyaddress,saleprice,saledate,legalreference we are going to find dupilcates
--finding duplicate records;
WITH cte AS
(
SELECT h.*,
Row_Number() OVER
(
PARTITION BY
 parcelid,
 propertyaddress,
 saleprice,
 saledate,
 legalreference
 ORDER BY uniqueid
 ) row_num
FROM  housings h
)SELECT * FROM cte WHERE row_num > 1;

--seems like 104 rows are duplicates

--before deleting lets put this in another table
--only structure not data
 CREATE TABLE duplicate_housing AS
 SELECT * FROM housings WHERE 1=0;


 SELECT * FROM duplicate_housing;

 ALTER TABLE duplicate_housing RENAME TO duplicate_housings;

 ALTER TABLE duplicate_housings ADD row_num NUMBER;

 SELECT * FROM duplicate_housings;

 --inserting the duplicate before deleting it
INSERT INTO duplicate_housings
 WITH cte AS
(
SELECT h.*,
Row_Number() OVER
(
PARTITION BY
 parcelid,
 propertyaddress,
 saleprice,
 saledate,
 legalreference
 ORDER BY uniqueid
 ) row_num
FROM  housings h
)SELECT * FROM cte WHERE row_num > 1;

SELECT * FROM duplicate_housings;

---now deleting duplicates
DELETE FROM housings WHERE uniqueid IN  (
SELECT uniqueid FROM
(
 SELECT h.*,
         ROW_NUMBER() OVER (
           PARTITION BY
             parcelid,
             propertyaddress,
             saleprice,
             saledate,
             legalreference
           ORDER BY uniqueid
         ) row_num
  FROM  housings h
)
 WHERE row_num > 1
);

-------------------------------------------------------------------------------------------------------------

--delete unused columns

--like propertyaddress,owneraddresee coz we have already split them into more useful columns

ALTER TABLE housings
DROP COLUMN owneraddress;

ALTER TABLE housings
DROP COLUMN propertyaddress;

