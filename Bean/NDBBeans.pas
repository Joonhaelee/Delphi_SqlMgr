unit NDBBeans;

interface

uses
  System.SysUtils, System.Classes, NBaseClass, NBaseRtti;

type

  [ _NCLASS(true) ]
  TNSession = class(TNData)
  public
    session_id: Int64;
    start_time: TDateTime;
    end_time: TDateTime;
    elapsed_sec: integer;
    end_type: String;
    member_proved_by: String;
    touch_count: integer;
    screen_change_count: integer;
    rental_count: integer;
    return_count: integer;
    regist_fail_count: integer;
    rental_fail_count: integer;
    return_fail_count: integer;
  end;

  [ _NCLASS(true) ]
  TNTrace = class(TNData)
  public
    session_id: Int64;
    event_time: TDateTime;
    event_type: String;
    event_log: String;
    sender_name: String;
    screen_name: String;
    title_id: Integer;
    member_id: Integer;
    mcard_no: String;
  end;

  [ _NCLASS(true) ]
  TNTableDirty = class(TNData)
  public
    TableName: String;
    LastUpdateTime: TDateTime;
  end;

  [ _NCLASS(true) ]
  TNKioskDumpbox = class(TNData)
  public
    owner_id: Integer;
    kiosk_id: Integer;
    box1: Integer;
    box2: Integer;
    box3: Integer;
    update_time: TDateTime;
    box_sum: Integer;
    function GetAvailableBoxNo(ACapacityPerBox: Integer): Integer;
    procedure UpdateBox(ABox: Integer; ADumped: Integer = 1);
  end;

  [ _NCLASS(true) ]
  TNConfig = class(TNData)
  public
    source: String;                  // file name or ....table name...
    dupCount: Integer;
    owner_id: Integer;
    kiosk_id: Integer;
    section: string;
    name: String;                    // config item name.
    value: String;                   // config item value
    remark: String;
    create_time: TDateTime;
    update_time: TDateTime;
  end;

  [ _NCLASS(true) ]
  TNSlot = class(TNData)
  public
    kiosk_model: String;
    slot_id: Integer;
    slot_disuse: Integer;
    distance: Integer;
  end;

  [ _NCLASS(true) ]
  TNKiosk = class(TNData)
  public
    kiosk_id: Integer;
    owner_id: Integer;
    kiosk_name: String;
    indoor: Integer;
    machine_serial: String;
    kiosk_model: String;
    kiosk_image: String;
    kiosk_status: String;
    reg_date: TDateTime;
    close_date: TDateTime;
    state_code: String;
    city_name: String;
    location: String;
    address: String;
    zipcode: String;
    latitude: Double;
    longitude: Double;
    remote_service_ip: String;
    remote_service_port: Integer;
    remote_service_password: String;
    remote_ip: String;
    remote_port: Integer;
    remote_password: String;
    tax_rate: Double;
    remark: String;
    // extracted from slot table
    slot_count: Integer;
  end;

  [ _NCLASS(true) ]
  TNInventory = class(TNData)
  public
    owner_id: Integer;
    kiosk_id: Integer;
    title_id: Integer;
    slot_id: Integer;
//    member_id: Integer;
//    card_number: String;
    disk1_rfid: String;
    disk2_rfid: String;
    disc_status_code: Integer;
    disc_service_type: Integer;
    create_time: TDateTime;
    update_time: TDateTime;
    failover_kiosk_id: Integer;
    failover_return_time: TDateTime;
    version_num: Integer;
  end;

  [ _NCLASS(true) ]
  TNInventoryCount = class(TNData)
  public
    owner_id: Integer;
    kiosk_id: Integer;
    title_id: Integer;
    disc_total: Integer;
    disc_instock: Integer;
    disc_onlinereserved: Integer;
    disc_blocked: Integer;
    disc_rented: Integer;
  end;

  [ _NCLASS(true) ]
  TNAd = class(TNData)
  public
    ad_id: Integer;
    position_id: Integer;
    media_type: Integer;
    ad_name: String;
    ad_link: String;
    ad_img: String;
    ad_url: String;
    ad_code: String;
    start_time: TDateTime;
    end_time: TDateTime;
    link_man: String;
    link_email: String;
    link_phone: String;
    click_count: Integer;
    enabled: Integer;
  end;

  [ _NCLASS(true) ]
  TNMovie = class(TNData)
  protected
    function GetPoster: String;
    function GetThumbnail: String;
  public
    movie_id: Integer;
    movie_name: String;
    director: String;
    actor: String;
    genre: String;
    running_time: String;
    nation: String;
    release_time: TDateTime;
    play_time: TDateTime;
    dub_language: String;
    subtitling: String;
    audio_format: String;
    content_class: String;
    color: String;
    per_number: Integer;
    medium: String;
    bar_code: String;
    isrc_code: String;
    area_code: String;
    import_code: String;
    fn_name: String;
    box_office: String;
    bullet_films: String;
    issuing_company: String;
    copyright: String;
    synopsis: String;
    movie_desc: String;
    movie_img: String;
    movie_img_url: String;
    movie_thumb: String;
    movie_thumb_url: String;
    movie_name_pinyin: String;    // movie name's whole pinyin
    movie_name_fpinyin: String;   // movie name's whole pinyin's first char
    property Poster: String read GetPoster;
    property Thumbnail: String read GetThumbnail;
  end;

  [ _NCLASS(true) ]
  TNInvTitle = class(TNMovie)
  protected
    function GetIsBluray: Boolean;
  public
    // movie :: inherited
    // inventory
    owner_id: Integer;
    kiosk_id: Integer;
    title_id: Integer;
    slot_id: Integer;
    member_id: Integer;
    card_number: String;
    disk1_rfid: String;
    disk2_rfid: String;
    disc_status_code: Integer;
    disc_service_type: Integer;
    create_time: TDateTime;
    update_time: TDateTime;
    version_num: Integer;
    // title
    daily_fee: Double;
    is_delete: Integer;
    contents_type: Integer;
    screen_def: Integer;  // 2k, 4k, 8k
    screen_dim: Integer;  // 2D, 3D
    // runtime
    dup_disc_count: integer;
    property IsBluray: Boolean read GetIsBluray;
  end;

  // Must keep order. used on sort
  TTitleScreenDisplayState = (tsdInStock, tsdComingSoon, tsdOutofStock);

  [ _NCLASS(true) ]
  TNServiceTitle = class(TNMovie)
  public
    owner_id: Integer;
    kiosk_id: Integer;
    // movie fields inherits from TNMovie
    // from title
    title_id: Integer;
    shop_price: Double;
    market_price: Double;
    daily_fee: Double;
    deposit: Double;
    is_delete: Integer;
    contents_type: Integer;
    screen_def: Integer;  // 2k, 4k, 8k
    screen_dim: Integer;  // 2D, 3D

    // from title_flag
    available_begin: TDateTime;
    available_end: TDateTime;
    coming_soon_begin: TDateTime;
    coming_soon_end: TDateTime;
    new_release_begin: TDateTime;
    new_release_end: TDateTime;
    hot_begin: TDateTime;
    hot_end: TDateTime;
    best_begin: TDateTime;
    best_end: TDateTime;
    // from inventory aggregation
    disc_count: Integer;
    disc_status_code: Integer;
    disc_service_type: Integer;
  protected
    function GetScreenDisplayType: TTitleScreenDisplayState;
    // followings are
    function GetIsBest: Boolean;
    function GetIsHot: Boolean;
    function GetIsNew: Boolean;
    function GetIsBluray: Boolean;
  public
    PosterResource: TObject;
    destructor Destroy; override;
    property ScreenDisplayType: TTitleScreenDisplayState read GetScreenDisplayType;
    property isHot: Boolean read GetIsHot;
    property isNew: Boolean read GetIsNew;
    property isBest: Boolean read GetIsBest;
    property IsBluray: Boolean read GetIsBluray;
  end;

  function GetDiscServiceTypeName(AServiceType: Integer): String;
  function GetDiscStatusCodeName(AStatus: Integer): String;
  function GetShortInvStatusOfDisc(AStatus: Integer): String;

const
  // kiosk internal usage only
  DISC_STATUS_InCart = 0;
  // Exist in slot and available for service
  DISC_STATUS_Reserved = 1;
  DISC_STATUS_InStock = 2;
  // Exist in slot but not available for service
  _DISC_STATUS_BLOCKED_MIN = 3;

  DISC_STATUS_BlockedByOp = 3;
  DISC_STATUS_BlockedByLoadFail = 4;
  DISC_STATUS_BlockedByInvalidRfid = 5;
  DISC_STATUS_BlockedByCustomer = 6;
  DISC_STATUS_ScheduledToRemove = 7;
  // Possibly exist in slot
  DISC_STATUS_BlockedByRecovery = 10;
  DISC_STATUS_BlockedByInsertFail = 11;
  DISC_STATUS_BlockedByUnknown = 12;

  _DISC_STATUS_BLOCKED_MAX = 19;
  _DISC_STATUS_IN_KIOSK_MAX = 19;

  // Not exist in slot
  DISC_STATUS_Rented = 20;
  DISC_STATUS_ScheduledToAdd = 30;
  DISC_STATUS_Removed = 40;
  DISC_STATUS_SoldByOverdue = 50;
  DISC_STATUS_Sold = 60;

  DISC_SERVICE_TYPE_RENT = 0;
  DISC_SERVICE_TYPE_SELL = 1;


  RENTAL_STATUS_PreAuth           = 0;
  RENTAL_STATUS_Pended            = 1;
  RENTAL_STATUS_Reserved          = 10;
  RENTAL_STATUS_OnGoing           = 11;
  RENTAL_STATUS_Returned          = 20;

  RENTAL_STATUS_CancellingPended  = 29;
  RENTAL_STATUS_PreAuthCancelled  = 30;
  RENTAL_STATUS_ReserveCancelled  = 31;
  RENTAL_STATUS_NoShow            = 32;
  RENTAL_STATUS_OverdueSold       = 40;
  RENTAL_STATUS_DispenseFailed    = 50;
  RENTAL_STATUS_DiscNotTaken      = 51;
  RENTAL_STATUS_LostOrBroken      = 60;
  RENTAL_STATUS_ClosedByOp        = 90;

implementation

uses System.IOUtils, System.DateUtils, System.Math;

function GetShortInvStatusOfDisc(AStatus: Integer): String;
begin
  if AStatus < 3 then
    Exit('InStock');
  if AStatus < 20 then
    Exit('Blocked');
  if AStatus = 20 then
    Exit('Rented');
  if AStatus = 30 then
    Exit('Add');
  Exit('Unknown');
end;

function GetDiscServiceTypeName(AServiceType: Integer): String;
begin
  if AServiceType = 1 then
    Exit('Sell')
  else
    Exit('Rent');
end;

function GetDiscStatusCodeName(AStatus: Integer): String;
begin
  case AStatus of
    DISC_STATUS_InCart: Exit('In Cart');
    DISC_STATUS_Reserved: Exit('Online Reserved');
    DISC_STATUS_InStock: Exit('In stock');
    DISC_STATUS_BlockedByOp: Exit('Blocked by operator');
    DISC_STATUS_BlockedByLoadFail: Exit('Blocked by extraction fail');
    DISC_STATUS_BlockedByInvalidRfid: Exit('Blocked by invalid rfid');
    DISC_STATUS_BlockedByCustomer: Exit('Blocked by customer');
    DISC_STATUS_ScheduledToRemove: Exit('Scheduled to remove');
    DISC_STATUS_BlockedByRecovery: Exit('Blocked by recovery');
    DISC_STATUS_BlockedByInsertFail: Exit('Blocked by insertion fail');
    DISC_STATUS_BlockedByUnknown: Exit('Blocked by unknown reason');
    DISC_STATUS_Rented: Exit('Rented');
    DISC_STATUS_ScheduledToAdd: Exit('Scheduled to add');
    DISC_STATUS_Removed: Exit('Removed');
    DISC_STATUS_SoldByOverdue: Exit('Sold by overdue');
    DISC_STATUS_Sold: Exit('Sold by purchase');
    else
      Exit('Undefined');
  end;
end;

{ TNInvTitle }

function TNInvTitle.GetIsBluray: Boolean;
begin
  result := screen_def >= 2; // more than 2K
end;


{ TNServiceTitle }

function TNServiceTitle.GetIsBest: Boolean;
begin
  result := InRange(Now, best_begin, best_end);
end;

function TNServiceTitle.GetIsHot: Boolean;
begin
  result := InRange(Now, hot_begin, hot_end);
end;

function TNServiceTitle.GetIsNew: Boolean;
begin
  result := InRange(Now, new_release_begin, new_release_end);
end;

function TNServiceTitle.GetIsBluray: Boolean;
begin
  result := screen_def >= 2;
end;

function TNMovie.GetPoster: String;
begin
  result := TPath.GetFileName(movie_img);
  if result = '' then
    result := TPath.GetFileName(movie_img_url);
end;

function TNMovie.GetThumbnail: String;
begin
  result := TPath.GetFileName(movie_thumb);
  if result = '' then
    result := TPath.GetFileName(movie_thumb_url);
end;

function TNServiceTitle.GetScreenDisplayType: TTitleScreenDisplayState;
begin
  case disc_status_code of
    // in stock;
    DISC_STATUS_InStock: Exit(tsdInStock);
    // coming soon. When we merge common soon titles, there are no disc_status_code. so it is 0
    0: Exit(tsdComingSoon);
    // out of stock
    else
       Exit(tsdOutOfStock);
  end;
end;

destructor TNServiceTitle.Destroy;
begin
  inherited;
end;

function TNKioskDumpbox.GetAvailableBoxNo(ACapacityPerBox: Integer): Integer;
begin
  if box1 < ACapacityPerBox then
    result := 1
  else if box2 < ACapacityPerBox then
    result := 2
  else if box3 < ACapacityPerBox then
    result := 3
  else
    result := 0;
end;

procedure TNKioskDumpbox.UpdateBox(ABox: Integer; ADumped: Integer = 1);
begin
  case ABox of
    1: Inc(box1, ADumped);
    2: Inc(box2, ADumped);
    3: Inc(box3, ADumped);
  end;
end;



end.
