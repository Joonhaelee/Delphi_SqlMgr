#!VERSION=2.0.0.0

-- Basic Query for available titles
-- Retrieve all of titles which is available on screen regardless stock or not
<sql name=EN.SelectList.Available.Title result=NDBBeans.TNServiceTitle>
SELECT *
  FROM (
SELECT   
       -- movie
       m.movie_id, m.movie_name, m.director, m.actor, m.genre,
       m.running_time, m.nation, m.release_time, m.play_time, m.dub_language,
       m.subtitling, m.audio_format, m.content_class, m.box_office, m.bullet_films,
       m.issuing_company, m.copyright, m.synopsis, m.movie_desc, m.movie_img, m.movie_img_url, 
       m.movie_thumb_url, m.movie_name_pinyin, m.movie_name_fpinyin, 
       --title,
       t.title_id, t.shop_price, t.market_price, t.daily_fee, t.deposit,
       t.is_delete, t.screen_def, t.screen_dim, t.contents_type,
       --title_flags,
       f.coming_soon_begin, f.coming_soon_end, f.hot_begin, f.hot_end,
       f.new_release_begin,f.new_release_end, f.available_begin, f.available_end,
       f.best_begin, f.best_end,
       --inventory,
       i.disc_service_type, i.disc_status_code, i.disc_count
  FROM movie_en_us M,
       title T,
       title_flags F,
       (SELECT II.title_id, II.disc_service_type, II.disc_status_code, Count(*) disc_count
          FROM inventory II, 
               slot SS
         WHERE II.slot_id = SS.slot_id
           AND SS.slot_disuse = 0
           AND II.title_id > 0
           AND II.owner_id = :owner_id
           AND II.kiosk_id = :kiosk_id
           AND II.disc_service_type = :disc_service_type
           AND II.disc_status_code = 2
      GROUP BY II.title_id, II.disc_service_type, II.disc_status_code) I
 WHERE M.movie_id = T.movie_id
   AND T.title_id = F.title_id
   AND T.is_delete <> 1
   AND (F.available_begin = 0 or F.available_begin <= strftime('%s', 'now'))
   AND (F.available_end = 0 or F.available_end >= strftime('%s', 'now'))
   AND T.title_id = I.title_id
<if IncludeOutOfStock = 'Y'>
UNION ALL
SELECT   
       -- movie
       m.movie_id, m.movie_name, m.director, m.actor, m.genre,
       m.running_time, m.nation, m.release_time, m.play_time, m.dub_language,
       m.subtitling, m.audio_format, m.content_class, m.box_office, m.bullet_films,
       m.issuing_company, m.copyright, m.synopsis, m.movie_desc, m.movie_img, m.movie_img_url, 
       m.movie_thumb_url, m.movie_name_pinyin, m.movie_name_fpinyin,
       --title,
       t.title_id, t.shop_price, t.market_price, t.daily_fee, t.deposit,
       t.is_delete, t.screen_def, t.screen_dim, t.contents_type,
       --title_flags,
       f.coming_soon_begin, f.coming_soon_end, f.hot_begin, f.hot_end,
       f.new_release_begin,f.new_release_end, f.available_begin, f.available_end,
       f.best_begin, f.best_end,
       --inventory,
       i.disc_service_type, i.disc_status_code, i.disc_count
  FROM movie_en_us M,
       title T,
       title_flags F,
       (SELECT II.title_id, II.disc_service_type, 
               -- force status to "rented"
               20 disc_status_code, 
               0 disc_count
          FROM inventory II, 
               slot SS
         WHERE II.slot_id = SS.slot_id
           AND SS.slot_disuse = 0
           AND II.title_id > 0
           AND II.owner_id = :owner_id
           AND II.kiosk_id = :kiosk_id
           -- from "rented" to "sold" OR online reserved
           AND ((II.disc_status_code > 19 AND II.disc_status_code < 61) OR
                 II.disc_status_code = 1)
           -- modified in 3 months
           AND II.update_time >= strftime('%s', datetime('now', '-3 months'))
           -- for renal or sale?
           AND II.disc_service_type = :disc_service_type
      GROUP BY II.title_id, II.disc_service_type, II.disc_status_code) I
 WHERE M.movie_id = T.movie_id
   AND T.title_id = I.title_id
   AND T.title_id = F.title_id
   AND T.is_delete <> 1
</if>  
<if IncludeComingSoon = 'Y'>
UNION ALL
SELECT *
  FROM (SELECT   
               -- movie
               m.movie_id, m.movie_name, m.director, m.actor, m.genre,
               m.running_time, m.nation, m.release_time, m.play_time, m.dub_language,
               m.subtitling, m.audio_format, m.content_class, m.box_office, m.bullet_films,
               m.issuing_company, m.copyright, m.synopsis, m.movie_desc, m.movie_img, m.movie_img_url, 
               m.movie_thumb_url, m.movie_name_pinyin, m.movie_name_fpinyin,
               --title,
               t.title_id, t.shop_price, t.market_price, t.daily_fee, t.deposit,
               t.is_delete, t.screen_def, t.screen_dim, t.contents_type,
               --title_flags,
               f.coming_soon_begin, f.coming_soon_end, f.hot_begin, f.hot_end,
               f.new_release_begin,f.new_release_end, f.available_begin, f.available_end,
               f.best_begin, f.best_end,
               --inventory,
               &disc_service_type& disc_service_type, 0 disc_status_code, 0 disc_count
          FROM movie_en_us M,
               title T,
               title_flags F
         WHERE M.movie_id = T.movie_id
           AND T.title_id = F.title_id
           AND F.coming_soon_begin <= strftime('%s', 'now')
           AND F.coming_soon_end >= strftime('%s', 'now')
           AND T.is_delete <> 1
        ORDER BY F.coming_soon_begin, F.available_begin, M.movie_name
        -- max 50 titles
        LIMIT 0, 50)
</if> 
)
<if SearchValue <> ''>
WHERE (Lower(movie_name) like Lower('%&SearchValue&%') OR
       Lower(director) like Lower('%&SearchValue&%') OR
       Lower(actor) like Lower('%&SearchValue&%'))
</if>
</sql>

<sql name=CH.SelectList.Available.Title result=NDBBeans.TNServiceTitle>
SELECT *
  FROM (
SELECT   
       -- movie
       m.movie_id, m.movie_name, m.director, m.actor, m.genre,
       m.running_time, m.nation, m.release_time, m.play_time, m.dub_language,
       m.subtitling, m.audio_format, m.content_class, m.box_office, m.bullet_films,
       m.issuing_company, m.copyright, m.synopsis, m.movie_desc, m.movie_img, m.movie_img_url, 
       m.movie_thumb_url, m.movie_name_pinyin, m.movie_name_fpinyin, 
       --title,
       t.title_id, t.shop_price, t.market_price, t.daily_fee, t.deposit,
       t.is_delete, t.screen_def, t.screen_dim, t.contents_type,
       --title_flags,
       f.coming_soon_begin, f.coming_soon_end, f.hot_begin, f.hot_end,
       f.new_release_begin,f.new_release_end, f.available_begin, f.available_end,
       f.best_begin, f.best_end,
       --inventory,
       i.disc_service_type, i.disc_status_code, i.disc_count
  FROM movie M,
       title T,
       title_flags F,
       (SELECT II.title_id, II.disc_service_type, II.disc_status_code, Count(*) disc_count
          FROM inventory II, 
               slot SS
         WHERE II.slot_id = SS.slot_id
           AND SS.slot_disuse = 0
           AND II.title_id > 0
           AND II.owner_id = :owner_id
           AND II.kiosk_id = :kiosk_id
           AND II.disc_service_type = :disc_service_type
           AND II.disc_status_code = 2
      GROUP BY II.title_id, II.disc_service_type, II.disc_status_code) I
 WHERE M.movie_id = T.movie_id
   AND T.title_id = F.title_id
   AND T.is_delete <> 1
   AND (F.available_begin = 0 or F.available_begin <= strftime('%s', 'now'))
   AND (F.available_end = 0 or F.available_end >= strftime('%s', 'now'))
   AND T.title_id = I.title_id
<if IncludeOutOfStock = 'Y'>
UNION ALL
SELECT   
       -- movie
       m.movie_id, m.movie_name, m.director, m.actor, m.genre,
       m.running_time, m.nation, m.release_time, m.play_time, m.dub_language,
       m.subtitling, m.audio_format, m.content_class, m.box_office, m.bullet_films,
       m.issuing_company, m.copyright, m.synopsis, m.movie_desc, m.movie_img, m.movie_img_url, 
       m.movie_thumb_url, m.movie_name_pinyin, m.movie_name_fpinyin,
       --title,
       t.title_id, t.shop_price, t.market_price, t.daily_fee, t.deposit,
       t.is_delete, t.screen_def, t.screen_dim, t.contents_type,
       --title_flags,
       f.coming_soon_begin, f.coming_soon_end, f.hot_begin, f.hot_end,
       f.new_release_begin,f.new_release_end, f.available_begin, f.available_end,
       f.best_begin, f.best_end,
       --inventory,
       i.disc_service_type, i.disc_status_code, i.disc_count
  FROM movie M,
       title T,
       title_flags F,
       (SELECT II.title_id, II.disc_service_type, 
               -- force status to "rented"
               20 disc_status_code, 
               0 disc_count
          FROM inventory II, 
               slot SS
         WHERE II.slot_id = SS.slot_id
           AND SS.slot_disuse = 0
           AND II.title_id > 0
           AND II.owner_id = :owner_id
           AND II.kiosk_id = :kiosk_id
           -- from "rented" to "sold" OR online reserved
           AND ((II.disc_status_code > 19 AND II.disc_status_code < 61) OR
                 II.disc_status_code = 1)
           -- modified in 3 months
           AND II.update_time >= strftime('%s', datetime('now', '-3 months'))
           -- for renal or sale?
           AND II.disc_service_type = :disc_service_type
      GROUP BY II.title_id, II.disc_service_type, II.disc_status_code) I
 WHERE M.movie_id = T.movie_id
   AND T.title_id = I.title_id
   AND T.title_id = F.title_id
   AND T.is_delete <> 1
</if>  
<if IncludeComingSoon = 'Y'>
UNION ALL
SELECT *
  FROM (SELECT   
               -- movie
               m.movie_id, m.movie_name, m.director, m.actor, m.genre,
               m.running_time, m.nation, m.release_time, m.play_time, m.dub_language,
               m.subtitling, m.audio_format, m.content_class, m.box_office, m.bullet_films,
               m.issuing_company, m.copyright, m.synopsis, m.movie_desc, m.movie_img, m.movie_img_url, 
               m.movie_thumb_url, m.movie_name_pinyin, m.movie_name_fpinyin,
               --title,
               t.title_id, t.shop_price, t.market_price, t.daily_fee, t.deposit,
               t.is_delete, t.screen_def, t.screen_dim, t.contents_type,
               --title_flags,
               f.coming_soon_begin, f.coming_soon_end, f.hot_begin, f.hot_end,
               f.new_release_begin,f.new_release_end, f.available_begin, f.available_end,
               f.best_begin, f.best_end,
               --inventory,
               &disc_service_type& disc_service_type, 0 disc_status_code, 0 disc_count
          FROM movie M,
               title T,
               title_flags F
         WHERE M.movie_id = T.movie_id
           AND T.title_id = F.title_id
           AND F.coming_soon_begin <= strftime('%s', 'now')
           AND F.coming_soon_end >= strftime('%s', 'now')
           AND T.is_delete <> 1
        ORDER BY F.coming_soon_begin, F.available_begin, M.movie_name
        -- max 50 titles
        LIMIT 0, 50)
</if> 
)
<if SearchValue <> ''>
WHERE (Lower(movie_name_pinyin) like Lower('&SearchValue&%') OR
       Lower(movie_name_fpinyin) like Lower('&SearchValue&%'))
</if>
</sql>

<sql name=SelectList.Cart result=uHttpBeans.TNDisc>
SELECT title_id, disk1_rfid, slot_id, update_time
  FROM cart
</sql>

<sql name=Clear.Cart result=int>
DELETE FROM cart
</sql>

<sql name=Insert.Cart result=int>
INSERT INTO cart(title_id, disk1_rfid, slot_id, update_time) 
values (:title_id, :disk1_rfid, :slot_id, :update_time)
</sql>

<sql name=Update.Cart result=int>
UPDATE cart set
(disk1_rfid = :disk1_rfid, slot_id = :slot_id, update_time = :update_time
WHERE title_id = :title_id
</sql>

<sql name=Delete.Cart result=int>
DELETE FROM cart WHERE title_id = :title_id
</sql>

