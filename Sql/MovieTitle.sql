#!VERSION=2.0.0.0

<sql name=CH.Count.Search.Title result=int>
SELECT Count(*) totalcnt
  FROM movie M,
       title T,
       title_flags F
 WHERE M.movie_id = T.movie_id
   AND T.title_id = F.title_id
   AND T.is_delete <> 1
   AND (Lower(m.movie_name_pinyin) like Lower('&search&%') OR
        Lower(m.movie_name_fpinyin) like Lower('&search&%'))
</sql>

<sql name=EN.Count.Search.Title result=int>
SELECT Count(*) totalcnt
  FROM movie_en_us M,
       title T,
       title_flags F
 WHERE M.movie_id = T.movie_id
   AND T.title_id = F.title_id
   AND T.is_delete <> 1
   AND (Lower(m.movie_name) like Lower('%&search&%') OR
        Lower(m.director) like Lower('%&search&%') OR
        Lower(m.actor) like Lower('%&search&%'))
</sql>

<sql name=CH.SelectList.Search.Title result=NDBBeans.TNServiceTitle>
SELECT   
       -- movie
       m.movie_id, m.movie_name, m.director, m.actor, m.genre,
       m.running_time, m.nation, m.release_time, m.play_time, m.dub_language,
       m.subtitling, m.audio_format, m.content_class, m.box_office, m.bullet_films,
       m.issuing_company, m.copyright, m.synopsis, m.movie_desc, m.movie_img, 
       m.movie_thumb, 
       --title,
       t.title_id, t.shop_price, t.market_price, t.daily_fee, t.deposit,
       t.is_delete, t.screen_def, t.screen_dim, t.contents_type,
       --title_flags,
       f.coming_soon_begin, f.coming_soon_end, f.hot_begin, f.hot_end,
       f.new_release_begin,f.new_release_end, f.available_begin, f.available_end,
       f.best_begin, f.best_end
  FROM movie M,
       title T,
       title_flags F
 WHERE M.movie_id = T.movie_id
   AND T.title_id = F.title_id
   AND T.is_delete <> 1
   AND (Lower(m.movie_name_pinyin) like Lower('&search&%') OR
        Lower(m.movie_name_fpinyin) like Lower('&search&%'))
ORDER BY M.movie_name, t.title_id desc   
LIMIT :fromIndex, :wantedCount
</sql>

<sql name=EN.SelectList.Search.Title result=NDBBeans.TNServiceTitle>
SELECT   
       -- movie
       m.movie_id, m.movie_name, m.director, m.actor, m.genre,
       m.running_time, m.nation, m.release_time, m.play_time, m.dub_language,
       m.subtitling, m.audio_format, m.content_class, m.box_office, m.bullet_films,
       m.issuing_company, m.copyright, m.synopsis, m.movie_desc, m.movie_img, 
       m.movie_thumb, 
       --title,
       t.title_id, t.shop_price, t.market_price, t.daily_fee, t.deposit,
       t.is_delete, t.screen_def, t.screen_dim, t.contents_type,
       --title_flags,
       f.coming_soon_begin, f.coming_soon_end, f.hot_begin, f.hot_end,
       f.new_release_begin,f.new_release_end, f.available_begin, f.available_end,
       f.best_begin, f.best_end
  FROM movie_en_us M,
       title T,
       title_flags F
 WHERE M.movie_id = T.movie_id
   AND T.title_id = F.title_id
   AND T.is_delete <> 1
   AND (Lower(m.movie_name) like Lower('%&search&%') OR
        Lower(m.director) like Lower('%&search&%') OR
        Lower(m.actor) like Lower('%&search&%'))
ORDER BY M.movie_name, t.title_id desc   
LIMIT :fromIndex, :wantedCount
</sql>

<sql name=CH.Get.MovieTitle.By.TitleID result=NDBBeans.TNServiceTitle>
SELECT        -- movie
       m.movie_id, m.movie_name, m.director, m.actor, m.genre,
       m.running_time, m.nation, m.release_time, m.play_time, m.dub_language,
       m.subtitling, m.audio_format, m.content_class, m.box_office, m.bullet_films,
       m.issuing_company, m.copyright, m.synopsis, m.movie_desc, m.movie_img, 
       m.movie_thumb, 
       --title,
       t.title_id, t.shop_price, t.market_price, t.daily_fee, t.deposit,
       t.is_delete, t.screen_def, t.screen_dim, t.contents_type,
       --title_flags,
       f.coming_soon_begin, f.coming_soon_end, f.hot_begin, f.hot_end,
       f.new_release_begin,f.new_release_end, f.available_begin, f.available_end,
       f.best_begin, f.best_end
  FROM movie M,
       title T,
       title_flags F
 WHERE M.movie_id = T.movie_id
   AND T.title_id = F.title_id
   AND T.is_delete <> 1
   <if title_id>
   AND t.title_id = :title_id
   </if>
   <if TitleID>
   AND t.title_id = :TitleID
   </if>
</sql>

<sql name=EN.Get.MovieTitle.By.TitleID result=NDBBeans.TNServiceTitle>
SELECT        -- movie
       m.movie_id, m.movie_name, m.director, m.actor, m.genre,
       m.running_time, m.nation, m.release_time, m.play_time, m.dub_language,
       m.subtitling, m.audio_format, m.content_class, m.box_office, m.bullet_films,
       m.issuing_company, m.copyright, m.synopsis, m.movie_desc, m.movie_img, 
       m.movie_thumb, 
       --title,
       t.title_id, t.shop_price, t.market_price, t.daily_fee, t.deposit,
       t.is_delete, t.screen_def, t.screen_dim, t.contents_type,
       --title_flags,
       f.coming_soon_begin, f.coming_soon_end, f.hot_begin, f.hot_end,
       f.new_release_begin,f.new_release_end, f.available_begin, f.available_end,
       f.best_begin, f.best_end
  FROM movie_en_us M,
       title T,
       title_flags F
 WHERE M.movie_id = T.movie_id
   AND T.title_id = F.title_id
   AND T.is_delete <> 1
   <if title_id>
   AND t.title_id = :title_id
   </if>
   <if TitleID>
   AND t.title_id = :TitleID
   </if>
</sql>

<sql name=CH.Get.Movie.By.TitleID result=NDBBeans.TNMovie>
SELECT m.*
  FROM movie m,
       title t
 WHERE m.movie_id = t.movie_id
  <if TitleID>
   AND t.title_id = :TitleID
   </if>
   <if title_id>
   AND t.title_id = :title_id
   </if>
</sql>

<sql name=EN.Get.Movie.By.TitleID result=NDBBeans.TNMovie>
SELECT m.*
  FROM movie_en_us m,
       title t
 WHERE m.movie_id = t.movie_id
  <if TitleID>
   AND t.title_id = :TitleID
   </if>
   <if title_id>
   AND t.title_id = :title_id
   </if>
</sql>
