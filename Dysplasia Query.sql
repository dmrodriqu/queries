USE genesysdatamart 

/*

Standard Dysplasia Query

*/ 
-- selecting all colonoscopies 
SELECT mrn, 
       [note date], 
       CASE 
         WHEN ( Charindex('Impression and Plan', [note text], 0) - 
                       Charindex('Procedure:             Colonoscopy', 
                       [note text]) ) < 
              0 THEN NULL 
         ELSE Substring([note text] -----starting position= 
              , Charindex('Procedure:             Colonoscopy', [note text], 0) 
              -----length = final position - starting 
              ------final position = 
              , Charindex('Impression and Plan', [note text], 0) - 
                ------initial position = 
                Charindex('Procedure:             Colonoscopy', [note text], 0) 
                + 500) 
       END AS colonoscopies 
INTO   #colonoscopies 
FROM   dbo.dr_7102_prnotes 
WHERE  [note text] LIKE '%colonoscopy%' 
       AND department_name = 'GASTROENTEROLOGY' 

-- selecting first colonoscopies 
SELECT mrn, 
       Min([note date]) date 
INTO   #firstcolondate 
FROM   #colonoscopies 
GROUP  BY mrn 

-----------Get diagnoses by ICD codes 
---left sided 
SELECT DISTINCT mrn        AS leftmrn, 
                start_date AS leftstart, 
                end_date   AS leftend 
INTO   #leftpt 
FROM   dbo.dr_10655_icd_dx 
WHERE  icd_dx LIKE '556.5' 

---- proctitis 
SELECT DISTINCT mrn        AS procmrn, 
                start_date AS procstart, 
                end_date   AS procend 
INTO   #procpt 
FROM   dbo.dr_10655_icd_dx 
WHERE  icd_dx LIKE '556.2' 

---- pancolitis 
SELECT DISTINCT mrn        AS panmrn, 
                start_date AS panstart, 
                end_date   AS panend 
INTO   #panpt 
FROM   dbo.dr_10655_icd_dx 
WHERE  icd_dx LIKE '556.6' 

-------- Get most recent and unique diagnoses, e.g. that a left sided pt not also in proc icd table 
SELECT DISTINCT b.panmrn, 
                c.procstart, 
                c.procend, 
                a.leftstart, 
                a.leftend, 
                b.panstart, 
                b.panend, 
                CASE 
                  WHEN ( ( procstart > leftstart ) 
                          OR ( procstart > leftend ) ) 
                       AND ( ( procstart > panend ) 
                              OR ( procstart > panstart ) ) THEN 1 
                  WHEN ( ( leftstart > procend ) 
                          OR ( leftstart > procstart ) ) 
                       AND ( ( leftstart > panend ) 
                              OR ( leftstart > panstart ) ) THEN 2 
                  WHEN ( ( panstart > leftend ) 
                          OR ( panstart > leftstart ) ) 
                       AND ( ( panstart > procstart ) 
                              OR ( panstart > procend ) ) THEN 3 
                  WHEN ( ( leftstart = procend ) 
                          OR ( leftstart = procstart ) ) 
                       AND ( ( procstart > leftend ) 
                              OR ( procstart > leftstart ) ) THEN 1 
                  WHEN ( ( procstart = panend ) 
                          OR ( procstart = panstart ) ) 
                       AND ( ( leftstart > panend ) 
                              OR ( leftstart > panstart ) ) THEN 2 
                  WHEN ( ( procstart = leftend ) 
                          OR ( procstart = leftstart ) ) 
                       AND ( ( panstart > leftend ) 
                              OR ( panstart > leftstart ) ) THEN 3 
                  WHEN ( panstart IS NULL 
                         AND leftstart IS NULL ) THEN 1 
                  WHEN ( procstart IS NULL 
                         AND leftstart IS NULL ) THEN 3 
                  WHEN ( leftstart IS NULL 
                         AND procstart IS NULL ) THEN 2 
                  WHEN ( procstart IS NULL ) 
                       AND ( leftstart > panend ) 
                        OR ( leftstart > panstart ) THEN 2 
                  WHEN ( procstart IS NULL ) 
                       AND ( panstart > leftend ) 
                        OR ( panstart > panstart ) THEN 3 
                END AS extent 
INTO   #extent 
FROM   #leftpt a 
       FULL OUTER JOIN #panpt b 
                    ON a.leftmrn = b.panmrn 
       LEFT JOIN #procpt c 
              ON c.procmrn = a.leftmrn 
WHERE  panmrn IS NOT NULL 

SELECT * 
FROM   #extent 

SELECT * 
FROM   #procpt a 
       FULL OUTER JOIN #leftpt b 
                    ON a.procmrn = b.leftmrn 
       FULL OUTER JOIN #panpt c 
                    ON a.procmrn = c.panmrn 


-- Dysplasia 
SELECT mrn, 
       dbo.dr_10655_path.order_time, 
       Substring(note_text, 0, Charindex('COMMENT', note_text, 0)) AS diag 
INTO   #diagnoses 
FROM   dbo.dr_10655_path 
WHERE  note_text LIKE '%comment%' 
       AND note_text LIKE '%colon%' 

SELECT DISTINCT mrn 
INTO   #dysplasia 
FROM   #diagnoses 
WHERE  diag LIKE '%grade dysplasia%' 


---dysplasia on any colonoscopy 
SELECT * 
INTO   #dysplasiapath 
FROM   #diagnoses 
WHERE  ( diag LIKE '%grade dysplasia%' 
          OR diag LIKE '%carcinoma%' ) 


---- carcinoma pts

select *
into #carcinoma
from #dysplasiapath
where diag like '%carcinoma%'


-- demographic information 
SELECT mrn, 
       dob, 
       sex 
INTO   #demo
FROM   dbo.dr_10655_pat_demo a
join #dysplasia b
on a.MRN = b.mrn



SELECT distinct mrn
into #distinctdysplasia
FROM   #dysplasiapath-- dysplasia diagnoses prior to comments 

select distinct mrn --- carcinoma patients
into #distinctcarcinoma
FROM   #carcinoma


select * from #distinctdysplasia

select * from #distinctcarcinoma

select distinct a.mrn --- dysplasia patients minus carcinoma patients (patients that never had documented carcinoma)
from #distinctdysplasia a
left join #distinctcarcinoma b
on a.mrn = b.mrn
where b.mrn is null

select distinct diagnosis, count(diagnosis) --- diagnosis counts per dysplasia 
from #distinctdysplasia a
join dbo.dr_7102_redcap_data b
on a.mrn = b.MRN
where b.dob not like ''
group by diagnosis

select distinct diagnosis, count(diagnosis) --- diagnosis counts per dysplasia 
from #distinctcarcinoma a
join dbo.dr_7102_redcap_data b
on a.mrn = b.MRN
where diagnosis not like ''
group by diagnosis

-- drop tables 
/*
DROP TABLE #firstcolondate 

DROP TABLE #diagnoses 

DROP TABLE #colonoscopies 

DROP TABLE #leftpt 

DROP TABLE #procpt 

DROP TABLE #panpt 

DROP TABLE #indexdysplasia 

DROP TABLE #dysplasiapath 

DROP TABLE #allpts 

DROP TABLE #dyspts 

DROP TABLE #extent

DROP TABLE #sec

DROP TABLE #dysplasia

DROP TABLE #demo

DROP TABLE #hpi

DROP TABLE #duration
*/