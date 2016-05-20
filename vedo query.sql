use GenesysDatamart

select mrn
		,[note date]
		,substring([Note Text]
					,charindex('current outpatient prescriptions'
								,[note text]
								,0)
					,1000) as meds 
into #meds
from dbo.dr_7102_prnotes 
where [note text] 
	like '%metronidazole%'
	and DEPARTMENT_NAME = 'GASTROENTEROLOGY'


select * from #meds where meds like '%current outpatient prescriptions%'


select mrn
		,[note date]
		,case when (charindex('family history',[note text],0) -


					charindex('surgical history',[note text])) < 0
		Then null
		else
		substring([Note Text]
		-----starting position=
					,charindex('surgical history'
								,[note text]
								,0)
		-----length = final position - starting
					------final position =
					,charindex('family history',[note text],0) -
					------initial position =

					charindex('surgical history',[note text]
								,0)) end
		as surgtext
					 
into #surgeries
from dbo.dr_7102_prnotes 
where [note text] 
	like '%surgical history%' and [note text] like '%resection%'
	and DEPARTMENT_NAME = 'GASTROENTEROLOGY'

select distinct * from #surgeries where #surgeries.surgtext is not null and [Note date] is not null

select distinct a.mrn into #metro from #meds a
join dr_7102_redcap_data b  on a.mrn = b.mrn
where b.diagnosis like '1' and a.meds like '%current outpatient prescriptions%'

select distinct a.mrn from #metro a 
join #surgeries b on a.MRN = b.MRN
where surgtext is not null and [Note date] is not null
