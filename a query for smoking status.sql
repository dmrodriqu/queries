------ finding current smokers

select 
	ID
	, [Note date]
	, SUBSTRING([Note Text]
	, CHARINDEX('current smoker',[Note Text],0),14) as currsmoker
into #currentsmoker
from — TABLE REDACTED -
where [Note Text] like '%current smoker%'

----- finding most recent mention of current smoking

select
	ID
	,MAX([Note date]) Max_Date
	into #smokerdates
	from #currentsmoker
	group by ID

select a.ID, a.[Note date] into #recentsmoker from #currentsmoker a
join #smokerdates b
on a.[Note date] = b.Max_Date


----- reducing false positives, finding former smokers

select 
	ID
	,[Note date]
	, SUBSTRING([Note Text]
	, CHARINDEX('former smoker',[Note Text],0),14) as currsmoker
into #formersmoker
from — TABLE REDACTED -
where [Note Text] like '%former smoker%'


select
	ID
	,MAX([Note date]) Max_Date
	into #formerdates
	from #formersmoker
	group by ID


select a.ID, a.[Note date] into #recentformer from #formersmoker a
join #formerdates b
on a.[Note date] = b.Max_Date


-----selecting for only current smokers


select (a.ID) as smokerID, a.[Note date],(b.ID) as formerID, (b.[Note date]) as formerdate,
	case 
		when a.[Note Date] > b.[Note Date] then 'current'
		when a.[Note date] < b.[Note date] then 'former'
		when a.[Note date] is null then 'former'
		when b.[Note date] is null then 'current'
		end as iscurrentsmoker
into #output
from #recentsmoker a
full outer join #recentformer b
on b.ID = a.ID

select (smokerID) as ID from #output 
where iscurrentsmoker like 'current'

