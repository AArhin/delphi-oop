# Dynamic SQL Builder #

Some usage examples:

**Select statements:**
```delphi

FSQLBuilder := TTransactSQLBuilder.Create();
LSQL := FSQLBuilder
.Select.Column('C.FIRSTNAME').Column('C.LASTNAME')
.From('dbo.Customers C')
.Join('dbo.Details D on D.ID=C.ID')
.Where('C.CUSTNAME = ''Foobar''')
.Where('D.CUSTORDER = 1')
.ToString;
```

Output:

```sql

SELECT
C.FIRSTNAME,C.LASTNAME
FROM dbo.Customers C
JOIN dbo.Details D on D.ID=C.ID
WHERE (C.CUSTNAME = 'Foobar') AND (D.CUSTORDER = 1)
```


**Building update statements:**
```delphi

FSQLBuilder := TTransactSQLBuilder.Create();
LSQL := FSQLBuilder.Update
.Table('dbo.Customers')
.Column('AGE').Values('18')
.Column('NAME').Values('Null')
.ToString;
```

Output:
```sql

UPDATE dbo.Customers
SET
AGE='18'
,NAME=Null
```

_More usage examples can be found in delphi-oop core unit tests._