select mrn
		,[note date]
		,case when (charindex('Impression and Plan',[note text],0) -


					charindex('Procedure:             Colonoscopy',[note text])) < 0
		Then null
		else
		substring([Note Text]
		-----starting position=
					,charindex('Procedure:             Colonoscopy'
								,[note text]
								,0)
		-----length = final position - starting
					------final position =
					,charindex('Impression and Plan',[note text],0) -
					------initial position =

					charindex('Procedure:             Colonoscopy',[note text]
								,0) +500) end
		as colonoscopies
					 
into #colonoscopies
from dbo.dr_7102_prnotes 
where [note text] 
	like '%colonoscopy%' and [note text] like '%stricture%'
	and DEPARTMENT_NAME = 'GASTROENTEROLOGY'


select mrn, max([Note date]) date into #colonotedate 
from #colonoscopies group by mrn

drop table #colonotedate


select max(mrn) as mrn, max(colonoscopies) as colonoscopy, max([note date]) as date into #strictures from #colonoscopies
where colonoscopies like '%stricture%'
group by mrn


------------------------------------------------------------------------------------------------------------strictures

Select mrn
	,SUBSTRING(colonoscopy,CHARINDEX('stricture', colonoscopy, 0)-10,50)
from #strictures
where colonoscopy like '%stricture%' and colonoscopy not like '%no strictures%'


----------------------------------------------------------------------------------------------------------malignant strictures
Select mrn
	,SUBSTRING(colonoscopy,CHARINDEX('grade stricture', colonoscopy, 0)-20,60)
from #strictures
where colonoscopy like '%grade stricture%' and colonoscopy not like '%no strictures%'


select mrn
		,case when (charindex('recommendation',colonoscopy,0) -


					charindex('impression',colonoscopy)) < 0
		Then null
		else
		substring(colonoscopy
		-----starting position=
					,charindex('impression'
								,colonoscopy
								,0)
		-----length = final position - starting
					------final position =
					,charindex('recommendation',colonoscopy,0) -
					------initial position =

					charindex('impression',colonoscopy
								,0) ) end
		as severity
into #impression					 
from #strictures 





------------------------------- get demographic data

select * from dr_7102_redcap_data
select * from dr_7102_redcap_metadata
--- mrn, study id, dob, sex, diagnosis, diagnosis_year, 

select mrn
	, study_id
	, dob, sex
	, diagnosis
	, diagnosis_year
into #demos
from dr_7102_redcap_data
where dob not like ''




 select distinct mrn from #strictures

------------------------------- get stricture data

select 
	mrn
	,SUBSTRING([Note Text]
	,charindex('stricture', [Note Text], 50)
	,50) as strictures 
	into #stricturetable
	from dr_7102_prnotes
	where [Note Text] like '%colonoscopy%'
	and [Note Text] like '%stricture%'
	
select 
	mrn
	,SUBSTRING([Note Text]
	,charindex('stricture', [Note Text], 50)- 20
	,40) as strictures 
	from dr_7102_prnotes
	where [Note Text] like '%colonoscopy%'
	and [Note Text] like '%stricture%'

select 
	mrn
	,SUBSTRING([Note Text]
	,charindex('anal stricture', [Note Text], 50)
	,14)as analstricture
	into #analstricture
	from dr_7102_prnotes
	where [Note Text] like '%colonoscopy%'
	and [Note Text] like '% anal stricture%'

select 
	mrn
	,SUBSTRING([Note Text]
	,charindex('anorectal stricture', [Note Text], 50)
	,20)as anorectalstricture
	into #anorectalstricture
	from dr_7102_prnotes
	where [Note Text] like '%colonoscopy%'
	and [Note Text] like '% anorectal stricture%'

select 
	mrn
	,SUBSTRING([Note Text]
	,charindex('colon stricture', [Note Text], 50)-15
	,60)as colonstricture
	into #colonstricture
	from dr_7102_prnotes
	where [Note Text] like '%colonoscopy%'
	and [Note Text] like '%colon stricture%'

select 
	mrn
	,SUBSTRING([Note Text]
	,charindex('ascending colon stricture', [Note Text], 50)-20
	,25)as asccolonstricture
	into #acstricture
	from dr_7102_prnotes
	where [Note Text] like '%colonoscopy%'
	and [Note Text] like '%transverse colon stricture%'

select 
	mrn
	,SUBSTRING([Note Text]
	,charindex('sigmoid colon stricture', [Note Text], 50)
	,25)as sigcolonstricture
	into #sigstricture
	from dr_7102_prnotes
	where [Note Text] like '%colonoscopy%'
	and [Note Text] like '%sigmoid colon stricture%'

select 
	mrn
	,SUBSTRING([Note Text]
	,charindex('transverse colon stricture', [Note Text], 50)-20
	,25)as transcolonstricture
	into #transtricture
	from dr_7102_prnotes
	where [Note Text] like '%colonoscopy%'
	and [Note Text] like '%transverse colon stricture%'

select 
	mrn
	,SUBSTRING([Note Text]
	,charindex('descending colon stricture', [Note Text], 50)-20
	,25) as descolonstricture
	into #destricture
	from dr_7102_prnotes
	where [Note Text] like '%colonoscopy%'
	and [Note Text] like '%descending colon stricture%'

select 
	mrn
	,SUBSTRING([Note Text]
	,charindex('R colon stricture', [Note Text], 50)
	,40) as descolonstricture
	into #rstricture
	from dr_7102_prnotes
	where [Note Text] like '%colonoscopy%'
	and [Note Text] like '%R colon stricture%'


------------------------------- malignancy data


select
	 mrn,
	 [Note date],
	 [Note Text]
	from dr_7102_prnotes
	where [Note Text] like '%CDEIS%'
	or  [Note Text] like '%SES-CD%'



select 
	mrn
	,SUBSTRING([Note Text]
	,charindex('SES-CD', [Note Text], 50)
	,50)as SESCD
	into #SESCD
	from dr_7102_prnotes
	where [Note Text] like '%SES-CD%'

select 
	mrn
	,SUBSTRING([Note Text]
	,charindex('Rutgert', [Note Text], 50)
	,50)as rutgert
	into #rutgert
	from dr_7102_prnotes
	where [Note Text] like '%Rutgert%'

select 
	mrn
	,SUBSTRING([Note Text]
	,charindex('uceis', [Note Text], 50)
	,50)as uceis

	from dr_7102_prnotes
	where [Note Text] like '%uceis%'
-------------------------------severity
select mrn,
	SUBSTRING(severity,
	CHARINDEX('',severity,0)-20,40)
from #impression
where severity like '%disease%' 

select mrn
	,CASE when severity like '%moderate%' THEN 'moderate'
	when severity like '%mild%' THEN 'mild'
	when severity like '%severe%' THEN 'severe'
	else severity end 
from #impression where severity is not null



select a.mrn, a.narrative, a.order_time,
	CASE when narrative like '%moderate%' THEN 'moderate'
	when narrative like '%mild%' THEN 'mild'
	when narrative like '%severe%' THEN 'severe'
	else null end as severity
into #pathsev
from dr_7102_path a
join #strictures b on a.mrn = b.mrn
where narrative like '%colon%'

select mrn, max(severity), max(order_time) from #pathsev group by mrn


---- individuals with dysplasia and strictures
select mrn,
	CASE when colonoscopy like '%low_grade%' then 'low grade'
	when colonoscopy like '%high_grade%' then 'high grade'
	else null end as dysplasia
into #stricdys
from #strictures where colonoscopy like '%grade dysplasia%' 

---- indivduals with cancer and stricture
select mrn,
	CASE when colonoscopy like '%carcinoma%' then 'carcinoma'
	else null end as carcinoma
into #carcinoma
from #strictures where colonoscopy like '%carcinoma%' 

--- diverticular disease
select mrn,
	CASE when colonoscopy like '%diverticu%' then 'diverticular'
	else null end as diverticular
into #diverticular from #strictures where colonoscopy like '%diverticu%' 

--- individuals with anastamosis
select mrn,
	CASE when colonoscopy like '%anastamo%' then 'anastamosis'
	else null end as anastamosis 
into #anastamosis
from #strictures where colonoscopy like '%anastamo%' 


---sticture for surg
select * from dr_7102_prnotes a
join  #strictures b on a.MRN = b.mrn
where DEPARTMENT_NAME like '%surg%' and Category like '%Operative Report%'


-------montreal

select distinct mrn
		,[note date]
		,substring([Note Text]
					,charindex('montreal classification'
								,[note text]
								,25)
					,38) as montreal 
into #montreal
from dbo.dr_7102_prnotes
where [note text] 
	like '%montreal classification%'
	and DEPARTMENT_NAME = 'GASTROENTEROLOGY'

select distinct a.mrn, montreal into #strictmont from #montreal b 
join #strictures a on a.mrn = b.MRN

-----------medications




select M.mrn
		,[Note date]
		,CASE WHEN substring([Note Text]
					,charindex('5-asa'
								, [note text]
								, 25)
					, 14) like '%5-ASA%' then '5-ASA'
			  WHEN substring([Note Text]
					,charindex('mesalamine'
								, [note text]
								, 25)
					, 14) like '%mesalamine%' then '5-ASA'
			  END  as asa into #asa
from dbo.dr_7102_prnotes d
inner join #strictures M
on M.mrn = d.MRN 
where [note text] 
	like '%5-asa%' or [Note Text] like '%mesalamine%'
	and DEPARTMENT_NAME = 'GASTROENTEROLOGY' 

Select  ---the max note dates
	MRN
	,max([Note date]) Max_Date
	into #asadates
	from #asa
	group by MRN

select n.* 
into #asa_output
from #asadates d
INNER JOIN 
#asa n
on d.MRN = n.MRN and n.[Note date] = d.Max_Date
select * from #asa_output

--drop table #asa
--drop table #asadates
--drop table #asa_output
-------------------------(those exposed to budesonide)


select M.mrn
		,[Note date]
		,substring([Note Text]
					,charindex('budesonide'
								, [note text]
								, 25)
					, 14) as budesonide into #budesonide
from dbo.dr_7102_prnotes d
inner join #strictures M
on M.mrn = d.MRN 
where [note text] 
	like '%budesonide%'
	and DEPARTMENT_NAME = 'GASTROENTEROLOGY' 

Select  ---the max note dates
	MRN
	,MAX([Note date]) Max_Date
	into #budesonidedates
	from #budesonide
	group by MRN

select n.* 
into #budesonide_output
from #budesonidedates d
INNER JOIN 
#budesonide n
on d.MRN = n.MRN and n.[Note date] = d.Max_Date

-------------------------------------------------------------------(selecting prednisone)

select M.mrn
		,[Note date]
		,substring([Note Text]
					,charindex('prednisone'
								, [note text]
								, 25)
					, 14) as pred into #prednisone
from dbo.dr_7102_prnotes d
inner join #strictures M
on M.mrn = d.MRN 
where [note text] 
	like '%prednisone%'
	and DEPARTMENT_NAME = 'GASTROENTEROLOGY'
select * from #prednisone	


Select  ---the max note dates
	MRN
	,MAX([Note date]) Max_Date
	into #prednisonedates
	from #prednisone
	group by MRN

select n.* 
into #prednisone_output
from #prednisonedates d
INNER JOIN 
#prednisone n
on d.MRN = n.MRN and n.[Note date] = d.Max_Date



--------------------------------------------------------------------(Selecting imuran)

select M.mrn
		,[Note date]
		,substring([Note Text]
					,charindex('imuran'
								, [note text]
								, 25)
					, 14) as imuran into #imuran
from dbo.dr_7102_prnotes d
inner join #strictures M
on M.mrn = d.MRN 
where [note text] 
	like '%imuran%'
	and DEPARTMENT_NAME = 'GASTROENTEROLOGY' 

Select  ---the max note dates
	MRN
	,MAX([Note date]) Max_Date
	into #imurandates
	from #imuran
	group by MRN

select n.* 
into #imuran_output
from #imurandates d
INNER JOIN 
#imuran n
on d.MRN = n.MRN and n.[Note date] = d.Max_Date


---------------------------------------------------------------(selecting 6mp)
select m.mrn
		,[Note date]
		,substring([Note Text]
					,charindex('6-mp'
								, [note text]
								, 25)
					, 14) as mp into #mp
from dbo.dr_7102_prnotes d
inner join #strictures M
on M.mrn = d.MRN 
where [note text] 
	like '%6-mp%'
	and DEPARTMENT_NAME = 'GASTROENTEROLOGY' 

Select  ---the max note dates
	MRN
	,MAX([Note date]) Max_Date
	into #mpdates
	from #mp
	group by MRN

select n.* 
into #mp_output
from #mpdates d
INNER JOIN 
#mp n
on d.MRN = n.MRN and n.[Note date] = d.Max_Date


---------------------------------------------------------------(selecting methotrexate)
select M.mrn
		,[Note date]
		,substring([Note Text]
					,charindex('methotrexate'
								, [note text]
								, 25)
					, 14) as metho into #methotrexate
from dbo.dr_7102_prnotes d
inner join #strictures M
on M.mrn = d.MRN 
where [note text] 
	like '%methotrexate%'
	and DEPARTMENT_NAME = 'GASTROENTEROLOGY' 

Select  ---the max note dates
	MRN
	,MAX([Note date]) Max_Date
	into #methotrexate_dates
	from #methotrexate
	group by MRN

select n.* 
into #metho_output
from #methotrexate_dates d
INNER JOIN 
#methotrexate n
on d.MRN = n.MRN and n.[Note date] = d.Max_Date


---------------------------------------------------------------(selecting antiTNF)
select m.mrn
		,[Note date]
		,substring([Note Text]
					,charindex('TNF'
								, [note text]
								, 25)
					, 14) as TNF into #TNF
from dbo.dr_7102_prnotes d
inner join #strictures M
on M.mrn = d.MRN 
where [note text] 
	like '%anti-TNF%'
	and DEPARTMENT_NAME = 'GASTROENTEROLOGY' 

Select  ---the max note dates
	MRN
	,MAX([Note date]) Max_Date
	into #TNFDates
	from #TNF
	group by MRN

select n.* 
into #TNF_output
from #TNFDates d
INNER JOIN 
#TNF n
on d.MRN = n.MRN and n.[Note date] = d.Max_Date


---------------------------------------------------------------(selecting vedo)
select m.mrn
		,[Note date]
		,substring([Note Text]
					,charindex('vedolizumab'
								, [note text]
								, 25)
					, 14) as vedolizumab into #vedo
from dbo.dr_7102_prnotes d
inner join #strictures M
on M.mrn = d.MRN 
where [note text] 
	like '%vedolizumab%'
	and DEPARTMENT_NAME = 'GASTROENTEROLOGY' 

Select mrn
	,MAX([Note date]) Max_Date  ---the max nodate]) Max_Date
	into #vedodates
	from #vedo
	group by MRN

select n.* 
into #vedo_out
from #vedodates d
INNER JOIN 
#vedo n
on d.MRN = n.MRN and n.[Note date] = d.Max_Date


---------------------------------------------------------------(selecting cyclosporin)
select m.mrn
		,[Note date]
		,substring([Note Text]
					,charindex('cyclosporin'
								, [note text]
								, 25)
					, 14) as cyclosporin into #cyclo
from dbo.dr_7102_prnotes d
inner join #strictures M
on M.mrn = d.MRN 
where [note text] 
	like '%cyclosporin%'
	and DEPARTMENT_NAME = 'GASTROENTEROLOGY' 

Select  ---the max note dates
	MRN
	,MAX([Note date]) Max_Date
	into #cyclodates
	from #cyclo
	group by MRN

select n.* 
into #cyclo_out
from #cyclodates d
INNER JOIN 
#cyclo n
on d.MRN = n.MRN and n.[Note date] = d.Max_Date


---------------------------------------------------------------(selecting tacro)
select m.mrn
		,[Note date]
		,substring([Note Text]
					,charindex('tacrolimus'
								, [note text]
								, 25)
					, 14) as tacrolimus into #tacro
from dbo.dr_7102_prnotes d
inner join #strictures M
on M.mrn = d.MRN 
where [note text] 
	like '%tacrolimus%'
	and DEPARTMENT_NAME = 'GASTROENTEROLOGY' 

Select  ---the max note dates
	MRN
	,MAX([Note date]) Max_Date
	into #tacrodates
	from #tacro
	group by MRN

select n.* 
into #tacro_out
from #tacrodates d
INNER JOIN 
#tacro n
on d.MRN = n.MRN and n.[Note date] = d.Max_Date

---------------------------------------------------------------(selecting first flare)
select m.mrn
		,[Note Text]
		,[Note date]
		,substring([Note Text]
					,charindex('prednisone'
								, [note text]
								, 25)
					, 14) as flare into #firstflare
from dbo.dr_7102_prnotes d
inner join #strictures M
on M.mrn = d.MRN 
where (([note text] 
	like '%diagnose%' and [Note Text] like '%prednisone%') or 
	([Note Text] like '%flare%' and [Note Text] like '%prednisone%'))
	and DEPARTMENT_NAME = 'GASTROENTEROLOGY' 

Select  ---the max note dates
	MRN
	,MIN([Note date]) MIN_DATE
	into #flaredate
	from #firstflare
	group by MRN

select n.* 
into #firstflare_out
from #flaredate d
INNER JOIN 
#firstflare n
on d.MRN = n.MRN and n.[Note date] = d.MIN_DATE
select * from #firstflare_out

--drop table #firstflare
--drop table #flaredate
--drop table #firstflare_out




select * from dr_7102_prnotes







-----------medications

select distinct t1.mrn
	, t1.dob
	, t1.sex
	, t1.diagnosis
	, t1.diagnosis_year
	, t2.montreal
	, t3.SESCD
	, t4.rutgert
	, b.dysplasia
	, c.severity
	, d.anastamosis
	, e.carcinoma
	,f.diverticular
	,j.analstricture
	,k.anorectalstricture
	,l.colonstricture
	,m.asccolonstricture
	,n.sigcolonstricture
	,o.transcolonstricture
	,p.descolonstricture
    ,q.descolonstricture as rcolon
into #stricturefinal
from #demos t1
left join #SESCD t3 on t3.MRN = t1.mrn
left join #rutgert t4 on t4.MRN = t1.mrn
left join #strictmont t2 on t2.mrn =t1.mrn
left join #strictures a on a.mrn = t1.mrn
left join #stricdys b on t1.mrn = b.mrn
left join #pathsev c on t1.mrn = c.mrn
left join #anastamosis d on d.mrn = t1.mrn
left join #carcinoma e on e.mrn = t1.mrn
left join #diverticular f on f.mrn = t1.mrn
left join #analstricture j on j.MRN= t1.mrn
left join #anorectalstricture k on k.MRN= t1.mrn
left join #colonstricture l on l.MRN= t1.mrn
left join #acstricture m  on m.MRN= t1.mrn
left join #sigstricture n on n.MRN= t1.mrn
left join #transtricture o on o.MRN= t1.mrn
left join #destricture p on p.MRN= t1.mrn
left join #rstricture q on q.MRN= t1.mrn
where a.mrn is not null


select distinct t1.mrn
	,t2.diagnosis
	,r.asa
	,s.budesonide
	,t.pred
	,u.imuran
	,v.mp
	,w.TNF
	,x.vedolizumab
	,y.cyclosporin
	,z.tacrolimus
into #meds
from #strictures t1
join #demos t2 on t2.mrn = t1.mrn
LEFT JOIN #asa_output r on r.mrn = t1.mrn
LEFT JOIN #budesonide_output s on s.mrn = t1.mrn
LEFT JOIN #prednisone_output t on t.MRN = t1.mrn
LEFT JOIN #imuran_output u on u.MRN = t1.mrn
LEFT JOIN #mp_output v on v.MRN = t1.mrn
LEFT JOIN #TNF_output w on w.MRN =t1.mrn
LEFT JOIN #vedo_out x on x.MRN = t1.mrn
LEFT JOIN #cyclo_out y on y.MRN  = t1.mrn
LEFT JOIN #tacro_out z on z.MRN = t1.mrn
where t1.mrn is not null

select * from #stricturefinal a
join #meds b on a.mrn = b.mrn