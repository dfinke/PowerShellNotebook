/* Look up user and phone number by last name
We match on first found in case of multiple
*/
declare @phonenumber nvarchar(50)
declare @lastname nvarchar(50)
declare @busentityid INT

set @lastname = 'Tamburello'

select 
top 1
@busentityid = BusinessEntityID -- Will be used to lookup phone number
from Person.Person
where LastName = @lastname

/* Only look for phone if we found the person
-- Should usually be null or 1, values over 1 not really possible
*/
if @busentityid is not null
begin

   select 
      p.FirstName,
      p.MiddleName,
      p.LastName,
      p.Suffix,
      pp.PhoneNumber
   from 
      Person.Person p
      left join Person.PersonPhone pp
      on p.BusinessEntityID = pp.BusinessEntityID
   where 
      p.BusinessEntityID = @busentityid

/* Save the phonenumber from the selected user */
   select 
      @phonenumber = PhoneNumber 
   from 
      Person.Person p
      left join Person.PersonPhone pp
      on p.BusinessEntityID = pp.BusinessEntityID
   where
      p.BusinessEntityID = @busentityid

end

go 

-- Wait for 4 seconds total after go 2
RAISERROR('waiting', 1,1) with nowait
select GETUTCDATE() as 'Waiting'
waitfor delay '00:00:02'

-- note the Go 2 has been *removed*
go

-- This select statement returns the full customer address list
select 
    p.FirstName,
    p.MiddleName,
    p.LastName,
    p.Suffix,
    a.AddressLine1,
    a.AddressLine2,  -- TODO: Should we concat line 1 and 2
    a.City,
    /*
    Debug stuff
    p.BusinessEntityID,
    bea.BusinessEntityID,
    bea.AddressID,
    a.AddressiD,
    sp.StateProvinceID,
    sp.StateProvinceID
    */
    sp.StateProvinceCode, /* TODO: Need to add country here too, join below */
    a.PostalCode--,
    --sp.CountryRegionCode 
 from 
    Person.Person p
    left join Person.BusinessEntityAddress bea  -- Used for joining, not selected from
    on p.BusinessEntityID = bea.BusinessEntityID 
    left join Person.Address a 
    on bea.AddressID = a.AddressID
    left join Person.StateProvince sp 
    on a.StateProvinceID = sp.StateProvinceID
    /* Commenting out until the field is added
    left join Person.CountryRegion cr 
    on sp.CountryRegionCode = cr.CountryRegionCode
    */

