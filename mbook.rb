#******************************************************************************
#
#    ＊ モンスター図鑑
#
#  --------------------------------------------------------------------------
#    バージョン ： 0.0.3
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： http://cacaosoft.webcrow.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#   ： モンスター図鑑の機能を追加します。
#
#  --------------------------------------------------------------------------
#   == 注意事項 ==
#
#   ※ テキストでコメントを設定する場合は、暗号化前に Data フォルダ内に
#      MBComments.rvdata ファイルがあることを確認してください。
#
#
#******************************************************************************


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
module MB
  #--------------------------------------------------------------------------
  # ◇ 解析ステートの番号
  #--------------------------------------------------------------------------
  ID_ANALYZE = 26
  #--------------------------------------------------------------------------
  # ◇ 名前のわからないページを表示するか
  #--------------------------------------------------------------------------
  # 0:一切の情報を非公開 1:名前のみ公開 2:名前がわかるまで非公開
  SECRET_TYPE = 1
  #--------------------------------------------------------------------------
  # ◇ 閲覧可能にする情報
  #--------------------------------------------------------------------------
  ENTRY_LIST = {} # ※ この行は変更しない ※
  # 初期状態
  ENTRY_LIST[:start]    = [:no, :defeat]
  # エンカウントで増やす項目
  ENTRY_LIST[:encount]  = [:graphic]
  # 戦闘後に増やす項目
  ENTRY_LIST[:battle]   = [:exp, :gold]
  # 解析で増やす項目
  ENTRY_LIST[:analyze]  = [:name, :status, :graphic, :exp, :gold, :drop]
  # 全表示項目 (完成度の判定に使用します。)
  ENTRY_LIST[:complete] = [
    :no, :name, :graphic, :comment,
    :status, :exp, :gold, :drop, :state, :element
  ]
  ENTRY_LIST["book"] = [:name, :graphic, :drop, :comment]
  ENTRY_LIST["WINNER"] =
    [:name] + ENTRY_LIST[:start] + ENTRY_LIST[:encount] + ENTRY_LIST[:battle]
  
  #--------------------------------------------------------------------------
  # ◇ 初期ページ
  #--------------------------------------------------------------------------
  START_PAGE = 0
  #--------------------------------------------------------------------------
  # ◇ 表示内容
  #--------------------------------------------------------------------------
  STATUS_ITEMS = [
    # ページ１
    [
      "name_270", "no_276_0_60", "space_2", "line_$FFF", "space_12",
      "status", "space_8",
      "exp_164_N", "gold_172_164", "space_12",
      "element_weak", "element_resist", "state_weak", "state_resist",
      "space_8", "defeat"
    ],
    # ページ２
    ["graphic_0_0_336_240", "drop_0_244_0_0", "state_weak", "state_resist"],
    # ページ３
    ["comment", "hp", "atk"]
  ]
  
  #--------------------------------------------------------------------------
  # ◇ 敗北しても登録する
  #     true  : 戦闘で負けても、倒した敵の加算と図鑑登録を行います。
  #     false : 戦闘に負けた場合は、何も行いません。
  #--------------------------------------------------------------------------
  AUTO_ENTRY_LOSE = false
  #--------------------------------------------------------------------------
  # ◇ 倒した敵のみ自動登録する
  #     true  : 敵を倒すと :encount + :battle
  #     false : 遭遇で :encount、倒すと :battle
  #--------------------------------------------------------------------------
  AUTO_ENTRY_DEFEATED = false
  
  #--------------------------------------------------------------------------
  # ◇ 情報ウィンドウの設定
  #--------------------------------------------------------------------------
  SMALL_INFO = [0, "モンスター図鑑"]
  LARGE_INFO = [1, :defeat, :encount, :complete]
    
  #--------------------------------------------------------------------------
  # ◇ 表示するステート
  #--------------------------------------------------------------------------
  USABLE_STATE = [2, 3, 4, 5, 6, 7, 8]
  #--------------------------------------------------------------------------
  # ◇ 表示する属性
  #--------------------------------------------------------------------------
  USABLE_ELEMENT = [3, 4, 5, 6, 7, 8, 9, 10]
  #------------------------------------------------------------------------
  # ◇ 属性のアイコン
  #------------------------------------------------------------------------
  ICO_ELEMENT = [104, 105, 106, 107, 108, 109, 110, 111]
  
  #------------------------------------------------------------------------
  # ◇ 戦闘時パーティコマンドに解析結果を追加する
  #------------------------------------------------------------------------
  PARTY_COMMAND = false

end # module MB
end # module CAO


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module CAO::MB
  #--------------------------------------------------------------------------
  # ◇ 表示内容の設定
  #--------------------------------------------------------------------------
  STATUS = []
  STATUS_ITEMS.each do |page|
    STATUS << []
    page.each do |s|
      params = s.split("_")
      name = params[0].to_sym
      rect = params.select {|s| s[/^-?\d+$/] }.map(&:to_i)
      rect.insert(2, rect.shift) if rect.size == 1
      rect.insert(1, nil)        if rect.size == 2
      opt = {}
      if name == :element || name == :state
        opt[name.to_sym] = :weak   if params.include?("weak")
        opt[name.to_sym] = :resist if params.include?("resist")
      end
      if name == :drop
        opt[:line] = 2 if params.include?("W")
      end
      txt = s[/_([SVLCRN]+)/, 1]
      if txt
        opt[:only] = :label if txt.include?("S")  # システム文字
        opt[:only] = :value if txt.include?("V")  # 値
        opt[:nobr] = true   if txt.include?("N")  # 改行無効
        opt[:align] = ["L","C","R"].index(txt[/([LCR])/,1]||0)
      end
      code = s[/_(?:\$|0x)([0-9a-fA-F]{3,8})/, 1] || ""
      case code.size
      when 3,4
        opt[:color] = Color.new(*(code.chars.map {|c| (c*2).to_i(16) } << 255))
      when 6,8
        opt[:color] = Color.new(*(code.scan(/../).map {|c| c.to_i(16) }))
      end
      x,y,w,h = *rect
      STATUS.last << [name, x, y, w, h, opt]
    end
  end
end
class RPG::Enemy::DropItem # uniq 等のメソッドのために定義
  #--------------------------------------------------------------------------
  # ● 同じアイテムなら常に同じハッシュ値を返し、種類がなしならば 0
  #--------------------------------------------------------------------------
  def hash
    @kind * 13 + @data_id * 31 * @kind
  end
  #--------------------------------------------------------------------------
  # ● 内容が等しければ true
  #--------------------------------------------------------------------------
  def ==(other)
    self.hash == other.hash
  end
  #--------------------------------------------------------------------------
  # ● 内容が等しければ true
  #--------------------------------------------------------------------------
  def eql?(other)
    self == other
  end
end
class << DataManager
  #--------------------------------------------------------------------------
  # ● 各種ゲームオブジェクトの作成
  #--------------------------------------------------------------------------
  alias _cao_mb_create_game_objects create_game_objects
  def create_game_objects
    _cao_mb_create_game_objects
    $game_mbook = Game_MonsterBook.new
  end
  #--------------------------------------------------------------------------
  # ● ニューゲームのセットアップ
  #--------------------------------------------------------------------------
  alias _cao_mb_setup_new_game setup_new_game
  def setup_new_game
    _cao_mb_setup_new_game
    $game_mbook.setup
  end
  #--------------------------------------------------------------------------
  # ● 戦闘テストのセットアップ
  #--------------------------------------------------------------------------
  alias _cao_mb_setup_battle_test setup_battle_test
  def setup_battle_test
    _cao_mb_setup_battle_test
    $game_mbook.setup
  end
  #--------------------------------------------------------------------------
  # ● セーブ内容の作成
  #--------------------------------------------------------------------------
  alias _cao_mb_make_save_contents make_save_contents
  def make_save_contents
    contents = _cao_mb_make_save_contents
    contents[:monster_book] = $game_mbook
    contents
  end
  #--------------------------------------------------------------------------
  # ● セーブ内容の展開
  #--------------------------------------------------------------------------
  alias _cao_mb_extract_save_contents extract_save_contents
  def extract_save_contents(contents)
    _cao_mb_extract_save_contents(contents)
    $game_mbook = contents[:monster_book] || $game_mbook.setup
  end
end
class << BattleManager
  #--------------------------------------------------------------------------
  # ○ 戦闘終了
  #     result : 結果 (0:勝利 1:逃走 2:敗北)
  #--------------------------------------------------------------------------
  alias _cao_mbook_battle_end battle_end
  def battle_end(result)
    if CAO::MB::AUTO_ENTRY_LOSE || result != 2
      $game_troop.members.each do |e|
        $game_mbook.enemy(e.enemy_id) do |dt|
          next if e.hidden?
          next if CAO::MB::AUTO_ENTRY_DEFEATED && e.alive?
          dt.encount = true
          dt.add(:encount)
          if e.dead?
            dt.defeat += 1
            dt.add(:battle)
          end
        end
      end
    end
    _cao_mbook_battle_end(result)
  end
end
class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # ● ドロップアイテムの配列作成
  #--------------------------------------------------------------------------
  def make_drop_items
    result = []
    mbk_enemy = $game_mbook.enemy(self.enemy_id)
    enemy.drop_items.each_with_index do |di,i|
      next if di.kind <= 0
      next if rand * di.denominator >= drop_item_rate
      mbk_enemy.drop_items << di.hash if mbk_enemy
      result << item_object(di.kind, di.data_id)
    end
    mbk_enemy.drop_items.uniq! if mbk_enemy
    return result
  end
  #--------------------------------------------------------------------------
  # ○ ステートの付加
  #--------------------------------------------------------------------------
  alias _cao_mbook_add_state add_state
  def add_state(state_id)
    if state_id == CAO::MB::ID_ANALYZE
      return unless analyze_addable?(state_id)
      $game_mbook.enemy(enemy_id) {|dt| dt.add(:analyze) }
    else
      _cao_mbook_add_state(state_id)
    end
  end
  #--------------------------------------------------------------------------
  # ● 解析ステートの付加判定
  #--------------------------------------------------------------------------
  def analyze_addable?(state_id)
    return false if state_id != CAO::MB::ID_ANALYZE
    return false unless $data_states[state_id]
    return false if state_resist?(state_id)
    return false if state_removed?(state_id)
    return false if state_restrict?(state_id)
    return true
  end
end
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● モンスター図鑑の起動
  #--------------------------------------------------------------------------
  def start_mbook
    return if $game_party.in_battle
    SceneManager.call(Scene_MonsterBook)
    Fiber.yield
  end
end
class Game_MonsterBookData
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :id                       # ＩＤ
  attr_reader   :enemy_id                 # ＩＤ
  attr_accessor :entry                    #
  attr_accessor :secret                   # 閲覧可否 (不可/可能)
  attr_accessor :unread                   # 既読状態 (未読/既読)
  attr_accessor :defeat                   # 撃退数
  attr_accessor :encount                  # 遭遇の有無 (遭遇済み/未遭遇)
  attr_accessor :drop_items               # ドロップアイテム (表示/非表示)
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #     id    : ＩＤ
  #     enemy : エネミー
  #--------------------------------------------------------------------------
  def initialize(id, enemy)
    @id = id
    @enemy_id = enemy.id
    setup
  end
  #--------------------------------------------------------------------------
  # ● 敵キャラのデータベースオブジェクトの取得
  #--------------------------------------------------------------------------
  def data
    $data_enemies[@enemy_id]
  end
  #--------------------------------------------------------------------------
  # ● 登録情報の初期化
  #--------------------------------------------------------------------------
  def setup
    clear
    reset_entry
    reset_secret
  end
  #--------------------------------------------------------------------------
  # ● 登録情報のクリア
  #--------------------------------------------------------------------------
  def clear
    @entry = []
    @secret = false
    @unread = true
    @defeat = 0
    @encount = false
    @drop_items = []
  end
  #--------------------------------------------------------------------------
  # ● 表示項目を初期化
  #--------------------------------------------------------------------------
  def reset_entry
    s = (self.note[/^@MB_ENTRY\[\s*(\w+)\s*\]/i, 1] || "")
    @entry = (CAO::MB::ENTRY_LIST[s] || CAO::MB::ENTRY_LIST[:start]).dup
  end
  #--------------------------------------------------------------------------
  # ● 非表示設定を初期化
  #--------------------------------------------------------------------------
  def reset_secret
    @secret = /^@MB_SECRET/ === self.note
  end
  #--------------------------------------------------------------------------
  # ● 項目を完成させる
  #--------------------------------------------------------------------------
  def complete
    @entry = CAO::MB::ENTRY_LIST[:complete].dup
    @drop_items = enemy_drop_items.uniq.map(&:hash)
    @secret = false
  end
  #--------------------------------------------------------------------------
  # ● 項目の完成度を取得
  #--------------------------------------------------------------------------
  def complete_rate
    return [
      CAO::MB::ENTRY_LIST[:complete].size + enemy_drop_items.uniq.size,
      @entry.size + @drop_items.size
    ]
  end
  #--------------------------------------------------------------------------
  # ● ドロップアイテムの取得
  #--------------------------------------------------------------------------
  def enemy_drop_items
    self.data.drop_items.select {|a| a.kind != 0 }
  end
  #--------------------------------------------------------------------------
  # ● 非表示設定の変更
  #--------------------------------------------------------------------------
  def secret=(v)
    @unread = true if @secret && !v
    @secret = v
  end
  #--------------------------------------------------------------------------
  # ● 登録情報の変更
  #--------------------------------------------------------------------------
  def set(params)
    @entry.replace(CAO::MB::ENTRY_LIST[params] || params)
    @unread = true
  end
  #--------------------------------------------------------------------------
  # ● 登録情報の追加
  #--------------------------------------------------------------------------
  def add(params)
    new_entry = @entry | (CAO::MB::ENTRY_LIST[params] || params)
    if @entry != new_entry
      @entry = new_entry
      @unread = true
    end
  end
  #--------------------------------------------------------------------------
  # ● 登録情報の削除
  #--------------------------------------------------------------------------
  def del(parms)
    @entry -= CAO::MB::ENTRY_LIST[params] || params
  end
  #--------------------------------------------------------------------------
  # ● 既読にする
  #--------------------------------------------------------------------------
  def read
    @unread = false if @unread && self.entry?
  end
  #--------------------------------------------------------------------------
  # ● 情報があるか
  #--------------------------------------------------------------------------
  def entry?
    return false if @entry.empty?
    return false if CAO::MB::SECRET_TYPE == 0 && @secret
    return true
  end
  #--------------------------------------------------------------------------
  # ● 項目が有効か判定
  #--------------------------------------------------------------------------
  def enable?(param)
    if @secret
      case CAO::MB::SECRET_TYPE
      when 0  # 完全非公開
        return !@secret && @entry.include?(param)
      when 1  # 名前のみ公開
        return param == :name && @entry.include?(param)
      when 2  # 名前がわかるまで非公開
        return @entry.include?(:name) && @entry.include?(param)
      else
        raise "SECRET_TYPE の設定が間違っています"
      end
    end
    return @entry.include?(param)
  end
  #--------------------------------------------------------------------------
  # ● 完成しているか判定 (非表示かどうかは考慮しない)
  #--------------------------------------------------------------------------
  def complete?
    return false unless (CAO::MB::ENTRY_LIST[:complete] - @entry).empty?
    return false unless drop_item_max == @drop_items.size
    return true
  end
  #--------------------------------------------------------------------------
  # ● エネミーの名前を取得
  #--------------------------------------------------------------------------
  def name
    return self.data.name
  end
  #--------------------------------------------------------------------------
  # ● パラメータの取得
  #--------------------------------------------------------------------------
  def hp
    return self.data.params[0]
  end
  def mp
    return self.data.params[1]
  end
  def atk
    return self.data.params[2]
  end
  def def
    return self.data.params[3]
  end
  def mat
    return self.data.params[4]
  end
  def mdf
    return self.data.params[5]
  end
  def age
    return self.data.params[6]
  end
  def luk
    return self.data.params[7]
  end
  #--------------------------------------------------------------------------
  # ● ドロップアイテムの最大数の取得
  #--------------------------------------------------------------------------
  def drop_item_max
    return self.data.drop_items.uniq.count {|di| di.kind != 0 }
  end
  #--------------------------------------------------------------------------
  # ● コメントの取得
  #--------------------------------------------------------------------------
  def comments
    @comments ||= make_comments
  end
  def make_comments
    prev,sep,foll = self.note.partition("@MB_COMMENT")
    if sep.empty?
      return []
    else
      prev,sep,foll = foll.strip.rpartition("@")
      text = (sep.empty? ? foll : prev).rstrip
      return text.split("\r\n")
    end
  end
  #--------------------------------------------------------------------------
  # ● メモの取得
  #--------------------------------------------------------------------------
  def note
    return self.data.note
  end
  #--------------------------------------------------------------------------
  # ● 戦闘グラフィックのファイル名の取得
  #--------------------------------------------------------------------------
  def battler_name
    return self.data.battler_name
  end
  #--------------------------------------------------------------------------
  # ● 戦闘グラフィックの色相の取得
  #--------------------------------------------------------------------------
  def battler_hue
    return self.data.battler_hue
  end
  #--------------------------------------------------------------------------
  # ● 戦闘グラフィックの取得
  #--------------------------------------------------------------------------
  def bitmap
    Cache.battler(self.data.battler_name, self.data.battler_hue)
  end
end
class Game_MonsterBook
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    @data = [nil]
    @replacement = {}   # 代替エネミー
  end
  #--------------------------------------------------------------------------
  # ● エネミーの図鑑情報を取得
  #--------------------------------------------------------------------------
  def [](book_id = nil)
    return book_id ? @data[book_id] : @data
  end
  #--------------------------------------------------------------------------
  # ● エネミーの図鑑情報を設定
  #--------------------------------------------------------------------------
  def []=(book_id, value)
    @data[book_id] = value
  end
  #--------------------------------------------------------------------------
  # ● エネミー ID から図鑑情報を取得
  #     &block: 除外されていなければ図鑑情報を引数にブロックの内容を実行
  #--------------------------------------------------------------------------
  def enemy(enemy_id)
    enemy_id = @replacement[enemy_id] || enemy_id
    book_data = @data.find {|e| e && enemy_id == e.enemy_id }
    yield book_data if block_given? && book_data
    return book_data
  end
  #--------------------------------------------------------------------------
  # ● エネミー ID から図鑑情報を取得
  #--------------------------------------------------------------------------
  def enemies(*enemy_id)
    list = enemy_id.flatten
    if list.empty?
      return self.data
    else
      list.map! {|id| @replacement[id] || id }
      return @data.select {|e| e && list.include?(e.enemy_id) }
    end
  end
  #--------------------------------------------------------------------------
  # ● 図鑑に登録できるエネミーの配列
  #--------------------------------------------------------------------------
  def data
    @data.drop(1)
  end
  #--------------------------------------------------------------------------
  # ● 図鑑に登録できるエネミーの数
  #--------------------------------------------------------------------------
  def size
    return @data.size - 1
  end
  #--------------------------------------------------------------------------
  # ● 図鑑を初期化
  #--------------------------------------------------------------------------
  def setup
    @data = [nil]
    @replacement = {}
    $data_enemies.each do |enemy|
      next if !enemy
      if enemy.note[/^@MB_DESELECTION\s?(\d+)?/i]
        @replacement[enemy.id] = $1.to_i
      else
        @data << Game_MonsterBookData.new(@data.size, enemy)
      end
    end
    return self
  end
  #--------------------------------------------------------------------------
  # ● 除外されたエネミーか判定
  #--------------------------------------------------------------------------
  def include?(enemy_id)
    return enemy(enemy_id) != nil
  end
  #--------------------------------------------------------------------------
  # ● 図鑑が完成しているか判定 (すべて表示されているか)
  #--------------------------------------------------------------------------
  def complete?
    return false if self.data.any? {|e| e.secret }
    return self.size == self.completion_count
  end
  #--------------------------------------------------------------------------
  # ● 図鑑を完成させる
  #--------------------------------------------------------------------------
  def complete
    self.each {|e| e.complete }
  end
  #--------------------------------------------------------------------------
  # ● イテレータの定義
  #--------------------------------------------------------------------------
  def each
    self.data.each {|e| yield e }
  end
  def select
    self.data.select {|e| yield e }
  end
  def find
    self.data.find {|e| yield e }
  end
  #--------------------------------------------------------------------------
  # ● 総完成数の取得
  #--------------------------------------------------------------------------
  def complete_count
    return self.data.select {|e| e.complete? }.size
  end
  #--------------------------------------------------------------------------
  # ● 総登録数の取得
  #--------------------------------------------------------------------------
  def entry_count(*params)
    if params.empty?
      return self.data.select {|e| !e.entry.empty? }.size
    else
      return self.data.select {|e| params.size < (e.entry & params).size }.size
    end
  end
  #--------------------------------------------------------------------------
  # ● 総撃退数の取得
  #--------------------------------------------------------------------------
  def defeat_count(*list_id)
    if list_id.empty?
      return self.data.inject(0) {|c, e| c + e.defeat }
    else
      return list_id.inject(0) {|c, id| c + self[id].defeat }
    end
  end
  #--------------------------------------------------------------------------
  # ● 遭遇した種類数を取得
  #--------------------------------------------------------------------------
  def encount_count
    return self.select {|e| e.encount }.size
  end
  #--------------------------------------------------------------------------
  # ● 図鑑の完成度の取得 (0.0 - 1.0)
  #--------------------------------------------------------------------------
  def complete_rate
    total = 0
    count = 0
    self.each do |e|
      max,now = e.complete_rate
      total += max
      count += now
    end
    return count.fdiv(total)
  end
  #--------------------------------------------------------------------------
  # ● 遭遇した種類を百分率で取得 (0 - 100)
  #--------------------------------------------------------------------------
  def encount_rate
    return encount_count * 100 / self.size
  end
end
class Window_MonsterBookCommand < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :status_window            # ステータスウィンドウ
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0, window_width, window_height)
    refresh
    select(0)
    activate
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ幅の取得
  #--------------------------------------------------------------------------
  def window_width
    return 184 + Graphics.width - 544
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ高さの取得
  #--------------------------------------------------------------------------
  def window_height
    return Graphics.height
  end
  #--------------------------------------------------------------------------
  # ● 項目数の取得
  #--------------------------------------------------------------------------
  def item_max
    @data ? @data.size : 1
  end
  #--------------------------------------------------------------------------
  # ● アイテムの取得
  #--------------------------------------------------------------------------
  def item
    @data[index]
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    make_item_list
    create_contents
    draw_all_items
  end
  #--------------------------------------------------------------------------
  # ● アイテムリストの作成
  #--------------------------------------------------------------------------
  def make_item_list
    @data =
      if SceneManager.scene_is?(Scene_Battle)
        list_id = $game_troop.members.select(&:exist?).map(&:enemy_id)
        $game_mbook.enemies(list_id)
      else
        $game_mbook.data
      end
  end
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #--------------------------------------------------------------------------
  def draw_item(index)
    enemy = @data[index]
    rect = item_rect(index)
    rect.x += 4
    rect.width -= 8
    if enemy.entry?
      change_color(enemy.unread ? text_color(11) : normal_color)
      if enemy.enable?(:name)
        draw_text(rect, enemy.name)
      else
        draw_text(rect, "？？？？？？？", 1)
      end
    else
      change_color(text_color(18))
      draw_text(rect, "--------------", 1)
    end
  end
  #--------------------------------------------------------------------------
  # ● ステータスウィンドウの設定
  #--------------------------------------------------------------------------
  def status_window=(status_window)
    @status_window = status_window
    call_update_help
  end
  #--------------------------------------------------------------------------
  # ● の設定
  #--------------------------------------------------------------------------
  def enemy_sprite=(enemy_sprite)
    @enemy_sprite = enemy_sprite
  end
  #--------------------------------------------------------------------------
  # ● ヘルプテキスト更新
  #--------------------------------------------------------------------------
  def update_help
    @help_window.set_item(item) if @help_window
    @status_window.enemy = item if @status_window
    @enemy_sprite.enemy = item if @enemy_sprite
  end
  #--------------------------------------------------------------------------
  # ● ヘルプウィンドウ更新メソッドの呼び出し
  #--------------------------------------------------------------------------
  def call_update_help
    update_help if active
  end
  #--------------------------------------------------------------------------
  # ● カーソルを右に移動
  #--------------------------------------------------------------------------
  def cursor_right(wrap = false)
    @status_window.page_index += 1
  end
  #--------------------------------------------------------------------------
  # ● カーソルを左に移動
  #--------------------------------------------------------------------------
  def cursor_left(wrap = false)
    @status_window.page_index -= 1
  end
  #--------------------------------------------------------------------------
  # ● カーソルの移動処理
  #--------------------------------------------------------------------------
  def process_cursor_move
    last_index = @status_window.page_index
    super
    Sound.play_cursor if @status_window.page_index != last_index
  end
end
class Window_MonsterBookStatus < Window_Base
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  KEY_STATUS = [:hp, :mp, :atk, :def, :mat, :mdf, :age, :luk]
  COL_IMGBACK = Color.new(0, 0, 0, 128)
  ICO_EMPTY = 16
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(x, y)
    super(x, y, 360, Graphics.height)
    @page_index = CAO::MB::START_PAGE
  end
  #--------------------------------------------------------------------------
  # ● の設定
  #--------------------------------------------------------------------------
  def enemy=(enemy)
    @enemy = enemy
    refresh
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ内容の幅を計算
  #--------------------------------------------------------------------------
  def contents_width
    page_width * page_max
  end
  #--------------------------------------------------------------------------
  # ● 現在のページのｘ座標
  #--------------------------------------------------------------------------
  def page_x
    page_width * page_index
  end
  #--------------------------------------------------------------------------
  # ● 現在のページの左端ｘ座標
  #--------------------------------------------------------------------------
  def page_rx
    page_width * (page_index + 1)
  end
  #--------------------------------------------------------------------------
  # ● １ページの横幅
  #--------------------------------------------------------------------------
  def page_width
    return width - standard_padding * 2
  end
  #--------------------------------------------------------------------------
  # ● 最大ページ数
  #--------------------------------------------------------------------------
  def page_max
    return CAO::MB::STATUS.size
  end
  #--------------------------------------------------------------------------
  # ● 行位置のリセット
  #--------------------------------------------------------------------------
  def reset_line
    @y = 0
  end
  #--------------------------------------------------------------------------
  # ● 行を進める
  #--------------------------------------------------------------------------
  def step_line(v = nil)
    now = @y
    @y += v || line_height
    return now
  end
  #--------------------------------------------------------------------------
  # ● 表示ページの設定
  #--------------------------------------------------------------------------
  attr_reader :page_index
  def page_index=(index)
    last_index = @page_index
    @page_index = [0, [index, page_max - 1].min].max
    self.ox = page_width * @page_index
    refresh if last_index != @page_index
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    contents.clear
    draw_page(@page_index)
    @enemy.read
  end
  #--------------------------------------------------------------------------
  # ● ページの描画
  #--------------------------------------------------------------------------
  def draw_page(index)
    reset_line
    CAO::MB::STATUS[index].each {|a| draw_item(a[0], a[1..5]) }
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def entry?(param)
    @enemy.enable?(param)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def enabled?(key)
    return true if entry?(:status) && KEY_STATUS.any? {|k| key == k }
    return true if key == :status && KEY_STATUS.any? {|k| entry?(k) }
    return true if [:line, :space, :script].include?(key)
    return entry?(key)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_item(name, args)
    __send__("draw_#{name}", *args, enabled?(name))
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def default_position(x, y, width, height, option={})
    x    ||= 0
    y    ||= option[:nobr] ? @y : step_line
    width  = page_width - x if (width  || 0) == 0
    height = line_height    if (height || 0) == 0
    align  = option[:align] || 0
    return x + page_width * page_index, y, width, height, align
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_no(x, y, width, height, option, enabled)
    x, y, width, height, align = default_position(x, y, width, height, option)
    if display?(:label, option)
      align = 0 if only?(:label, option)
      change_color(system_color)
      draw_text(x, y, width, line_height, "No.", align)
    end
    if display?(:value, option)
      align = 2 if !only?(:value, option)
      change_color(normal_color)
      draw_text(x, y, width, line_height, enabled ? @enemy.id : "---", align)
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_name(x, y, width, height, option, enabled)
    x, y, width, height, align = default_position(x, y, width, height, option)
    change_color(normal_color)
    draw_text(x, y, width, line_height, enabled ? @enemy.name : "?"*8, align)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_status(x, y, width, height, option, enabled)
    x, y, width, height = default_position(x, y||@y, width, height, option)
    width = width / 2 - 4
    4.times do |i|
      id = i * 2
      y = step_line
      draw_param(id, x, y, width, line_height, 0, 0, enabled)
      draw_param(id+1, x+width+8, y, width, line_height, 0, 0, enabled)
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_param(param_id, x, y, width, height, only, align, enabled)
    x, y, width, height = default_position(x, y, width, height)
    only  ||= 0
    align ||= 0
    if only != :value
      align = 0 if only != :label
      change_color(system_color)
      draw_text(x, y, width, line_height, Vocab.param(param_id), align)
    end
    if only != :label
      align = 2 if only != :value
      change_color(normal_color)
      text = enabled ? @enemy.data.params[param_id] : "????"
      draw_text(x, y, width, line_height, text, align)
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_hp(x, y, width, height, option, enabled)
    draw_param(0, x, y, width, height, option[:only], option[:align], enabled)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_mp(x, y, width, height, option, enabled)
    draw_param(1, x, y, width, height, option[:only], option[:align], enabled)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_atk(x, y, width, height, option, enabled)
    draw_param(2, x, y, width, height, option[:only], option[:align], enabled)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_def(x, y, width, height, option, enabled)
    draw_param(3, x, y, width, height, option[:only], option[:align], enabled)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_mat(x, y, width, height, option, enabled)
    draw_param(4, x, y, width, height, option[:only], option[:align], enabled)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_mdf(x, y, width, height, option, enabled)
    draw_param(5, x, y, width, height, option[:only], option[:align], enabled)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_age(x, y, width, height, option, enabled)
    draw_param(6, x, y, width, height, option[:only], option[:align], enabled)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_luk(x, y, width, height, option, enabled)
    draw_param(7, x, y, width, height, option[:only], option[:align], enabled)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_exp(x, y, width, height, option, enabled)
    x, y, width, height, align = default_position(x, y, width, height, option)
    if display?(:label, option)
      change_color(system_color)
      draw_text(x, y, width, line_height, "経験値", 0)
    end
    if display?(:value, option)
      align = 2 if display?(:label, option)
      change_color(normal_color)
      text = enabled ? @enemy.data.exp : "????"
      draw_text(x, y, width, line_height, text, align)
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_gold(x, y, width, height, option, enabled)
    x, y, width, height, align = default_position(x, y, width, height, option)
    cx = 0
    if display?(:label, option)
      change_color(system_color)
      draw_text(x, y, width, line_height, "報　酬", 0)
      draw_text(x, y, width, line_height, Vocab.currency_unit, 2)
      cx = text_size(Vocab.currency_unit).width + 4
    end
    if display?(:value, option)
      align = 2 if display?(:label, option)
      change_color(normal_color)
      text = enabled ? @enemy.data.gold : "????"
      draw_text(x, y, width - cx, line_height, text, align)
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_defeat(x, y, width, height, option, enabled)
    x, y, width, height, align = default_position(x, y, width, height, option)
    cx = 0
    if display?(:label, option)
      change_color(system_color)
      draw_text(x, y, width, line_height, "倒した数", 0)
      draw_text(x, y, width, line_height, "体", 2)
      cx = text_size(Vocab.currency_unit).width + 4
    end
    if display?(:value, option)
      align = 2 if display?(:label, option)
      text = enabled ? @enemy.defeat : "????"
      change_color(normal_color)
      draw_text(x, y, width - cx, line_height, text, align)
    end
  end
  #--------------------------------------------------------------------------
  # ● アイテムオブジェクトの取得
  #--------------------------------------------------------------------------
  def item_object(kind, data_id)
    return $data_items  [data_id] if kind == 1
    return $data_weapons[data_id] if kind == 2
    return $data_armors [data_id] if kind == 3
    return nil
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_drop(x, y, width, height, option, enabled)
    x, @y, width, height, align = default_position(x, y, width, height, option)
    if display?(:label, option)
      change_color(system_color)
      draw_text(x, step_line, width, line_height, "ドロップアイテム", 0)
      x += 24
    end
    if display?(:value, option)
      align = 2 if display?(:label, option)
      drop_items = @enemy.data.drop_items.uniq
      item_max = drop_items.count {|di| di.kind != 0 }
      drop_items.select! {|di| @enemy.drop_items.include?(di.hash) }
      drop_items.map! {|di| item_object(di.kind, di.data_id) }
      if option[:line] == 2
        width /= 2
        3.times do |i|
          draw_item_name(drop_items[i], x+i%2*width, @y, width, i < item_max)
          step_line if i%2 == 1
        end
      else
        3.times do |i|
          draw_item_name(drop_items[i], x, step_line, width, i < item_max)
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● アイテム名の描画
  #     enabled : 有効フラグ。false のとき半透明で描画
  #--------------------------------------------------------------------------
  def draw_item_name(item, x, y, width = 172, enabled = true)
    if enabled
      if item
        icon_index = item.icon_index
        item_name  = item.name
      else
        icon_index = ICO_EMPTY
        item_name  = "????????????"
      end
    else
      icon_index = ICO_EMPTY
      item_name  = "------------"
    end
    draw_icon(icon_index, x, y)
    change_color(normal_color)
    draw_text(x + 28, y, width - 28, line_height, item_name)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_graphic(x, y, width, height, option, enabled)
    x, y, width, height = default_position(x, y||@y, width, height)
    rect = Rect.new(x, y, width, height)
    bitmap = @enemy.bitmap
    if enabled
      if rect.width < bitmap.width
        zoom = rect.width.to_f / bitmap.width
        rect.height = bitmap.height * zoom
      else
        rect.width = bitmap.width
      end
      if rect.height < bitmap.height
        zoom = rect.height.to_f / bitmap.height
        rect.width = bitmap.width * zoom
      else
        rect.height = bitmap.height
      end
      rect.x += (page_width - rect.width) / 2
      rect.y += (height - rect.height) / 2
      contents.stretch_blt(rect, bitmap, bitmap.rect)
    else
      contents.fill_rect(rect, COL_IMGBACK)
      contents.draw_text(rect, "？", 1)
    end
    @y += height || rect.height
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_comment(x, y, width, height, option, enabled)
    # FIXME: 項目名、enabled 設定
    x, y, width, height, align = default_position(x, y, width, height, option)
    return unless enabled
    @y = y
    @enemy.comments.each do |comment|
      xx = x
      comment.each_char do |c|
        tw = contents.text_size(c).width
        draw_text(xx, @y, tw + 2, line_height, c, 1)
        xx += tw
      end
      step_line
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_line(x, y, width, height, option, enabled)
    x, dummy, width, height = default_position(x, 0, width, height||2)
    margin = option[:margin] || 0
    y ||= step_line(option[:nobr] ? 0 : height + margin * 2) + margin
    color = option[:color] || normal_color
#~     option[:valign]
#~     option[:shadow]
    contents.fill_rect(x, y, width, height, color)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_script(x, y, width, height, option, enabled)
    eval(option[:script])
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_space(x, y, width, height, option, enabled)
    @y += height || width || line_height
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_element(x, y, width, height, option, enabled)
    x, y, width, height, align = default_position(x, y, width, height, option)
    code = Game_BattlerBase::FEATURE_ELEMENT_RATE   # 属性有効度
    features = @enemy.data.features.select {|f| f.code == code }
    case option[:element]
    when :weak
      label = "有効属性"
      features.select! {|f| f.value > 1.0 }
    when :resist
      label = "耐性属性"
      features.select! {|f| f.value < 1.0 }
    end
    features.select! {|f| CAO::MB::USABLE_ELEMENT.include?(f.data_id) }
    if CAO::MB::ICO_ELEMENT
      features.map! {|f| CAO::MB::USABLE_ELEMENT.index(f.data_id) }
      elements = features.map {|id| CAO::MB::ICO_ELEMENT[id] }
    else
      elements = features.map {|f| $data_system.elements[f.data_id][0] }
    end
    if display?(:label, option)
      change_color(system_color)
      draw_text(x, y, width, line_height, label, 0)
      x += 80
    end
    if display?(:value, option)
      elements = Array.new(6, "??") unless enabled
      align = 2 if display?(:label, option)
      x = page_width - elements.size * 24 if align == 2
      change_color(normal_color)
      elements.each do |e|
        if CAO::MB::ICO_ELEMENT && enabled
          draw_icon(e, x, y)
        else
          draw_text(x, y, 24, line_height, e, 1)
        end
        x += 24
      end
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_state(x, y, width, height, option, enabled)
    x, y, width, height, align = default_position(x, y, width, height, option)
    code = Game_BattlerBase::FEATURE_STATE_RATE     # ステート有効度
    features = @enemy.data.features.select {|f| f.code == code }
    case option[:state]
    when :weak
      label = "有効ステート"
      features.select! {|f| f.value > 1.0 }
    when :resist
      label = "耐性ステート"
      features.select! {|f| f.value < 1.0 }
      code = Game_BattlerBase::FEATURE_STATE_RESIST # ステート無効化
      features += @enemy.data.features.select {|f| f.code == code }
    end
    features.select! {|f| CAO::MB::USABLE_STATE.include?(f.data_id) }
    states = features.map {|f| $data_states[f.data_id] }
    if display?(:label, option)
      change_color(system_color)
      draw_text(x, y, width, line_height, label, 0)
      x += 80
    end
    if display?(:value, option)
      states = Array.new(6, "??") unless enabled
      align = 2 if display?(:label, option)
      x = page_rx - states.size * 24 if align == 2
      change_color(normal_color)
      states.each do |s|
        if enabled
          draw_icon(s.icon_index, x, y)
        else
          draw_text(x, y, 24, line_height, s, 1)
        end
        x += 24
      end
    end
  end
  private
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def display?(type, option)
    case type
    when :label
      return option[:only] != :value
    when :value
      return option[:only] != :label
    end
    return true
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def only?(type, option)
    return option[:only] == type
  end
end
class Window_MonsterBookInfo < Window_Base
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(width, params)
    @params = params
    if width == Graphics.width
      super(0, 0, width, window_height)
    else
      super(0, 0, width, fitting_height(params.size))
      self.height = window_height
    end
    refresh
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ高さの取得
  #--------------------------------------------------------------------------
  def window_height
    line_height + standard_padding * 2
  end
  #--------------------------------------------------------------------------
  # ● 指定行数に適合するウィンドウの高さを計算
  #--------------------------------------------------------------------------
  def fitting_height(line_number)
    line_number * line_height + standard_padding * 2
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    if line_height < contents.height
      @params.each_with_index do |param,index|
        draw_item(0, line_height * index, contents.width, param)
      end
    else
      w = contents.width / @params.size
      @params.each_with_index do |param,index|
        draw_item(w * index + 4, 0, w - 8, param)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_item(x, y, width, param)
    case param
    when :defeat
      t = "総撃退数"
      v = $game_mbook.defeat_count
    when :encount
      t = "総遭遇数"
      v = $game_mbook.encount_count
    when :complete
      t = "完成度"
#~       v = sprintf("%d/%d", $game_mbook.complete_count, $game_mbook.size)
      v = sprintf("%.2f %%", $game_mbook.complete_rate * 100)
    else
      t = nil
      v = param
    end
    if t
      change_color(system_color)
      draw_text(x, y, width, line_height, t)
      change_color(normal_color)
      draw_text(x, y, width, line_height, v, 2)
    else
      change_color(normal_color)
      draw_text(x, y, width, line_height, v, 1)
    end
  end
end
class Sprite_MonsterBookEnemy < Sprite
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super
    @enemy = nil
    self.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    self.color = Color.new(0, 0, 0)
    self.z = 200
    self.visible = false
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def dispose
    super
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def show(enemy = nil)
    self.enemy = enemy if enemy
    refresh
    self.visible = true
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def close
    self.visible = false
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def enemy=(enemy)
    return if @enemy == enemy
    @enemy = enemy
    refresh
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def refresh
    self.bitmap.clear
    self.bitmap.fill_rect(self.bitmap.rect, Color.new(0, 0, 0, 128))
    self.color.alpha = @enemy.enable?(:graphic) ? 0 : 255
    if @enemy
      bmp = @enemy.bitmap
      x = (self.width - bmp.width) / 2
      y = (self.height - bmp.height) / 2
      self.bitmap.blt(x, y, bmp, bmp.rect)
    end
  end
end
class Scene_MonsterBook < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● 開始処理
  #--------------------------------------------------------------------------
  def start
    super
    create_command_window
    create_status_window
    create_enemy_sprite
    create_info_window
  end
  #--------------------------------------------------------------------------
  # ● 情報ウィンドウの作成
  #--------------------------------------------------------------------------
  def create_info_window
    sy = 0
    ly = 0
    params = CAO::MB::LARGE_INFO.drop(1)
    if !params.empty?
      @largeinfo_window =
        Window_MonsterBookInfo.new(Graphics.width, params)
      @status_window.height -= @largeinfo_window.height
      @status_window.create_contents
      @status_window.refresh
      @command_window.height -= @largeinfo_window.height
      if CAO::MB::LARGE_INFO[0] == 0
        sy += @largeinfo_window.height
        @command_window.y += @largeinfo_window.height
        @status_window.y += @largeinfo_window.height
      else
        ly += @status_window.height
      end
    end
    params = CAO::MB::SMALL_INFO.drop(1)
    if !params.empty?
      @smallinfo_window =
        Window_MonsterBookInfo.new(@command_window.width, params)
      @command_window.height -= @smallinfo_window.height
      if CAO::MB::SMALL_INFO[0] == 0
        @command_window.y += @smallinfo_window.height
      else
        sy += @command_window.height
      end
    end
    @smallinfo_window.y = sy if @smallinfo_window
    @largeinfo_window.y = ly if @largeinfo_window
  end
  #--------------------------------------------------------------------------
  # ● コマンドウィンドウの作成
  #--------------------------------------------------------------------------
  def create_command_window
    @command_window = Window_MonsterBookCommand.new
    @command_window.set_handler(:ok, method(:command_ok))
    @command_window.set_handler(:cancel, method(:command_cancel))
  end
  #--------------------------------------------------------------------------
  # ● ステータスウィンドウの作成
  #--------------------------------------------------------------------------
  def create_status_window
    @status_window = Window_MonsterBookStatus.new(@command_window.width, 0)
    @command_window.status_window = @status_window
  end
  #--------------------------------------------------------------------------
  # ● ｚ
  #--------------------------------------------------------------------------
  def create_enemy_sprite
    @enemy_sprite = Sprite_MonsterBookEnemy.new
    @command_window.enemy_sprite = @enemy_sprite
  end
  #--------------------------------------------------------------------------
  # ● 終了処理
  #--------------------------------------------------------------------------
  def terminate
    super
  end
  #--------------------------------------------------------------------------
  # ● コマンド［画像表示］
  #--------------------------------------------------------------------------
  def command_ok
    @command_window.activate
    if @enemy_sprite.visible
      @enemy_sprite.close
    else
      @enemy_sprite.show(@command_window.item)
    end
  end
  #--------------------------------------------------------------------------
  # ● コマンド［キャンセル］
  #--------------------------------------------------------------------------
  def command_cancel
    @command_window.activate
    if @enemy_sprite.visible
      @enemy_sprite.close
    else
      return_scene
    end
  end
end
if CAO::MB::PARTY_COMMAND
class Window_PartyCommand < Window_Command
  #--------------------------------------------------------------------------
  # ● コマンドリストの作成
  #--------------------------------------------------------------------------
  alias _cao_mbook_make_command_list make_command_list
  def make_command_list
    _cao_mbook_make_command_list
    @list << @list.pop.tap { add_command("解析結果", :analyze) }
  end
end
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ● 全ウィンドウの作成
  #--------------------------------------------------------------------------
  alias _cao_mbook_create_all_windows create_all_windows
  def create_all_windows
    _cao_mbook_create_all_windows
    create_mbook_window
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウの作成
  #--------------------------------------------------------------------------
  def create_mbook_window
    @mbook_command_window = Window_MonsterBookCommand.new
    @mbook_command_window.set_handler(:cancel, method(:mbook_cancel))
    @mbook_status_window =
      Window_MonsterBookStatus.new(@mbook_command_window.width, 0)
    @mbook_command_window.status_window = @mbook_status_window
    @mbook_command_window.deactivate
    @mbook_command_window.openness = 0
    @mbook_status_window.deactivate
    @mbook_status_window.openness = 0
  end
  #--------------------------------------------------------------------------
  # ● パーティコマンドウィンドウの作成
  #--------------------------------------------------------------------------
  alias _cao_mbook_create_party_command_window create_party_command_window
  def create_party_command_window
    _cao_mbook_create_party_command_window
    @party_command_window.set_handler(:analyze, method(:command_analyze))
  end
  #--------------------------------------------------------------------------
  # ● コマンド［解析］
  #--------------------------------------------------------------------------
  def command_analyze
    @party_command_window.deactivate
    @mbook_command_window.refresh
    @mbook_command_window.activate.open
    @mbook_status_window.open
  end
  #--------------------------------------------------------------------------
  # ● コマンド［］
  #--------------------------------------------------------------------------
  def mbook_cancel
    @party_command_window.activate
    @mbook_command_window.deactivate.close
    @mbook_status_window.close
  end
end
end # if
