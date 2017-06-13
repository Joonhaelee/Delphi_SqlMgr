#!VERSION=2.0.0.0

-- Basic Query for available titles
<sql name=CH.SelectList.All.InStock.InvTitles result=NDBBeans.TNInvTitle>
select I.*, mt.movie_id, mt.movie_name, mt.movie_img, mt.movie_thumb, mt.daily_fee, mt.is_delete,
       mt.screen_def, mt.screen_dim, mt.contents_type,
       mt.director, mt.actor, mt.genre, mt.movie_name_pinyin, mt.movie_name_fpinyin
  from inventory I   
       left outer join (select m.movie_id, m.movie_name,m.movie_img,m.movie_thumb, m.director, m.actor, m.genre,
                               m.movie_name_pinyin, m.movie_name_fpinyin,
                               t.title_id, t.daily_fee, t.is_delete, t.screen_def, t.screen_dim, t.contents_type                              
                          from movie M, title T     
                         where M.movie_id = T.movie_id) MT                         
       on I.title_id = MT.title_id
where I.owner_id = :owner_id 
  AND I.kiosk_id = :kiosk_id
  AND I.disc_status_code < 20         
</sql>

<sql name=EN.SelectList.All.InStock.InvTitles result=NDBBeans.TNInvTitle>
select I.*, mt.movie_id, mt.movie_name, mt.movie_img, mt.movie_thumb, mt.daily_fee, mt.is_delete,
       mt.screen_def, mt.screen_dim, mt.contents_type,
       mt.director, mt.actor, mt.genre, mt.movie_name_pinyin, mt.movie_name_fpinyin
  from inventory I   
       left outer join (select m.movie_id, m.movie_name,m.movie_img,m.movie_thumb, m.director, m.actor, m.genre,
                               m.movie_name_pinyin, m.movie_name_fpinyin,
                               t.title_id, t.daily_fee, t.is_delete, t.screen_def, t.screen_dim, t.contents_type
                          from movie_en_us M, title T     
                         where M.movie_id = T.movie_id) MT                         
       on I.title_id = MT.title_id
where I.owner_id = :owner_id 
  AND I.kiosk_id = :kiosk_id
  AND I.disc_status_code < 20         
</sql>

<sql name=CH.SelectList.InStock.InvTitles.By.Slot result=NDBBeans.TNInvTitle>
select I.*, 
       mt.movie_id, mt.movie_name, mt.movie_img, mt.movie_thumb, mt.daily_fee, mt.is_delete,
       mt.screen_def, mt.screen_dim, mt.contents_type,
       mt.director, mt.actor, mt.genre, mt.movie_name_pinyin, mt.movie_name_fpinyin
  from inventory I   
       left outer join (select m.movie_id, m.movie_name,m.movie_img,m.movie_thumb, m.director, m.actor, m.genre,
                               m.movie_name_pinyin, m.movie_name_fpinyin,
                               t.title_id, t.daily_fee, t.is_delete, t.screen_def, t.screen_dim, t.contents_type
                          from movie M, title T     
                         where M.movie_id = T.movie_id) MT                         
       on I.title_id = MT.title_id
where I.owner_id = :owner_id 
  AND I.kiosk_id = :kiosk_id
  AND I.disc_status_code < 20
  AND I.slot_id = :slot_id
</sql>

<sql name=EN.SelectList.InStock.InvTitles.By.Slot result=NDBBeans.TNInvTitle>
select I.*, 
       mt.movie_id, mt.movie_name, mt.movie_img, mt.movie_thumb, mt.daily_fee, mt.is_delete,
       mt.screen_def, mt.screen_dim, mt.contents_type,
       mt.director, mt.actor, mt.genre, mt.movie_name_pinyin, mt.movie_name_fpinyin
  from inventory I   
       left outer join (select m.movie_id, m.movie_name,m.movie_img,m.movie_thumb, m.director, m.actor, m.genre,
                               m.movie_name_pinyin, m.movie_name_fpinyin,
                               t.title_id, t.daily_fee, t.is_delete, t.screen_def, t.screen_dim, t.contents_type
                          from movie_en_us M, title T     
                         where M.movie_id = T.movie_id) MT                         
       on I.title_id = MT.title_id
where I.owner_id = :owner_id 
  AND I.kiosk_id = :kiosk_id
  AND I.disc_status_code < 20
  AND I.slot_id = :slot_id
</sql>

<sql name=CH.Select.InvTitle.By.RFID result=NDBBeans.TNInvTitle>
select I.*, 
       mt.movie_id, mt.movie_name, mt.movie_img, mt.movie_thumb, mt.daily_fee, mt.is_delete,
       mt.screen_def, mt.screen_dim, mt.contents_type,
       mt.director, mt.actor, mt.genre, mt.movie_name_pinyin, mt.movie_name_fpinyin
  from inventory I   
       left outer join (select m.movie_id, m.movie_name,m.movie_img,m.movie_thumb, m.director, m.actor, m.genre,
                               m.movie_name_pinyin, m.movie_name_fpinyin,
                               t.title_id, t.daily_fee, t.is_delete, t.screen_def, t.screen_dim, t.contents_type
                          from movie M, title T     
                         where M.movie_id = T.movie_id) MT                         
       on I.title_id = MT.title_id
where I.disk1_rfid = :disk1_rfid
</sql>

<sql name=EN.Select.InvTitle.By.RFID result=NDBBeans.TNInvTitle>
select I.*, 
       mt.movie_id, mt.movie_name, mt.movie_img, mt.movie_thumb, mt.daily_fee, mt.is_delete,
       mt.screen_def, mt.screen_dim, mt.contents_type,
       mt.director, mt.actor, mt.genre, mt.movie_name_pinyin, mt.movie_name_fpinyin
  from inventory I   
       left outer join (select m.movie_id, m.movie_name,m.movie_img,m.movie_thumb, m.director, m.actor, m.genre,
                               m.movie_name_pinyin, m.movie_name_fpinyin,
                               t.title_id, t.daily_fee, t.is_delete, t.screen_def, t.screen_dim, t.contents_type
                          from movie_en_us M, title T     
                         where M.movie_id = T.movie_id) MT                         
       on I.title_id = MT.title_id
where I.disk1_rfid = :disk1_rfid
</sql>


<sql name=Get.Available.Disc.By.TitleID result=NDBBeans.TNInventory>
SELECT I.*
  FROM INVENTORY I,
       SLOT S
WHERE I.owner_id = :owner_id
  AND I.kiosk_id = :kiosk_id
  AND I.title_id = :title_id
  AND I.disc_service_type = 0  
  AND I.disc_status_code = 2
  AND I.slot_id = S.slot_id
ORDER BY S.distance
LIMIT 0, 1
</sql>

<sql name=Get.Available.Slot.Count result=int>
SELECT Count(*) Cnt
  FROM (SELECT * 
          FROM SLOT
         WHERE kiosk_model = 'MANGO-C500'
           AND slot_disuse = 0
       ) S LEFT OUTER JOIN 
       (SELECT slot_id 
          FROM INVENTORY
         WHERE owner_id = :owner_id
           AND kiosk_id = :kiosk_id
           AND disc_status_code < 20) I
         ON S.slot_id = I.slot_id
WHERE I.slot_id is null
</sql>

<sql name=Get.Available.Slot result=int>
SELECT S.Slot_id Slot_Id
  FROM (SELECT * 
          FROM SLOT
         WHERE kiosk_model = 'MANGO-C500'
           AND slot_disuse = 0
       ) S LEFT OUTER JOIN 
       (SELECT slot_id 
          FROM INVENTORY
         WHERE owner_id = :owner_id
           AND kiosk_id = :kiosk_id
           AND disc_status_code < 20) I
         ON S.slot_id = I.slot_id         
WHERE I.slot_id is null
ORDER BY S.distance
LIMIT 0, 1
</sql>

<sql name=Get.Available.Far.Slot result=int>
SELECT S.Slot_id Slot_Id
  FROM (SELECT * 
          FROM SLOT
         WHERE kiosk_model = 'MANGO-C500'
           AND slot_disuse = 0
       ) S LEFT OUTER JOIN 
       (SELECT slot_id 
          FROM INVENTORY
         WHERE owner_id = :owner_id
           AND kiosk_id = :kiosk_id
           AND disc_status_code < 20) I
         ON S.slot_id = I.slot_id         
WHERE I.slot_id is null
ORDER BY S.distance desc
LIMIT 0, 1
</sql>


<sql name=Select.Inventory.By.Title result=NDBBeans.TNInventory>
SELECT title_id, owner_id, kiosk_id, slot_id, 
       disk1_rfid, disk2_rfid, disc_status_code, disc_service_type,
       create_time, update_time,
       failover_kiosk_id, failover_return_time
  FROM INVENTORY A
 WHERE A.owner_id = :owner_id
   AND A.kiosk_id = :kiosk_id
   AND A.title_id = :title_id
</sql>

<sql name=Get.Count.By.RFID result=int>
SELECT Count(*) cnt
  FROM INVENTORY A
 WHERE 1 =1 
   <if RFID>
   AND A.disk1_rfid = :RFID
   </if>
   <if disk1_rfid>
   AND A.disk1_rfid = :disk1_rfid
   </if>
</sql>

<sql name=Select.Inventory.By.RFID result=NDBBeans.TNInventory>
SELECT title_id, owner_id, kiosk_id, slot_id, 
       disk1_rfid, disk2_rfid, disc_status_code, disc_service_type,
       create_time, update_time,
       failover_kiosk_id, failover_return_time
  FROM INVENTORY A
 WHERE 1 =1 
   <if RFID>
   AND A.disk1_rfid = :RFID
   </if>
   <if disk1_rfid>
   AND A.disk1_rfid = :disk1_rfid
   </if>
</sql>

<sql name=SelectList.Inventory result=NDBBeans.TNInventory>
SELECT title_id, owner_id, kiosk_id, slot_id, 
       disk1_rfid, disk2_rfid, disc_status_code, disc_service_type,
       create_time, update_time,
       failover_kiosk_id, failover_return_time
  FROM INVENTORY A
 WHERE 1 = 1
   <if kiosk_id<>0>
   AND A.kiosk_id = :kiosk_id
   </if>
   <if slot_id<>0>
   AND A.slot_id = :slot_id
   </if>
   <if disk1_rfid<>''>
   AND A.disk1_rfid = :disk1_rfid
   </if>
   -- to make it easy, use netgative value to get all of disc_status_code
   <if disc_status_code>=0>
   AND A.disc_status_code = :disc_status_code
   </if>
   -- to make it easy, use netgative value to get all of disc_service_type
   <if disc_service_type>=0>
   AND A.disc_service_type = :disc_service_type
   </if>   
</sql>
  
<sql name=Insert.Inventory result=int>
INSERT INTO INVENTORY (
  owner_id, kiosk_id, title_id, slot_id, 
  disk1_rfid, disk2_rfid, disc_status_code, disc_service_type, 
  create_time, update_time
  <if failover_kiosk_id>
  , failover_kiosk_id, failover_return_time
  </if>
  , version_num
  )
VALUES(
  :owner_id, :kiosk_id, :title_id, :slot_id, 
  :disk1_rfid, :disk2_rfid, :disc_status_code, :disc_service_type, 
  :create_time, :update_time
  <if failover_kiosk_id>
  , :failover_kiosk_id, :failover_return_time
  </if>
  , :version_num
  )
</sql>

<sql name=Update.Inventory.By.RFID result=int>
UPDATE INVENTORY SET
  owner_id = :owner_id,
  kiosk_id = :kiosk_id,
  title_id = :title_id,
  slot_id = :slot_id,
  disk1_rfid = :disk1_rfid,
  disk2_rfid = :disk2_rfid,
  disc_status_code = :disc_status_code,
  disc_service_type = :disc_service_type,
  update_time = :update_time,
  version_num = :version_num
  <if failover_kiosk_id>
, failover_kiosk_id = :failover_kiosk_id,
  failover_return_time = :failover_return_time
  </if>
WHERE 1 = 1
   <if RFID>
   AND disk1_rfid = :RFID
   </if>
   <if disk1_rfid>
   AND disk1_rfid = :disk1_rfid
   </if>
</sql>
  
<sql name=Update.Inventory.By.Slot result=int>
UPDATE INVENTORY SET
  owner_id = :owner_id,
  kiosk_id = :kiosk_id,
  disk1_rfid = :disk1_rfid,
  disk2_rfid = :disk2_rfid,
  slot_id = :slot_id,
  disc_status_code = :disc_status_code,
  disc_service_type = :disc_service_type,
  update_time = :update_time,
  version_num = :version_num
  <if failover_kiosk_id>
, failover_kiosk_id = :failover_kiosk_id,
  failover_return_time = :failover_return_time
  </if>
WHERE owner_id = :owner_id
  AND kiosk_id = :kiosk_id
  AND slot_id = :slot_id
</sql>

<sql name=Update.Inventory.TitleID.By.RFID result=int>
UPDATE INVENTORY SET
  owner_id = :owner_id,
  kiosk_id = :kiosk_id,
  title_id = :title_id,
  version_num = :version_num,
  update_time = :update_time
WHERE
  disk1_rfid = :disk1_rfid
</sql>

<sql name=Update.Inventory.DiscStatusCode.By.RFID result=int>
UPDATE INVENTORY SET
  owner_id = :owner_id,
  kiosk_id = :kiosk_id,
  disc_status_code = :disc_status_code,
  version_num = :version_num,
  update_time = :update_time
WHERE
  disk1_rfid = :disk1_rfid
</sql>

<sql name=Update.Inventory.DiscStatusCode.Of.InKiosk.By.Slot result=int>
UPDATE INVENTORY SET
  disc_status_code = :disc_status_code,
  update_time = :update_time,
  version_num = :version_num
WHERE owner_id = :owner_id
  AND kiosk_id = :kiosk_id
  AND slot_id = :slot_id
  -- 20 = rented..
  AND disc_status_code < 20
</sql>

  
<sql name=Delete.Inventory.By.RFID result=int>
DELETE INVENTORY 
WHERE disk1_rfid = :disk1_rfid
</sql>
  
<sql name=Delete.Inventory.By.Slot result=int>
DELETE INVENTORY 
WHERE owner_id = :owner_id
  AND kiosk_id = :kiosk_id
  AND slot_id = :slot_id
</sql>
  
<sql name=Clear.Inventory result=int>
DELETE INVENTORY 
WHERE owner_id = :owner_id
  AND kiosk_id = :kiosk_id
</sql>
 
 
<sql name=Get.InventoryCount result=NDBBeans.TNInventoryCount>
SELECT owner_id, kiosk_id,
  SUM(CASE WHEN disc_status_code < 20 THEN 1 ELSE 0 END) disc_total,
  SUM(CASE WHEN disc_status_code = 0 THEN 1 ELSE 0 END) disc_onlinereserved,
  SUM(CASE WHEN disc_status_code < 3  THEN 1 ELSE 0 END) disc_inStock,  
  SUM(CASE WHEN disc_status_code > 2 AND disc_status_code < 20 THEN 1 ELSE 0 END) disc_blocked,
  SUM(CASE WHEN disc_status_code = 20 THEN 1 ELSE 0 END) disc_rented
 FROM inventory
WHERE owner_id = :owner_id
  AND kiosk_id = :kiosk_id
GROUP BY owner_id, kiosk_id
</sql>

<sql name=GetList.InventoryCount.GroupBy.Title result=NDBBeans.TNInventoryCount>
SELECT owner_id, kiosk_id, title_id,
  SUM(CASE WHEN disc_status_code < 20 THEN 1 ELSE 0 END) disc_total,
  SUM(CASE WHEN disc_status_code = 0 THEN 1 ELSE 0 END) disc_onlinereserved,
  SUM(CASE WHEN disc_status_code < 3  THEN 1 ELSE 0 END) disc_inStock,  
  SUM(CASE WHEN disc_status_code > 2 AND disc_status_code < 20 THEN 1 ELSE 0 END) disc_blocked,
  SUM(CASE WHEN disc_status_code = 20 THEN 1 ELSE 0 END) disc_rented
 FROM inventory
WHERE owner_id = :owner_id
  AND kiosk_id = :kiosk_id
GROUP BY owner_id, kiosk_id, title_id
</sql>

<sql name=SelectList.Return.Failover.Disc result=NDBBeans.TNInventory>
SELECT *
  FROM inventory
 WHERE owner_id = :owner_id
   AND failover_kiosk_id = :kiosk_id  
 LIMIT 2
</sql>
