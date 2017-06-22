USE genesysdatamart 

/*overall plan: 

1. select colonoscopies, get individuals with at least 2 colnoscopies. 
  -find time between initial and second colonoscopy 
  -confirm if dysplasia present in second colonoscopy 
    - insert case column (1/0) 
2. select those without dysplasia in the first colonoscopy 
    select where not like "grade dysplasia" from colonoscopy parse 
3. define disease extent for all individuals 
    disease extent three way comparison 
4. define age for all individuals 
    birth year to index colonoscopy 
5. define sex for all individuals 
    sex as recorded by medical record 
6. define disease duration for all individuals 
    diagnosis year, or number of years to index as recorded in medical record. 
    (terms: 
        - '%diagnosed in%' 
        - '%diagnosed%' 
        - '% __ years%' 
        define regex for numbers both as double and quadruple digits to capture 
        year or number of years 

        define case to create disease duration column 
    ) 


after finishing, option: abstract script to functions 
...especially with inner table joins 

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

-- serrated changes / SEC 
SELECT * 
INTO   #sec 
FROM   dbo.dr_10655_path 
WHERE  note_text LIKE '%colon%' 
       AND ( note_text LIKE '%serrated%' 
              OR note_text LIKE '%serrated changes%' 
              OR note_text LIKE '%serrated epithelial%' ) 
       AND ( note_text NOT LIKE '%grade dysplasia%' 
             AND note_text NOT LIKE '%sessile%' 
             AND note_text NOT LIKE '%adenoma%' 
             AND note_text NOT LIKE '%consultation%' ) 

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

--- dysplasia on first colonoscopy 
SELECT a.mrn, 
       b.date 
INTO   #indexdysplasia 
FROM   #dysplasia a 
       JOIN #firstcolondate b 
         ON a.mrn = b.mrn 

---dysplasia on any colonoscopy 
SELECT * 
INTO   #dysplasiapath 
FROM   #diagnoses 
WHERE  ( diag LIKE '%grade dysplasia%' 
          OR diag LIKE '%carcinoma%' ) 

--- only dysplasia after index 
SELECT * 
FROM   #dysplasiapath a 
       JOIN #colonoscopies b 
         ON a.mrn = b.mrn 
WHERE  a.order_time > b.[note date] 
       AND b.colonoscopies NOT LIKE '%dysplasia%' 

-- demographic information 
SELECT mrn, 
       dob, 
       sex 
INTO   #demo 
FROM   dbo.dr_10655_pat_demo 

-- disease duration ... 
SELECT mrn, 
       Substring(note_text, 0, Charindex('Past Surgical History', note_text, 0)) 
       AS HPI 
INTO   #hpi 
FROM   dbo.dr_10655_enc_notes 
WHERE  department_name LIKE '%Gastroenterology%' 
       AND ( note_text LIKE '%ulcerative colitis%' ) 
       AND ( note_text LIKE '%diagnosed%' ) 

SELECT mrn, 
       Substring(hpi, Charindex('diagnosed', hpi, 0), 
       Charindex('in', hpi, 0) + 5) AS 
       diag 
INTO   #duration 
FROM   #hpi 

SELECT * 
FROM   #duration 
WHERE  diag LIKE '%[0-9][0-9][0-9][0-9]%' 

-- 
SELECT mrn, 
       diagnosis_year 
FROM   dbo.dr_10655_redcap_extract 

--  all patients 
SELECT DISTINCT a.mrn, 
                Max(d.dob)         AS dob, 
                Max(d.sex)         AS sex, 
                Max(b.extent)      AS extent, 
                Max(c.diag)        AS diag, 
                Min(e.[note date]) AS indexcolon 
INTO   #allpts 
FROM   #diagnoses a 
       JOIN #extent b 
         ON a.mrn = b.panmrn 
       JOIN #duration c 
         ON a.mrn = c.mrn 
       JOIN #demo d 
         ON d.mrn = a.mrn 
       JOIN #colonoscopies e 
         ON e.mrn = a.mrn 
WHERE  c.diag NOT LIKE '' 
       AND c.diag LIKE '%[0-9][0-9][0-9][0-9]%' 
GROUP  BY a.mrn 

--  developed dysplasia 
SELECT DISTINCT a.mrn, 
                Max(d.dob)         AS dob, 
                Max(d.sex)         AS sex, 
                Max(b.extent)      AS extent, 
                Max(c.diag)        AS diag, 
                Min(e.[note date]) AS indexcolon 
INTO   #dyspts 
FROM   #diagnoses a 
       JOIN #extent b 
         ON a.mrn = b.panmrn 
       JOIN #duration c 
         ON a.mrn = c.mrn 
       JOIN #demo d 
         ON d.mrn = a.mrn 
       JOIN #colonoscopies e 
         ON e.mrn = a.mrn 
       JOIN #dysplasiapath f 
         ON f.mrn = a.mrn 
WHERE  c.diag NOT LIKE '' 
       AND c.diag LIKE '%[0-9][0-9][0-9][0-9]%' 
GROUP  BY a.mrn 

--- no dysplasia patients 
SELECT * 
FROM   #allpts a 
       LEFT JOIN #dyspts b 
              ON a.mrn = b.mrn 
WHERE  b.mrn IS NULL 


--tables 
SELECT * 
FROM   #diagnoses -- path text prior to comment (all)

SELECT * 
FROM   #dysplasiapath-- dysplasia diagnoses prior to comments 

SELECT * 
FROM   #colonoscopies --all colonoscopy notes 

SELECT * 
FROM   #firstcolondate -- index colonoscopy date (first colonoscopy date for all patients)

SELECT * 
FROM   #extent -- extent of disease per patient 

SELECT * 
FROM   #indexdysplasia -- dysplasia on index 

SELECT * 
FROM   #allpts -- all patients

SELECT *
FROM   #dyspts -- patients that developed dysplasia 

SELECT *  
FROM   #sec -- sec patients



-- drop tables 

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