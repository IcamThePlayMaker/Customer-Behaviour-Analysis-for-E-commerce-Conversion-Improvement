---------------------------------------------------------------- CHECK PHASE-----------------------------------------------------

-- SELECT masked_user_id,count (*) as Total_Number_Of_Transaction
-- FROM `bitlabs-dab.I_CID_02.activity` 
-- GROUP BY masked_user_id
-- having count(masked_user_id) >30 ; # Total Number record of transaction every customer is 30 

-- SELECT 
--   count(distinct masked_user_id)
-- FROM 
--   `bitlabs-dab.I_CID_02.activity`  ; #143324

-- SELECT 
--   count(distinct masked_user_id) 
-- FROM 
--   `bitlabs-dab.I_CID_02.user` ; # 143340 | antar dua tabel jumlah customernya beda





------------------------------------------------------------ VALIDATION PHASE ---------------------------------------------------

#Validasi perbedaan masked_user_id antara 2 tabel
-- WITH x AS
-- (
--   SELECT 
--     count(distinct masked_user_id) AS Number_of_masked_user_id,
--     masked_user_id
--   FROM 
--     `bitlabs-dab.I_CID_02.user` 
--   GROUP BY 2) ,

--       y AS
-- (
--   SELECT 
--     count(distinct masked_user_id),
--     masked_user_id,


--   FROM 
--     `bitlabs-dab.I_CID_02.activity` 
--   GROUP BY 2) 

-- SELECT * FROM x
-- EXCEPT DISTINCT
-- SELECT * FROM y ;
  
-- SELECT 
--   * 
-- FROM 
--   `bitlabs-dab.I_CID_02.user` 
-- WHERE 
--   masked_user_id in 
--                   ( "b4fb8e38-f476-463b-8b6f-8a680fb0c37b",
--                     "6488b3db-714d-4845-b0f2-5dd71a8227de",
--                     "ec4fe4e5-9ead-4376-8751-47a968f690fb",
--                     "19d3f15a-58ee-484e-bcb1-ed78268a7147",
--                     "1ea17eee-cd76-471d-bb33-b41940eb6707",
--                     "92c469db-11a6-40e0-8585-48c46ad6801d",
--                     "0a50f6a7-1aa4-4779-8316-ef1cb204cd25",
--                     "e27bae53-a159-444b-bebd-52a0f1e2fbda",
--                     "d5a9e082-a6be-4952-a99c-a3766b0d0f29",
--                     "95c9d14f-614a-4bec-a567-1215935112b2",
--                     "af393e60-e72b-4315-8830-572e30f12017",
--                     "9394a637-7d6f-48af-be46-7dec4ce2199b",
--                     "c0b712cb-09a0-4c11-8032-4d7d23ae0520",
--                     "0f83f6de-e591-4b16-a69e-0d3dae537ae0",
--                     "8ec63066-76c1-4368-b7a1-8de8422fe6ec",
--                     "73213c38-40f4-4a7e-bfdd-ae64553855aa") ;  
#kemungkinan yang paling mungkin user user ini tidak melakukan aktivitas selama tahun 2022 bulan 4 #validasi ini berguna untuk kalo join harus inner join



-------------------------------------------------------------- NOMOR 1-------------------------------------------------------
#conversion rate
WITH TR AS
(
SELECT
  count(is_make_order) as true_order
FROM
   `bitlabs-dab.I_CID_02.activity`
WHERE is_make_order = TRUE), 

TV AS
(
SELECT
  count(distinct masked_user_id) as total_visitor
FROM
 `bitlabs-dab.I_CID_02.activity`)

 SELECT concat(ROUND(TR.true_order/TV.total_visitor*100,2),'%') as convertion_rate
 FROM TR,TV ;


---------------------------------------------------------   NOMOR 2 -----------------------------------------------------------
#conversion rate per city 
WITH CCR AS
(
  SELECT 
    distinct b.city as city,
    SUM(CASE
        WHEN a.is_make_order = true THEN 1 END) as true_order,
    COUNT(DISTINCT a.masked_user_id) as users
  FROM 
    `bitlabs-dab.I_CID_02.activity` as a
  INNER JOIN 
    `bitlabs-dab.I_CID_02.user` as b
  ON 
    a.masked_user_id = b.masked_user_id
  GROUP BY 1
)
 
  SELECT
    *,
    concat(round(true_order/users*100,2),"%") as CR_User_city
  FROM
    CCR 
  ORDER BY 2 DESC;
------------------------------------------------------ NOMOR 3 ----------------------------------------------------------------

#glosary: INN = in number, CR = conversion rate, v = view
-- these calculation idea corresponding to this web guidance :https://www.hotjar.com/blog/funnel-analysis/ 
-- all calculation funnel start from session_start_global_count colomn since it tell us the visitor of website


#Funnel calculation
WITH Visit_rupa as
(
    SELECT 
        count(session_start_global_count) as visit
    FROM
        `bitlabs-dab.I_CID_02.activity` 
    WHERE
        session_start_global_count >0
),
 VM AS 
(
    SELECT 
        count(view_microsite_count) as total_V_microsite
    FROM
        `bitlabs-dab.I_CID_02.activity` 
    WHERE
        view_microsite_count >0 and session_start_global_count >0
),
TS AS
(
    SELECT 
        count(session_start_global_count) as total_session
    FROM
        `bitlabs-dab.I_CID_02.activity` 
    WHERE
        session_start_global_count >0
),
cal12 AS
(
    SELECT
        CAST(ROUND(total_v_microsite/total_session*100,2)*total_session/100 as INT) AS CR_V_microsite_INN,
        concat(ROUND(total_v_microsite/total_session*100,2),"%") as in_percentage1
    FROM
        VM,TS
),
pdp AS
( 
    SELECT 
        count(view_pdp_count) as total_user_pdp
    FROM
        `bitlabs-dab.I_CID_02.activity` 
    WHERE
          view_pdp_count >0  AND view_microsite_count >0 AND session_start_global_count >0
),
cal23 AS
(
    SELECT
        cast(round(total_user_pdp/CR_V_microsite_INN*100,2)*CR_V_microsite_INN/100 as int) AS CR_pdp_INN,
         concat(round(total_user_pdp/CR_V_microsite_INN*100,2),"%")  AS in_percentage2
    FROM 
        cal12,pdp
),
IC AS
(
     SELECT 
        count(input_kode_promo_count) as total_input_kode
    FROM
        `bitlabs-dab.I_CID_02.activity` 
    WHERE
          input_kode_promo_count >0 AND view_pdp_count >0  AND view_microsite_count >0 AND session_start_global_count >0
),
cal34 AS
(
    SELECT 
        cast(round(total_input_kode/CR_pdp_INN*100,2)*CR_pdp_INN/100 as int) AS CR_input_kode_INN,
        concat(round(total_input_kode/CR_pdp_INN*100,2),'%') AS in_percentage3
     FROM
        IC,cal23
),

MP AS
(   
    SELECT 
        count(pilih_metode_pembayaran_count) as total_Pilih_bayar
    FROM
        `bitlabs-dab.I_CID_02.activity` 
    WHERE
         pilih_metode_pembayaran_count >0  AND input_kode_promo_count >0 AND view_pdp_count >0  AND view_microsite_count >0 AND session_start_global_count >0
),
cal45 AS
(
    SELECT 
        cast(round(MP.total_Pilih_bayar/CR_input_kode_INN*100,2)*CR_input_kode_INN/100 as int) AS CR_Pilih_bayar_INN,
        concat(round(MP.total_Pilih_bayar/CR_input_kode_INN*100,2),"%") AS in_percentage4
     FROM
        MP,cal34
),

P AS
(
    SELECT 
        count(is_make_order) as total_yes_order
    FROM
        `bitlabs-dab.I_CID_02.activity` 
    WHERE
         is_make_order=true AND pilih_metode_pembayaran_count >0 AND  wishlist_count >0 AND input_kode_promo_count >0 AND view_pdp_count >0  AND view_microsite_count >0 AND session_start_global_count >0
),
cal56 AS
(
    SELECT 
        cast(round(total_yes_order/CR_Pilih_bayar_INN*100,2)*CR_Pilih_bayar_INN/100 as int) AS CR_yes_order_INN,
        concat(round(total_yes_order/CR_Pilih_bayar_INN*100,2),"%") AS in_percentage5
     FROM
        p,cal45
)


SELECT
Visit_rupa.visit,
  cal12.CR_v_microsite_INN,
  in_percentage1,
  cal23.CR_pdp_INN,
  in_percentage2,
  cal34.CR_input_kode_INN,
  in_percentage3,
  cal45.CR_Pilih_bayar_INN,
  in_percentage4,
  cal56.CR_yes_order_INN,
  in_percentage5,

FROM 
cal12
,cal23,cal34,cal45,cal56,visit_rupa;



   