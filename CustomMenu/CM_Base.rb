#******************************************************************************
#
#    ＊ Custom Menu Base
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.1.4
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： http://cacaosoft.webcrow.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#    ： カスタムメニューのベーススクリプトです。
#
#  --------------------------------------------------------------------------
#   == 注意事項 ==
#
#    ※ このスクリプトは、なるべく下のほうのに導入してください。
#    ※ カスタムメニュー関連のスクリプトより上に導入してください。
#
#
#******************************************************************************


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module CAO
module CM
  #--------------------------------------------------------------------------
  # ◇ メニュー項目の設定
  #--------------------------------------------------------------------------
  COMMAND_ITEMS = {}
  COMMAND_ITEMS[:item] = {
    :name     => "アイテム",
    :command  => Scene_Item,
    :help     => 'アイテムを使用します。'
  }
  COMMAND_ITEMS[:skill] = {
    :name     => "スキル",
    :personal => Scene_Skill,
    :help     => 'スキルを使用します。'
  }
  COMMAND_ITEMS[:equip] = {
    :name     => "装備",
    :personal => Scene_Equip,
    :help     => '装備を変更します。'
  }
  COMMAND_ITEMS[:status] = {
    :name     => "ステータス",
    :personal => Scene_Status,
    :help     => 'ステータスを確認します。'
  }
  COMMAND_ITEMS[:formation] = {
    :name     => "並び替え",
    :command  => :command_formation,
    :enable   => :formation_enabled,
    :help     => 'パーティを入れ替えます。'
  }
  COMMAND_ITEMS[:save] = {
    :name     => "セーブ",
    :command  => Scene_Save,
    :hide     => "$game_system.save_disabled",
    :help     => 'ゲームをセーブします。'
  }
  COMMAND_ITEMS[:game_end] = {
    :name     => "ゲーム終了",
    :command  => Scene_End,
    :help     => 'ゲームを終了します。'
  }
  
  COMMAND_ITEMS[:load] = {
    :name     => "ロード",
    :command  => Scene_Load,
    :enable   => "DataManager.save_file_exists?",
    :help     => 'ゲームをロードします。'
  }
  COMMAND_ITEMS[:script] = {
    :name     => "スクリプト",
    :command  => "msgbox 'メッセージの表示'",
    :help     => "メッセージボックスを表示します。"
  }
  COMMAND_ITEMS[:common] = {
    :name     => "コモンイベント",
    :command  => 'start_common_event(1)',
    :refresh  => [:command, :text]
  }
  COMMAND_ITEMS[:common2] = {
    :name     => "レベルアップ！",
    :personal => 'start_common_event(3)',
    :refresh  => [:status]
  }
  COMMAND_ITEMS[:common3] = {
    :name     => "予約コモン",
    :command  => '$game_temp.reserve_common_event(2)',
  }
  COMMAND_ITEMS[:sw] = {
    :name     => [17, "スイッチ ON", "スイッチ OFF"],
    :command  => "$game_switches[17] ^= true",
    :refresh  => [:command]
  }
  
  COMMAND_ITEMS[:sub] = {
    :name => "サブコマンド",
    :sub => :sub,
    :help => "サブコマンドのテストを行います。"
  }
  COMMAND_ITEMS[:file] = {
    :name => "ファイル",
    :sub  => :file,
    :help => "ゲームのセーブ・ロードを行います。"
  }
  
  #--------------------------------------------------------------------------
  # ◇ 表示項目の設定
  #--------------------------------------------------------------------------
  COMMANDS = {}   # <= 消さない！
  # メインコマンド 必須
  COMMANDS[:main] =
    [:item, :skill, :equip, :status, :formation, :save, :game_end]
  # サブコマンド
  COMMANDS[:file] =
    [:save, :load]
  COMMANDS[:sub] =
    [:item, :status, :sw, :script, :common, :common2, :common3]

  #--------------------------------------------------------------------------
  # ◇ コマンドウィンドウの文字サイズ
  #--------------------------------------------------------------------------
  COMMAND_SIZE = 24
  #--------------------------------------------------------------------------
  # ◇ コマンドウィンドウの一行の縦幅
  #--------------------------------------------------------------------------
  #     0 で文字サイズを基準に自動調整
  #--------------------------------------------------------------------------
  COMMAND_HEIGHT = 0
  
  #--------------------------------------------------------------------------
  # ◇ 残りＨＰで顔グラを変化させる
  #--------------------------------------------------------------------------
  EXPRESSIVE_RATE = []
  #--------------------------------------------------------------------------
  # ◇ 顔グラをまとめる
  #--------------------------------------------------------------------------
  COLLECT_FACE = false
  #--------------------------------------------------------------------------
  # ◇ 立ち絵のファイル名
  #--------------------------------------------------------------------------
  PORTRAIT_NAME = "MActor%d"

  #--------------------------------------------------------------------------
  # ◇ コモンイベントの自動実行
  #--------------------------------------------------------------------------
  START_COMMON_ID     = 0     # 開始前処理
  TERMINATE_COMMON_ID = 0     # 終了前処理
  
  #--------------------------------------------------------------------------
  # ◇ 背景画像
  #--------------------------------------------------------------------------
  # 前景画像（最前面に表示されます。）
  FILE_FOREGROUND = nil
  # 背景画像（デフォルトのマップ画像と入れ替えます。）
  FILE_BACKGROUND = nil
  # アニメ画像 ["ファイル名", vx, vy, 最背面？]
  BACKIMAGE = nil
  
  #--------------------------------------------------------------------------
  # ◇ システム文字の有無
  #--------------------------------------------------------------------------
  VISIBLE_SYSTEM = true
  #--------------------------------------------------------------------------
  # ◇ 用語設定
  #--------------------------------------------------------------------------
  VOCABS = {}
  VOCABS[:gold]  = "所持金"
  VOCABS[:exp]   = "経験値"
  VOCABS[:exp_a] = "LvUP"
  
end # module CM
end # module CAO


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class CustomizeError < Exception; end

class Game_MenuItem
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  attr_reader :symbol                     # 
  attr_reader :sub                        # 
  attr_reader :enable                     # 
  attr_reader :refresh_items              # 
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def initialize(symbol, params = {})
    @symbol = symbol                          # 項目の識別子
    @name   = params[:name]   || ""           # 項目名
    @help   = params[:help]   || ""           # ヘルプ
    @icon   = params[:icon]                   # アイコン番号
    @enable = params[:enable] || true         # 選択の可否
    @hide   = params[:hide]   || false        # 非表示の有無
    
    @scene    = params[:scene]                # 項目処理 シーン遷移
    @command  = params[:command]              # 項目処理 コマンド実行
    @personal = params[:personal]             # 項目処理 アクター選択
    @sub      = params[:sub]                  # 項目処理 サブコマンド
    case [@scene, @command, @personal, @sub].count {|o| o }
    when 0; raise CustomizeError, "項目処理が設定されていません。"
    when 1  # Do Nothing
    else;   raise CustomizeError, "複数の項目処理が設定されています。"
    end
    
    @refresh_items = params[:refresh] || []     # 項目処理後に再描画
    @auto_close = params[:auto_close] || false  # アクター選択時コマンドを閉じる
    @continue = params[:continue] || false      # アクター選択継続
    @sw_sub = params[:sw_sub] || false          # サブ表示時にメインを非表示
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def _convert_value(obj)
    if obj.is_a?(Array)
      case obj[0]
      when String
        result = eval(obj[0], ::TOPLEVEL_BINDING)
        return result if obj.size == 1
        return obj[result ? 1 : 2] if result == !!result
        return obj[result + 1]
      when Integer
        if obj.size == 3
          return obj[$game_switches[obj[0]] ? 1 : 2]
        else
          return obj[$game_variables[obj[0]]]
        end
      else
        raise "must not happen"
      end
    else
      return obj
    end
  end
  private :_convert_value
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def name
    return _convert_value(@name)
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def help
    return _convert_value(@help)
  end
  alias description help
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def icon_index
    return _convert_value(@icon)
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def handler
    return :command_ok       if @scene
    return @command          if @command  && @command.is_a?(Symbol)
    return :command_ok       if @command
    return @personal         if @personal && @personal.is_a?(Symbol)
    return :command_personal if @personal
    return :command_sub      if @sub
    raise "must not happen"
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def exec
    #
    # ここでエラーが発生した場合、項目の設定が間違っている可能性があります。
    # 項目処理の設定を確認してください。
    #
    # エラーメッセージを確認の上、設定を修正してください。
    # つづり間違いや文法が間違っている可能性があります。
    #
    if @scene
      case @scene
      when Class
        return SceneManager.call(@scene.untaint)
      when Symbol
        return SceneManager.call(Kernel.const_get(@scene).untaint)
      when String
        return SceneManager.call(eval(@scene, ::TOPLEVEL_BINDING).untaint)
      end
    else
      command = @command || @personal
      case command
      when Class
        return SceneManager.call(command.untaint)
      when String
        return SceneManager.scene.instance_eval(command)
      end
    end
    raise "must not happen"
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def hide?
    #
    # ここでエラーが発生した場合、項目の設定が間違っている可能性があります。
    # オプションの :hide の設定を確認してください。
    #
    case @hide
    when true, false
      return @hide
    when String
      return eval(@hide, ::TOPLEVEL_BINDING)
    else
      raise "must not happen"
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def personal?
    return !@personal.nil?
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def refresh?
    return !@refresh_items.empty?
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def switch?
    return @sw_sub
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def auto_close?
    return @auto_close
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def continue?
    return @continue
  end
end

class Scene_Menu::Game_Interpreter < Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  undef command_101         # 文章の表示
  undef command_102         # 選択肢の表示
  undef command_103         # 数値入力の処理
  undef command_104         # アイテム選択の処理
  undef command_105         # スクロール文章の表示
  undef command_201         # 場所移動
  undef command_204         # マップのスクロール
  undef command_205         # 移動ルートの設定
  undef command_217         # 隊列メンバーの集合
  undef command_261         # ムービーの再生
  undef command_301         # バトルの処理
  undef command_351         # メニュー画面を開く
end

class Scene_Menu
  #--------------------------------------------------------------------------
  # ○ 開始処理
  #--------------------------------------------------------------------------
  def start
    super
    if CAO::CM::START_COMMON_ID > 0
      start_common_event(CAO::CM::START_COMMON_ID)
    end
    @caller = []
    create_command_window
    create_status_window
    create_option_window
  end
  #--------------------------------------------------------------------------
  # ○ フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    update_backimage
    update_command_window
    update_status_window
    update_option_window
  end
  #--------------------------------------------------------------------------
  # ○ 終了前処理
  #--------------------------------------------------------------------------
  def pre_terminate
    super
    if CAO::CM::TERMINATE_COMMON_ID > 0
      start_common_event(CAO::CM::TERMINATE_COMMON_ID)
    end
  end
  #--------------------------------------------------------------------------
  # ○ 終了処理
  #--------------------------------------------------------------------------
  def terminate
    super
    dispose_command_window
    dispose_status_window
    dispose_option_window
  end
  #--------------------------------------------------------------------------
  # ○ 背景の作成
  #--------------------------------------------------------------------------
  def create_background
    if CAO::CM::FILE_BACKGROUND
      @background_sprite = Sprite.new
      @background_sprite.bitmap = Cache.system(CAO::CM::FILE_BACKGROUND)
    else
      super
    end
    if CAO::CM::BACKIMAGE
      @backimage_sprite = Plane.new
      @backimage_sprite.bitmap = Cache.system(CAO::CM::BACKIMAGE[0])
      @backimage_sprite.z = -1 if CAO::CM::BACKIMAGE[3]
    end
    if CAO::CM::FILE_FOREGROUND
      @foreground_sprite = Sprite.new
      @foreground_sprite.z = 1000
      @foreground_sprite.bitmap = Cache.system(CAO::CM::FILE_FOREGROUND)
    end
  end
  #--------------------------------------------------------------------------
  # ○ 背景の解放
  #--------------------------------------------------------------------------
  def dispose_background
    super
    @backimage_sprite.dispose if @backimage_sprite
    @foreground_sprite.dispose if @foreground_sprite
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def update_backimage
    return unless @backimage_sprite
    return unless CAO::CM::BACKIMAGE[1] && CAO::CM::BACKIMAGE[2]
    @backimage_sprite.ox = (@backimage_sprite.ox - CAO::CM::BACKIMAGE[1]) % 999
    @backimage_sprite.oy = (@backimage_sprite.oy - CAO::CM::BACKIMAGE[2]) % 999
  end
  #--------------------------------------------------------------------------
  # ● コマンドウィンドウの作成
  #--------------------------------------------------------------------------
  def create_command_window
    # Do Nothing
  end
  #--------------------------------------------------------------------------
  # ● ステータスウィンドウの作成
  #--------------------------------------------------------------------------
  def create_status_window
    # Do Nothing
  end
  #--------------------------------------------------------------------------
  # ● オプションウィンドウの作成
  #--------------------------------------------------------------------------
  def create_option_window
    # Do Nothing
  end
  #--------------------------------------------------------------------------
  # ● コマンドウィンドウの更新
  #--------------------------------------------------------------------------
  def update_command_window
    # Do Nothing
  end
  #--------------------------------------------------------------------------
  # ● ステータスウィンドウの更新
  #--------------------------------------------------------------------------
  def update_status_window
    # Do Nothing
  end
  #--------------------------------------------------------------------------
  # ● オプションウィンドウの更新
  #--------------------------------------------------------------------------
  def update_option_window
    # Do Nothing
  end
  #--------------------------------------------------------------------------
  # ● コマンドウィンドウの解放
  #--------------------------------------------------------------------------
  def dispose_command_window
    # Do Nothing
  end
  #--------------------------------------------------------------------------
  # ● ステータスウィンドウの解放
  #--------------------------------------------------------------------------
  def dispose_status_window
    # Do Nothing
  end
  #--------------------------------------------------------------------------
  # ● オプションウィンドウの解放
  #--------------------------------------------------------------------------
  def dispose_option_window
    # Do Nothing
  end
  #--------------------------------------------------------------------------
  # ● コモンイベント予約判定
  #    イベントの呼び出しが予約されているならマップ画面へ遷移する。
  #--------------------------------------------------------------------------
  def check_common_event
    SceneManager.goto(Scene_Map) if $game_temp.common_event_reserved?
  end
  #--------------------------------------------------------------------------
  # ● コモンベントの実行
  #--------------------------------------------------------------------------
  def start_common_event(common_event_id)
    if @status_window && @status_window.index >= 0
      $game_party.menu_actor = $game_party.members[@status_window.index]
    end
    interpreter = Scene_Menu::Game_Interpreter.new
    interpreter.setup($data_common_events[common_event_id].list)
    interpreter.update while interpreter.running?
  end
  #--------------------------------------------------------------------------
  # ● 現在アクティブなコマンドウィンドウ
  #--------------------------------------------------------------------------
  def current_console
    @caller.last || @command_window
  end
  #--------------------------------------------------------------------------
  # ● 以前操作していたコマンドウィンドウ
  #--------------------------------------------------------------------------
  def previous_console
    @caller[-2] || @command_window
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def change_console(console)
    @caller << console
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def return_console
    current_console.deactivate.close
    previous_console.activate.open
    @caller.pop
  end
  #--------------------------------------------------------------------------
  # ● コマンド実行後の処理
  #--------------------------------------------------------------------------
  def post_terminate
    item = current_console.current_data
    current_console.activate if !current_console.locked?
  end
  #--------------------------------------------------------------------------
  # ● コマンド [決定]
  #--------------------------------------------------------------------------
  def command_ok
    current_console.current_exec
    post_terminate
    check_common_event
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def command_sub
    if current_console == @subcommand_window
      raise CustomizeError, "サブコマンドからは呼び出せません。"
    end
    @command_window.close if @command_window.current_data.switch?
    symbol = @command_window.current_data.sub
    @subcommand_window.init_command(symbol)
    @subcommand_window.clear_handler
    @subcommand_window.set_handler(:cancel, method(:return_console))
    @subcommand_window.set_handlers(self)
    change_console(@subcommand_window)
    open_sub_command
  end
  #--------------------------------------------------------------------------
  # ○ コマンド［スキル］［装備］［ステータス］
  #--------------------------------------------------------------------------
  def command_personal
    @status_window.select_last
    @status_window.activate
    @status_window.set_handler(:ok,     method(:on_personal_ok))
    @status_window.set_handler(:cancel, method(:on_personal_cancel))
    current_console.close if current_console.current_data.auto_close?
  end
  #--------------------------------------------------------------------------
  # ○ 個人コマンド [決定]
  #--------------------------------------------------------------------------
  def on_personal_ok
    command_ok
    if current_console.current_data.continue?
      current_console.deactivate
      @status_window.activate
    end
  end
  #--------------------------------------------------------------------------
  # ○ 個人コマンド［終了］
  #--------------------------------------------------------------------------
  def on_personal_cancel
    @status_window.unselect
    current_console.activate.open
  end
  #--------------------------------------------------------------------------
  # ○ 並び替え［キャンセル］
  #--------------------------------------------------------------------------
  def on_formation_cancel
    if @status_window.pending_index >= 0
      @status_window.pending_index = -1
      @status_window.activate
    else
      @status_window.unselect
      current_console.activate.open
    end
  end
  #--------------------------------------------------------------------------
  # ● サブコマンドウィンドウを開く
  #--------------------------------------------------------------------------
  def open_sub_command
    return if scene_changing?
    @subcommand_window.activate.open
  end
  #--------------------------------------------------------------------------
  # ● サブコマンドウィンドウを閉じる
  #--------------------------------------------------------------------------
  def close_sub_command
    @subcommand_window.deactivate.close
  end
end

module CustomMenuCommand
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(ident)
    @ident = ident
    super()
    unlock
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def init_command(ident)
    @ident = ident
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def current_commands
    CAO::CM::COMMANDS[@ident]
  end
  #--------------------------------------------------------------------------
  # ● 項目数の取得
  #--------------------------------------------------------------------------
  def item_max
    @list.size
  end
  #--------------------------------------------------------------------------
  # ● コマンドリストのクリア
  #--------------------------------------------------------------------------
  def clear_command_list
    @list = []
  end
  #--------------------------------------------------------------------------
  # ● コマンドリストの作成
  #--------------------------------------------------------------------------
  def make_command_list
    return unless @ident
    unless current_commands
      raise CustomizeError,
        "識別子 :#{@ident} のメニューコマンドの設定がありません。(COMMANDS)"
    end
    current_commands.each do |symbol|
      unless CAO::CM::COMMAND_ITEMS[symbol]
        puts "識別子 :#{symbol} の項目の設定がありません。(COMMAND_ITEMS)"
        next
      end
      item = Game_MenuItem.new(symbol, CAO::CM::COMMAND_ITEMS[symbol])
      @list << item unless item.hide?
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def lock
    @locked = true
    self
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def unlock
    @locked = false
    self
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def locked?
    @locked
  end
  #--------------------------------------------------------------------------
  # ● コマンドの有効状態を取得
  #--------------------------------------------------------------------------
  def command_enabled?(index)
    param = @list[index].enable
    return false if @list[index].personal? && !$game_party.exists
    return true if param == true
    return false if param == false
    return eval(param.to_s) if param.is_a?(Symbol) || param.is_a?(String)
    raise "must not happen"
  end
  #--------------------------------------------------------------------------
  # ● コマンド名の取得
  #--------------------------------------------------------------------------
  def command_name(index)
    @list[index].name
  end
  #--------------------------------------------------------------------------
  # ● コマンドアイコン番号の取得
  #--------------------------------------------------------------------------
  def command_icon_index(index)
    return @list[index].icon_index
  end
  #--------------------------------------------------------------------------
  # ● 選択項目のコマンドデータを取得
  #--------------------------------------------------------------------------
  def current_data
    index >= 0 ? @list[index] : nil
  end
  #--------------------------------------------------------------------------
  # ● 選択項目の有効状態を取得
  #--------------------------------------------------------------------------
  def current_item_enabled?
    index >= 0 ? command_enabled?(index) : false
  end
  #--------------------------------------------------------------------------
  # ● 選択項目のシンボルを取得
  #--------------------------------------------------------------------------
  def current_symbol
    current_data ? current_data.symbol : nil
  end
  #--------------------------------------------------------------------------
  # ● 選択項目のインデックスを取得
  #--------------------------------------------------------------------------
  def current_index
    @list.index {|item| item.symbol == current_symbol }
  end
  #--------------------------------------------------------------------------
  # ● 選択項目の実行
  #--------------------------------------------------------------------------
  def current_exec
    current_data.exec
  end
  #--------------------------------------------------------------------------
  # ● 指定されたシンボルを持つコマンドにカーソルを移動
  #--------------------------------------------------------------------------
  def select_symbol(symbol)
    @list.each_index {|i| select(i) if @list[i].symbol == symbol }
  end
  #--------------------------------------------------------------------------
  # ● ハンドラのクリア
  #--------------------------------------------------------------------------
  def clear_handler
    @handler = {}
  end
  #--------------------------------------------------------------------------
  # ● 動作に対応するハンドラの設定
  #--------------------------------------------------------------------------
  def set_handlers(obj)
    #
    # ここでエラーが発生した場合、項目の設定が間違っている可能性があります。
    # 項目処理の設定を確認してください。
    #
    # NameError : undefined method `○○' for class `Scene_Menu'
    #   つづりが間違っていないか確認してください。
    # 
    # NameError : undefined method `command_sub' for class `Scene_Menu'
    #  『サブコマンド』スクリプトが未導入の可能性があります。
    # 
    @list.each {|cmd| @handler[cmd.symbol] = obj.method(cmd.handler) }
  end
end

class Window_CustomMenuCommand < Window_MenuCommand
  include CustomMenuCommand
  #--------------------------------------------------------------------------
  # ● ウィンドウ内容の幅を計算
  #--------------------------------------------------------------------------
  def contents_width
    (item_width + spacing) * col_max - spacing
  end
  #--------------------------------------------------------------------------
  # ● 行の高さを取得
  #--------------------------------------------------------------------------
  def line_height
    if CAO::CM::COMMAND_HEIGHT == 0
      return default_font_size
    else
      return CAO::CM::COMMAND_HEIGHT
    end
  end
  #--------------------------------------------------------------------------
  # ● 横に項目が並ぶときの空白の幅を取得
  #--------------------------------------------------------------------------
  def spacing
    return 8
  end
  #--------------------------------------------------------------------------
  # ● 初期フォントサイズ
  #--------------------------------------------------------------------------
  def default_font_size
    return Font.default_size if CAO::CM::COMMAND_SIZE == 0
    return CAO::CM::COMMAND_SIZE
  end
  #--------------------------------------------------------------------------
  # ● フォントサイズのリセット
  #--------------------------------------------------------------------------
  def reset_font_size
    contents.font.size = default_font_size
  end
  #--------------------------------------------------------------------------
  # ● カーソルを下に移動
  #--------------------------------------------------------------------------
  def cursor_down(wrap = false)
    if index < item_max - col_max || (wrap && col_max == 1)
      select((index + col_max) % item_max)
    elsif col_max != 1 && index < (item_max.to_f/col_max).ceil*col_max-col_max
      select(item_max - 1)
    end
  end
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #--------------------------------------------------------------------------
  def draw_item(index)
    rect = item_rect(index)
    enabled = command_enabled?(index)
    if command_icon_index(index)
      draw_icon(command_icon_index(index), rect.x, rect.y, enabled)
      rect.x += 26
      rect.width -= 28
    else
      rect.x += 4
      rect.width -= 8
    end
    change_color(normal_color, enabled)
    draw_text(rect, command_name(index), alignment)
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    reset_font_size
    draw_all_items
  end
end

class Sprite_CustomMenuCursor < Sprite
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def initialize(data, viewport = nil)
    super(viewport)
    @filename     = data[0]
    @distance_x   = data[1] || 1
    @distance_y   = data[2] || 1
    @view_behind  = data[3] || data[3] == nil
    @flash_amount = data[4] || 0
    
    self.bitmap = Cache.system(@filename)
    self.z = @view_behind ? -1 : 1
    self.ox = self.bitmap.width / 2
    self.oy = self.bitmap.height / 2
    self.opacity = 0
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def update
    super
    update_flash
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def update_flash
    return if @flash_amount == 0
    last_opacity = self.opacity
    self.opacity += @flash_amount
    @flash_amount *= -1 if self.opacity == last_opacity
  end
end

class Spriteset_CustomMenuCommand
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  OPEN_SPEED = 16
  #--------------------------------------------------------------------------
  # ● クラスインスタンス変数
  #--------------------------------------------------------------------------
  class << self
    attr_accessor :last_command_symbol    # カーソル位置 保存用
  end
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :index
  attr_reader   :openness
  attr_reader   :help_window              # ヘルプウィンドウ
  attr_accessor :x
  attr_accessor :y
  attr_accessor :viewport
  attr_accessor :visible
  attr_accessor :active
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    @handler = {}
    @index = -1
    @x = 0
    @y = 0
    @visible = true
    @active = false
    @openness = 255     # 変更は self.openness で行なう
    @opening = false
    @closing = false
  end
  #--------------------------------------------------------------------------
  # ● 項目数の取得 (要再定義)
  #--------------------------------------------------------------------------
  def item_max
    return 0
  end
  #--------------------------------------------------------------------------
  # ● コマンド名の取得 (要再定義)
  #--------------------------------------------------------------------------
  def command_name(index)
    return ""
  end
  #--------------------------------------------------------------------------
  # ● コマンドファイル名 (要再定義)
  #--------------------------------------------------------------------------
  def command_filename
    return ""
  end
  #--------------------------------------------------------------------------
  # ● コマンド総数の取得 (要再定義)
  #--------------------------------------------------------------------------
  def command_max
    return 0
  end
  #--------------------------------------------------------------------------
  # ● カーソルデータの取得
  #--------------------------------------------------------------------------
  def cursor_data
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def dispose
    dispose_command_sprites
    dispose_cursor_sprite
  end
  #--------------------------------------------------------------------------
  # ● スプライトの表示
  #--------------------------------------------------------------------------
  def show
    self.visible = true
    self
  end
  #--------------------------------------------------------------------------
  # ● スプライトの非表示
  #--------------------------------------------------------------------------
  def hide
    self.visible = false
    self
  end
  #--------------------------------------------------------------------------
  # ● スプライトのアクティブ化
  #--------------------------------------------------------------------------
  def activate
    self.active = true
    self
  end
  #--------------------------------------------------------------------------
  # ● スプライトの非アクティブ化
  #--------------------------------------------------------------------------
  def deactivate
    self.active = false
    self
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def openness=(value)
    @openness = value
    update_openness
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウを開く
  #--------------------------------------------------------------------------
  def open
    @opening = true unless open?
    @closing = false
    self
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウを閉じる
  #--------------------------------------------------------------------------
  def close
    @closing = true unless close?
    @opening = false
    self
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def open?
    @openness = 255 if @openness > 255
    return @openness == 255
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def close?
    @openness = 0 if @openness < 0
    return @openness == 0
  end
  #--------------------------------------------------------------------------
  # ● 開く処理の更新
  #--------------------------------------------------------------------------
  def update_open
    @openness += OPEN_SPEED
    @opening = false if open?
  end
  #--------------------------------------------------------------------------
  # ● 閉じる処理の更新
  #--------------------------------------------------------------------------
  def update_close
    @openness -= OPEN_SPEED
    @closing = false if close?
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def visible=(value)
    @visible = value
    @cursor_sprite.visible = value if @cursor_sprite
  end
  #--------------------------------------------------------------------------
  # ● カーソル位置の設定
  #--------------------------------------------------------------------------
  def index=(index)
    @index = index
    refresh
    call_update_help
  end
  #--------------------------------------------------------------------------
  # ● 項目の選択
  #--------------------------------------------------------------------------
  def select(index)
    self.index = index if index && @index != index
  end
  #--------------------------------------------------------------------------
  # ● 項目の選択解除
  #--------------------------------------------------------------------------
  def unselect
    self.index = -1
  end
  #--------------------------------------------------------------------------
  # ● 前回の選択位置を復帰
  #--------------------------------------------------------------------------
  def select_last
    select_symbol(self.class.last_command_symbol)
  end
  #--------------------------------------------------------------------------
  # ● 項目の選択位置を記憶
  #--------------------------------------------------------------------------
  def save_command_position
    self.class.last_command_symbol = current_symbol
  end
  #--------------------------------------------------------------------------
  # ● 前回の選択位置を削除
  #--------------------------------------------------------------------------
  def init_command_position
    self.class.last_command_symbol = nil
  end
  #--------------------------------------------------------------------------
  # ● 動作に対応するハンドラの設定
  #     method : ハンドラとして設定するメソッド (Method オブジェクト)
  #--------------------------------------------------------------------------
  def set_handler(symbol, method)
    @handler[symbol] = method
  end
  #--------------------------------------------------------------------------
  # ● ハンドラの存在確認
  #--------------------------------------------------------------------------
  def handle?(symbol)
    @handler.include?(symbol)
  end
  #--------------------------------------------------------------------------
  # ● ハンドラの呼び出し
  #--------------------------------------------------------------------------
  def call_handler(symbol)
    @handler[symbol].call if handle?(symbol)
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    update_cursor_sprite
    update_command_sprites
    update_openness
    process_cursor_move
    process_handling
  end
  #--------------------------------------------------------------------------
  # ● 開閉更新
  #--------------------------------------------------------------------------
  def update_openness
    return unless @command_sprites
    update_open  if @opening
    update_close if @closing
    @command_sprites.each {|sp| sp.opacity = @openness }
  end
  #--------------------------------------------------------------------------
  # ● カーソルの移動処理
  #--------------------------------------------------------------------------
  def process_cursor_move
    return unless cursor_movable?
    last_index = @index
    cursor_down (Input.trigger?(:DOWN))  if Input.repeat?(:DOWN)
    cursor_up   (Input.trigger?(:UP))    if Input.repeat?(:UP)
    cursor_right(Input.trigger?(:RIGHT)) if Input.repeat?(:RIGHT)
    cursor_left (Input.trigger?(:LEFT))  if Input.repeat?(:LEFT)
    cursor_pagedown   if !handle?(:pagedown) && Input.trigger?(:R)
    cursor_pageup     if !handle?(:pageup)   && Input.trigger?(:L)
    Sound.play_cursor if @index != last_index
  end
  #--------------------------------------------------------------------------
  # ● 決定やキャンセルなどのハンドリング処理
  #--------------------------------------------------------------------------
  def process_handling
    return unless active
    return process_ok     if Input.trigger?(:C)
    return process_cancel if Input.trigger?(:B)
  end
  #--------------------------------------------------------------------------
  # ● カーソルの移動可能判定
  #--------------------------------------------------------------------------
  def cursor_movable?
    active && item_max > 0
  end
  #--------------------------------------------------------------------------
  # ● カーソルを下に移動
  #--------------------------------------------------------------------------
  def cursor_down(wrap = false)
    if @index + cursor_dy >= 0 && @index + cursor_dy < item_max || wrap
      select((@index + cursor_dy) % item_max)
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルを上に移動
  #--------------------------------------------------------------------------
  def cursor_up(wrap = false)
    if @index - cursor_dy >= 0 && @index - cursor_dy < item_max || wrap
      select((@index - cursor_dy) % item_max)
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルを右に移動
  #--------------------------------------------------------------------------
  def cursor_right(wrap = false)
    if @index + cursor_dx >= 0 && @index + cursor_dx < item_max || wrap
      select((@index + cursor_dx) % item_max)
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルを左に移動
  #--------------------------------------------------------------------------
  def cursor_left(wrap = false)
    if @index - cursor_dx >= 0 && @index - cursor_dx < item_max || wrap
      select((@index - cursor_dx) % item_max)
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルを 1 ページ後ろに移動
  #--------------------------------------------------------------------------
  def cursor_pagedown
    # Do Nothing
  end
  #--------------------------------------------------------------------------
  # ● カーソルを 1 ページ前に移動
  #--------------------------------------------------------------------------
  def cursor_pageup
    # Do Nothing
  end
  #--------------------------------------------------------------------------
  # ● 決定ボタンが押されたときの処理
  #--------------------------------------------------------------------------
  def process_ok
    save_command_position
    if current_item_enabled?
      Sound.play_ok
      Input.update
      deactivate
      if handle?(current_symbol)
        call_handler(current_symbol)
      elsif handle?(:ok)
        call_handler(:ok)
      else
        activate
      end
    else
      Sound.play_buzzer
    end
  end
  #--------------------------------------------------------------------------
  # ● キャンセルボタンが押されたときの処理
  #--------------------------------------------------------------------------
  def process_cancel
    Sound.play_cancel
    Input.update
    deactivate
    call_handler(:cancel)
  end
  #--------------------------------------------------------------------------
  # ● ヘルプウィンドウの設定
  #--------------------------------------------------------------------------
  def help_window=(help_window)
    @help_window = help_window
    call_update_help
  end
  #--------------------------------------------------------------------------
  # ● ヘルプウィンドウ更新メソッドの呼び出し
  #--------------------------------------------------------------------------
  def call_update_help
    update_help if active && @help_window
  end
  #--------------------------------------------------------------------------
  # ● ヘルプウィンドウの更新
  #--------------------------------------------------------------------------
  def update_help
    @help_window.clear
  end
  #--------------------------------------------------------------------------
  # ● 主要コマンドの有効状態を取得
  #--------------------------------------------------------------------------
  def main_commands_enabled
    $game_party.exists
  end
  #--------------------------------------------------------------------------
  # ● 並び替えの有効状態を取得
  #--------------------------------------------------------------------------
  def formation_enabled
    $game_party.members.size >= 2 && !$game_system.formation_disabled
  end
  #--------------------------------------------------------------------------
  # ● セーブの有効状態を取得
  #--------------------------------------------------------------------------
  def save_enabled
    !$game_system.save_disabled
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def create_cursor_sprite
    unless cursor_data
      raise CustomizeError, "カーソルの情報が設定されていません。"
    end
    return unless cursor_data[0]
    return if cursor_data[0].empty?
    @cursor_sprite = Sprite_CustomMenuCursor.new(cursor_data, viewport)
    update_cursor_sprite
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def update_cursor_sprite
    return unless @cursor_sprite
    if !open? || !@visible
      @cursor_sprite.visible = false
    end
    if @active
      if @index < 0
        @cursor_sprite.visible = false
      else
        @cursor_sprite.visible = true
        @cursor_sprite.x = @command_sprites[@index].x
        @cursor_sprite.y = @command_sprites[@index].y
        @cursor_sprite.update
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def dispose_cursor_sprite
    return unless @cursor_sprite
    @cursor_sprite.dispose
  end
  #--------------------------------------------------------------------------
  # ● カーソル画像の取得
  #--------------------------------------------------------------------------
  def cursor_bitmap
    return nil unless cursor_data
    return nil if cursor_data[0].empty?
    return Cache.system(cursor_data[0])
  end
  #--------------------------------------------------------------------------
  # ● カーソルの移動量
  #--------------------------------------------------------------------------
  def cursor_dx
    return cursor_data[1]
  end
  #--------------------------------------------------------------------------
  # ● カーソルの移動量
  #--------------------------------------------------------------------------
  def cursor_dy
    return cursor_data[2]
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def item_rect(index)
    rect = Rect.new(0, 0, 0, 0)
    rect.x = @command_sprites[index].x
    rect.y = @command_sprites[index].y
    rect.width = @command_sprites[index].bitmap.width
    rect.height = @command_sprites[index].bitmap.height
    return rect
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def create_command_sprites
    @command_sprites = Array.new(item_max) do |i|
      sp = Sprite.new(viewport)
      sp.bitmap = Bitmap.new(image_width(i), image_height(i))
      sp.ox = sp.bitmap.width / 2
      sp.oy = sp.bitmap.height / 2
      yield(sp, i) if defined? yield
      sp
    end
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update_command_sprites
    return unless @command_sprites
    @command_sprites.each {|sp| sp.update }
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def dispose_command_sprites
    return unless @command_sprites
    @command_sprites.each do |sp|
      sp.bitmap.dispose
      sp.dispose
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def image_index(index)
    result = 0
    result += 1 if @index == index
    result += 2 unless command_enabled?(index)
    return result
  end
  #--------------------------------------------------------------------------
  # ● src_rect
  #--------------------------------------------------------------------------
  def image_rect(index)
    rect = @command_sprites[index].bitmap.rect
    if multi_image?
      cmd_index = current_commands.index(@list[index].symbol)
      rect.x = @command_sprites[index].bitmap.width * image_index(index) 
      rect.y = @command_sprites[index].bitmap.height * cmd_index
    else
      rect.x = 0
      rect.y = @command_sprites[index].bitmap.height * image_index(index)
    end
    return rect
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def refresh_command(index)
    bitmap = @command_sprites[index].bitmap
    bitmap.clear
    bitmap.blt(0, 0, command_image(index), image_rect(index))
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def refresh_commands
    @command_sprites.each_with_index do |sp, i|
      refresh_command(i)
      yield(sp, i) if defined? yield
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def command_image(index)
    if multi_image?
      Cache.system(command_filename)
    else
      Cache.system(command_name(index))
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def multi_image?
    return !command_filename.empty?
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def image_width(index)
    return command_image(index).width / 4 if multi_image?
    return command_image(index).width
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def image_height(index)
    return command_image(index).height / command_max if multi_image?
    return command_image(index).height / 4
  end
end

class Game_Actor
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :portrait_name            # 立ち絵 ファイル名
  #--------------------------------------------------------------------------
  # ● 立ち絵のファイル名を取得
  #--------------------------------------------------------------------------
  def portrait_name
    filename = @portrait_name ? @portrait_name : CAO::CM::PORTRAIT_NAME
    return sprintf(filename, self.id, self.expression_index)
  end
  #--------------------------------------------------------------------------
  # ● 顔グラ（表情）のインデックスを取得
  #--------------------------------------------------------------------------
  def face_expression_index
    index = CAO::CM::COLLECT_FACE ? @face_index - (@face_index % 4) : 0
    return index + self.expression_index
  end
  #--------------------------------------------------------------------------
  # ● 表情のインデックスを取得
  #--------------------------------------------------------------------------
  def expression_index
    rate = (self.hp_rate * 100).ceil
    index = CAO::CM::EXPRESSIVE_RATE.index {|r| r < rate }
    return index || CAO::CM::EXPRESSIVE_RATE.size
  end
  #--------------------------------------------------------------------------
  # ● 経験値の割合を取得
  #--------------------------------------------------------------------------
  def cm_exp_rate
    return 1.0 if max_level?
    return self.cm_accumulated_exp / self.cm_requisite_exp.to_f
  end
  #--------------------------------------------------------------------------
  # ● レベルアップに必要な経験値を取得
  #--------------------------------------------------------------------------
  def cm_requisite_exp
    return 0 if max_level?
    return self.next_level_exp - self.current_level_exp
  end
  #--------------------------------------------------------------------------
  # ● 獲得した経験値を取得 (現レベル)
  #--------------------------------------------------------------------------
  def cm_accumulated_exp
    return self.exp - self.current_level_exp
  end
  #--------------------------------------------------------------------------
  # ● レベルアップに必要な残りの経験値を取得
  #--------------------------------------------------------------------------
  def cm_remaining_exp
    return 0 if max_level?
    return self.next_level_exp - self.exp
  end
end

class CAO::CM::Canvas
  include CAO::CM
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader :window
  attr_reader :bitmap
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(obj)
    case obj
    when Window
      @window = obj
      @bitmap = obj.contents
    when Bitmap
      @window = nil
      @bitmap = obj
    else
      raise TypeError,
        "wrong argument type #{obj.class} (expected Bitmap or Window)"
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def contents
    return @window ? @window.contents : @bitmap
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def draw_actor_items(actor, x, y, list)
    #
    # メニューステータスの設定が間違っている可能性があります。
    # 表示項目の設定を確認してください。
    #
    # TypeError
    #   引数の型(数値や文字列など)が間違っています。
    #   設定がずれているかもしれません。
    #   設定は必ず [シンボル, 数値, 数値, ... ] の形で始まります。
    #   識別子とｘ座標とｙ座標の設定は省略できません。
    #
    # ArgumentError : wrong number of arguments
    #   引数の数が間違っています。
    #   オプション部分の設定に間違いがないか確認してください。
    #   
    list.each do |params|
      symbol = params[0]
      argv = params[1, params.size]
      xx, yy = argv[0], argv[1]
      unless METHODS_NAME[symbol]
        puts "識別子 :#{symbol} の処理は定義されていません。"
        next
      end
      unless xx && yy
        raise CustomizeError, "描画する座標が設定されていません。"
      end
      begin
        opt = (argv.size <= 2) ? [] : argv[2, argv.size - 2]
        eval("#{METHODS_NAME[symbol]}(actor, x + xx, y + yy, *opt)")
      rescue
        msg = "{ Actor(#{actor.respond_to?(:id)&&actor.id})  "
        msg << "Symbol(:#{symbol})  Method(#{METHODS_NAME[symbol]}) }\n"
        msg << $!.message
        raise $!, msg, $!.backtrace
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  METHODS_NAME = {}
  METHODS_NAME[:w_chara] = '@window.draw_actor_graphics'
  METHODS_NAME[:w_face]  = '@window.draw_actor_face'
  METHODS_NAME[:w_name]  = '@window.draw_actor_name'
  METHODS_NAME[:w_class] = '@window.draw_actor_class'
  METHODS_NAME[:w_nick]  = '@window.draw_actor_nickname'
  METHODS_NAME[:w_level] = '@window.draw_actor_level'
  METHODS_NAME[:w_state] = '@window.draw_actor_icons'
  METHODS_NAME[:w_hp]    = '@window.draw_actor_hp'
  METHODS_NAME[:w_mp]    = '@window.draw_actor_mp'
  METHODS_NAME[:w_tp]    = '@window.draw_actor_tp'
  
  if CAO::CM::EXPRESSIVE_RATE.empty?
    METHODS_NAME[:face] = :draw_actor_face
  else
    METHODS_NAME[:face] = :draw_actor_expression
  end
  METHODS_NAME[:chara] = :draw_actor_graphic
  METHODS_NAME[:name]  = :draw_actor_name
  METHODS_NAME[:class] = :draw_actor_class
  METHODS_NAME[:nick]  = :draw_actor_nickname
  METHODS_NAME[:level] = :draw_actor_level
  METHODS_NAME[:lv_g]  = :draw_actor_level_g
  METHODS_NAME[:state] = :draw_actor_icons
  METHODS_NAME[:hp]    = :draw_actor_hp
  METHODS_NAME[:mp]    = :draw_actor_mp
  METHODS_NAME[:tp]    = :draw_actor_tp
  METHODS_NAME[:exp]   = :draw_actor_exp
  METHODS_NAME[:param] = :draw_actor_param
  METHODS_NAME[:icon]  = :draw_actor_icon
  METHODS_NAME[:bust]  = :draw_actor_portrait
  METHODS_NAME[:fill]  = :draw_actor_rect
  METHODS_NAME[:pict]  = :draw_actor_picture
  METHODS_NAME[:text]  = :draw_actor_text
  METHODS_NAME[:num]   = :draw_actor_number
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  COLOR_AIB_1 = Color.new(0, 0, 0)          # アクターアイコンの縁の色
  COLOR_AIB_2 = Color.new(255, 255, 255)    # アクターアイコンの背景色
  #--------------------------------------------------------------------------
  # ● 行の高さを取得
  #--------------------------------------------------------------------------
  def line_height
    return 24
  end
  #--------------------------------------------------------------------------
  # ● 半透明描画用のアルファ値を取得
  #--------------------------------------------------------------------------
  def translucent_alpha
    return 160
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def str2color(value)
    case value
    when Color
      return value
    when Array
      return Color.new(*value)
    when Integer
      num = value
    when Symbol, String
      text = value.to_s.sub(/^(0x|x)/, "")
      case text.size
      when 1; text = text * 6 << 'FF'
      when 2; text = text[0] * 6 << text[1] * 2
      when 3; text = text[0] * 2 << text[1] * 2 << text[2] * 2 << 'FF'
      when 4; text = text[0] * 2 << text[1] * 2 << text[2] * 2 << text[3] * 2
      when 6; text = text[0, 6] << 'FF'
      end
      num = eval("0x#{text}")
    end
    return Color.new(num >> 24, num >> 16 & 255, num >> 8 & 255, num & 255)
  end
  #--------------------------------------------------------------------------
  # ● 文字色取得
  #     n : 文字色番号（0..31）
  #--------------------------------------------------------------------------
  def text_color(n, enabled = true)
    color = Cache.system("Window").get_pixel(64+(n%8)*8, 96+(n/8)*8)
    color.alpha = translucent_alpha unless enabled
    return color
  end
  #--------------------------------------------------------------------------
  # ● 各種文字色の取得
  #--------------------------------------------------------------------------
  def normal_color;      text_color(0);   end;    # 通常
  def system_color;      text_color(16);  end;    # システム
  def crisis_color;      text_color(17);  end;    # ピンチ
  def knockout_color;    text_color(18);  end;    # 戦闘不能
  def gauge_back_color;  text_color(19);  end;    # ゲージ背景
  def hp_gauge_color1;   text_color(20);  end;    # HP ゲージ 1
  def hp_gauge_color2;   text_color(21);  end;    # HP ゲージ 2
  def mp_gauge_color1;   text_color(22);  end;    # MP ゲージ 1
  def mp_gauge_color2;   text_color(23);  end;    # MP ゲージ 2
  def mp_cost_color;     text_color(23);  end;    # 消費 MP
  def power_up_color;    text_color(24);  end;    # 装備 パワーアップ
  def power_down_color;  text_color(25);  end;    # 装備 パワーダウン
  def tp_gauge_color1;   text_color(28);  end;    # TP ゲージ 1
  def tp_gauge_color2;   text_color(29);  end;    # TP ゲージ 2
  def tp_cost_color;     text_color(29);  end;    # 消費 TP
  def exp_gauge_color1;  text_color(30);  end;    # EXP ゲージ 1
  def exp_gauge_color2;  text_color(31);  end;    # EXP ゲージ 2
  #--------------------------------------------------------------------------
  # ● 保留項目の背景色を取得
  #--------------------------------------------------------------------------
  def pending_color
    Cache.system("Window").get_pixel(80, 80)
  end
  #--------------------------------------------------------------------------
  # ● テキスト描画色の変更
  #--------------------------------------------------------------------------
  def change_color(color, enabled = true)
    if block_given?
      last_color = self.contents.font.color.dup
      change_color(color, enabled)
      yield
      self.contents.font.color = last_color
    else
      self.contents.font.color.set(color)
      self.contents.font.color.alpha = translucent_alpha unless enabled
    end
  end
  #--------------------------------------------------------------------------
  # ● テキストサイズの変更
  #--------------------------------------------------------------------------
  def change_size(size)
    if block_given?
      last_size = self.contents.font.size
      change_size(size)
      yield
      self.contents.font.size = last_size
    else
      self.contents.font.size = size
    end
  end
  #--------------------------------------------------------------------------
  # ● テキストの描画
  #--------------------------------------------------------------------------
  def draw_text(*args)
    contents.draw_text(*args)
  end
  #--------------------------------------------------------------------------
  # ● テキストサイズの取得
  #--------------------------------------------------------------------------
  def text_size(str)
    contents.text_size(str)
  end
  #--------------------------------------------------------------------------
  # ● 制御文字つきテキストの描画
  #--------------------------------------------------------------------------
  def draw_text_ex(x, y, text)
    reset_font_settings
    text = convert_escape_characters(text)
    pos = {:x => x, :y => y, :new_x => x, :height => calc_line_height(text)}
    process_character(text.slice!(0, 1), text, pos) until text.empty?
  end
  #--------------------------------------------------------------------------
  # ● フォント設定のリセット
  #--------------------------------------------------------------------------
  def reset_font_settings
    change_color(normal_color)
    contents.font.size = Font.default_size
    contents.font.bold = Font.default_bold
    contents.font.italic = Font.default_italic
  end
  #--------------------------------------------------------------------------
  # ● 制御文字の事前変換
  #    実際の描画を始める前に、原則として文字列に変わるものだけを置き換える。
  #    文字「\」はエスケープ文字（\e）に変換。
  #--------------------------------------------------------------------------
  def convert_escape_characters(text)
    result = text.to_s.clone
    result.gsub!(/\r\n/)          { "\n" }
    result.gsub!(/\\/)            { "\e" }
    result.gsub!(/\e\e/)          { "\\" }
    result.gsub!(/\e({+)/i)       { "\e{" * $1.count("{") }
    result.gsub!(/\e(}+)/i)       { "\e}" * $1.count("}") }
    result.gsub!(/\eV\[(\d+)\]/i) { $game_variables[$1.to_i] }
    result.gsub!(/\eV\[(\d+)\]/i) { $game_variables[$1.to_i] }
    result.gsub!(/\eS\[(\d+),(.*?),(.*?)\]/i) { $game_switches[$1.to_i]?$2:$3 }
    result.gsub!(/\eN\[(\d+)\]/i) { actor_name($1.to_i) }
    result.gsub!(/\eP\[(\d+)\]/i) { party_member_name($1.to_i) }
    result.gsub!(/\eG/i)          { Vocab::currency_unit }
    result.gsub!(/\e\$/)          { $game_party.gold }
    result.gsub!(/\eW/)           { $game_party.steps }
    result.gsub!(/\eT\[(.+?)\]/i) { play_time($1) }
    result.gsub!(/\eT/i)          { play_time }
    result.gsub!(/\en/)           { "\n" }
    result.gsub!(/<%(.*?)%>/)     { eval($1) }
    result
  end
  #--------------------------------------------------------------------------
  # ● アクター n 番の名前を取得
  #--------------------------------------------------------------------------
  def actor_name(n)
    actor = n >= 1 ? $game_actors[n] : nil
    actor ? actor.name : ""
  end
  #--------------------------------------------------------------------------
  # ● パーティメンバー n 番の名前を取得
  #--------------------------------------------------------------------------
  def party_member_name(n)
    actor = n >= 1 ? $game_party.members[n - 1] : nil
    actor ? actor.name : ""
  end
  #--------------------------------------------------------------------------
  # ● プレイ時間を取得
  #--------------------------------------------------------------------------
  def play_time(format = '%3d:%02d:%02d')
    total = Graphics.frame_count / Graphics.frame_rate
    return sprintf(format,
      (total / 3600), (total / 60 % 60), (total % 60), (total / 60), total)
  end
  #--------------------------------------------------------------------------
  # ● 文字の処理
  #     c    : 文字
  #     text : 描画処理中の文字列バッファ（必要なら破壊的に変更）
  #     pos  : 描画位置 {:x, :y, :new_x, :height}
  #--------------------------------------------------------------------------
  def process_character(c, text, pos)
    case c
    when "\n"   # 改行
      process_new_line(text, pos)
    when "\e"   # 制御文字
      process_escape_character(obtain_escape_code(text), text, pos)
    else        # 普通の文字
      process_normal_character(c, pos)
    end
  end
  #--------------------------------------------------------------------------
  # ● 通常文字の処理
  #--------------------------------------------------------------------------
  def process_normal_character(c, pos)
    text_width = text_size(c).width
    draw_text(pos[:x], pos[:y], text_width * 2, pos[:height], c)
    pos[:x] += text_width
  end
  #--------------------------------------------------------------------------
  # ● 改行文字の処理
  #--------------------------------------------------------------------------
  def process_new_line(text, pos)
    pos[:x] = pos[:new_x]
    pos[:y] += pos[:height]
    pos[:height] = calc_line_height(text)
  end
  #--------------------------------------------------------------------------
  # ● 制御文字の本体を破壊的に取得
  #--------------------------------------------------------------------------
  def obtain_escape_code(text)
    text.slice!(/^[\$\.\|\^!><\{\}\\]|^[A-Z]+/i)
  end
  #--------------------------------------------------------------------------
  # ● 制御文字の引数を破壊的に取得
  #--------------------------------------------------------------------------
  def obtain_escape_param(text)
    text.slice!(/^\[-?\d+\]/)[/-?\d+/].to_i rescue 0
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def obtain_escape_value(text, value)
    text.slice!(/^\[([+-]?)(\d+)\]/i)
    return value + $2.to_i if $1 == '+'
    return value - $2.to_i if $1 == '-'
    return $2.to_i
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def obtain_escape_picparam(text)
    return [] unless text.slice!(/^\[(.+?)\]/)
    params = $1.split(',')
    params.each {|s| s.strip! }
    return params
  end
  #--------------------------------------------------------------------------
  # ● 制御文字の処理
  #     code : 制御文字の本体部分（「\C[1]」なら「C」）
  #--------------------------------------------------------------------------
  def process_escape_character(code, text, pos)
    case code.upcase
    when 'C'
      change_color(text_color(obtain_escape_param(text)))
    when 'I'
      if text[/^\[\d+\]/]
        process_draw_icon(obtain_escape_param(text), pos)
      else
        process_draw_picture(obtain_escape_picparam(text))
      end
    when 'P'
      process_draw_picture(obtain_escape_picparam(text))
    when 'F'
      process_draw_face(obtain_escape_picparam(text))
    when '{'
      make_font_bigger
    when '}'
      make_font_smaller
    when 'X'
      pos[:x] = obtain_escape_value(text, pos[:x])
    when 'Y'
      pos[:y] = obtain_escape_value(text, pos[:y])
    when 'L'
      process_draw_line(text, pos)
    end
  end
  #--------------------------------------------------------------------------
  # ● 制御文字によるライン描画の処理
  #--------------------------------------------------------------------------
  def process_draw_line(text, pos)
    if text.slice!(/^\[(\d+)\s*,\s*(\d+)(?:\s*,\s*([AFHTMBXS]+))?\]/i)
      x, y, w, h, params = pos[:x], pos[:y], $1.to_i, $2.to_i, ($3 || "")
      # 描画幅を文字サイズから (A:自動,F:全角,H:半角)
      case params
      when /A/i; w = text_size(text[0, w]).width
      when /F/i; w = text_size("　" * w).width
      when /H/i; w = text_size(" " * w).width
      end
      # 線の描画位置 (t:上,m:中,b:下, デフォルトは下)
      unless params[/T/i]
        if params[/M/i]
          y += (pos[:height] + h) / 2 
        else
          y += pos[:height] - h
        end
      end
      # 影の描画
      if params[/S/i]
        w -= 1
        color = gauge_back_color
        color.alpha = translucent_alpha
        self.contents.fill_rect(x + 1, y + 1, w, h, color)
      end
      # 線の描画
      self.contents.fill_rect(x, y, w, h, self.contents.font.color)
      # ｘ座標を進める
      x += w if params[/X/i]
    elsif text.slice!(/^\[([0-9, ]+?)(0x[0-9A-F]+)?\]/i)
      color = $2
      param = $1.sub(/, *$/, '').split(',').map {|s| s.to_i }
      if param.is_a?(Array) && param.size == 4
        if color
          draw_fill_rect(*param, str2color(color))
        else
          self.contents.fill_rect(*param, self.contents.font.color)
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 制御文字によるアイコン描画の処理
  #--------------------------------------------------------------------------
  def process_draw_icon(icon_index, pos)
    draw_icon(icon_index, pos[:x], pos[:y] + (pos[:height] - 24) / 2)
    pos[:x] += 24
  end
  #--------------------------------------------------------------------------
  # ● 制御文字によるピクチャ描画の処理
  #--------------------------------------------------------------------------
  def process_draw_picture(params)
    return if params.empty?
    bitmap  = Cache.picture(params[0] || "")
    x       = (params[1] ||   0).to_i
    y       = (params[2] ||   0).to_i
    opacity = (params[3] || 255).to_i
    hue     = (params[4] ||   0).to_i
    if hue != 0
      bitmap = bitmap.dup
      bitmap.hue_change(hue)
    end
    contents.blt(x, y, bitmap, bitmap.rect, opacity)
  end
  #--------------------------------------------------------------------------
  # ● 制御文字による顔グラ描画の処理
  #--------------------------------------------------------------------------
  def process_draw_face(params)
    return if params.empty?
    if params.size == 3
      actor  = $game_actors[params[0].to_i]
      bitmap = Cache.face(actor.face_name)
      index  = actor.face_index
      x      = (params[1] || 0).to_i
      y      = (params[2] || 0).to_i
    else
      bitmap = Cache.face(params[0] || "")
      index  = (params[1] || 0).to_i
      x      = (params[2] || 0).to_i
      y      = (params[3] || 0).to_i
    end
    contents.blt(x, y, bitmap, Rect.new(index % 4 * 96, index / 4 * 96, 96, 96))
  end
  #--------------------------------------------------------------------------
  # ● フォントを大きくする
  #--------------------------------------------------------------------------
  def make_font_bigger
    contents.font.size += 4 if contents.font.size <= 92
  end
  #--------------------------------------------------------------------------
  # ● フォントを小さくする
  #--------------------------------------------------------------------------
  def make_font_smaller
    contents.font.size -= 4 if contents.font.size >= 10
  end
  #--------------------------------------------------------------------------
  # ● 行の高さを計算
  #     restore_font_size : 計算後にフォントサイズを元に戻す
  #--------------------------------------------------------------------------
  def calc_line_height(text, restore_font_size = true)
    result = [line_height, contents.font.size].max
    last_font_size = contents.font.size
    text.slice(/^.*$/).scan(/\e[\{\}]/).each do |esc|
      make_font_bigger  if esc == "\e{"
      make_font_smaller if esc == "\e}"
      result = [result, contents.font.size].max
    end
    contents.font.size = last_font_size if restore_font_size
    result
  end
  #--------------------------------------------------------------------------
  # ● 矩形の描画
  #--------------------------------------------------------------------------
  def draw_fill_rect(x, y, width, height, color)
    bitmap = Bitmap.new(width, height)
    bitmap.fill_rect(bitmap.rect, color)
    self.contents.blt(x, y, bitmap, bitmap.rect)
    bitmap.dispose
  end
  #--------------------------------------------------------------------------
  # ● ゲージの描画
  #     rate   : 割合（1.0 で満タン）
  #     color1 : グラデーション 左端
  #     color2 : グラデーション 右端
  #--------------------------------------------------------------------------
  def draw_gauge(x, y, width, rate, color1, color2)
    fill_w = (width * rate).to_i
    gauge_y = y + line_height - 8
    contents.fill_rect(x, gauge_y, width, 6, gauge_back_color)
    contents.gradient_fill_rect(x, gauge_y, fill_w, 6, color1, color2)
  end
  #--------------------------------------------------------------------------
  # ● アイコンの描画
  #--------------------------------------------------------------------------
  def draw_icon(icon_index, x, y, enabled = true)
    bitmap = Cache.system("Iconset")
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    contents.blt(x, y, bitmap, rect, enabled ? 255 : translucent_alpha)
  end
  #--------------------------------------------------------------------------
  # ● 顔グラフィックの描画
  #--------------------------------------------------------------------------
  def draw_face(face_name, face_index, x, y, size = 96, enabled = true)
    bitmap = Cache.face(face_name)
    dest_rect = Rect.new(x, y, 96, 96)
    src_rect = Rect.new(face_index % 4 * 96, face_index / 4 * 96, 96, 96)
    opacity = enabled ? 255 : translucent_alpha
    
    case size
    when Integer
      src_rect.x += (96 - size) / 2
      src_rect.y += (96 - size) / 2
      src_rect.width = size
      src_rect.height = size
      contents.blt(x, y, bitmap, src_rect, opacity)
    when Array
      case size.size
      when 1
        dest_rect.width, dest_rect.height = size[0], size[0]
      when 2
        dest_rect.width, dest_rect.height = size[0], size[1]
      when 4
        dest_rect.width, dest_rect.height = size[2], size[3]
        src_rect.width, src_rect.height = size[2], size[3]
        src_rect.x, src_rect.y = src_rect.x + size[0], src_rect.y + size[1]
      else
        raise "wrong number of elements (#{size.size} of 2)"
      end
      contents.stretch_blt(dest_rect, bitmap, src_rect, opacity)
    else
      raise TypeError,
        "wrong argument type #{size.class} (expected Integer or Array)"
    end
  end
  #--------------------------------------------------------------------------
  # ● 歩行グラフィックの描画
  #--------------------------------------------------------------------------
  def draw_character(character_name, character_index, x, y)
    return unless character_name
    bitmap = Cache.character(character_name)
    sign = character_name[/^[\!\$]./]
    if sign && sign.include?('$')
      cw = bitmap.width / 3
      ch = bitmap.height / 4
    else
      cw = bitmap.width / 12
      ch = bitmap.height / 8
    end
    n = character_index
    src_rect = Rect.new((n%4*3+1)*cw, (n/4*4)*ch, cw, ch)
    contents.blt(x - cw / 2, y - ch, bitmap, src_rect)
  end
  #--------------------------------------------------------------------------
  # ● HP の文字色を取得
  #--------------------------------------------------------------------------
  def hp_color(actor)
    return knockout_color if actor.hp == 0
    return crisis_color if actor.hp < actor.mhp / 4
    return normal_color
  end
  #--------------------------------------------------------------------------
  # ● MP の文字色を取得
  #--------------------------------------------------------------------------
  def mp_color(actor)
    return crisis_color if actor.mp < actor.mmp / 4
    return normal_color
  end
  #--------------------------------------------------------------------------
  # ● TP の文字色を取得
  #--------------------------------------------------------------------------
  def tp_color(actor)
    return normal_color
  end
  #--------------------------------------------------------------------------
  # ● アクターの歩行グラフィック描画
  #--------------------------------------------------------------------------
  def draw_actor_graphic(actor, x, y)
    draw_character(actor.character_name, actor.character_index, x, y)
  end
  #--------------------------------------------------------------------------
  # ● アクターの顔グラフィック描画
  #--------------------------------------------------------------------------
  def draw_actor_face(actor, x, y, size = 96)
    draw_face(actor.face_name, actor.face_index, x, y, size)
  end
  #--------------------------------------------------------------------------
  # ● アクターの表情グラフィック描画
  #--------------------------------------------------------------------------
  def draw_actor_expression(actor, x, y, size = 96)
    draw_face(actor.face_name, actor.face_expression_index, x, y, size)
  end
  #--------------------------------------------------------------------------
  # ● 歩行アイコンの描画
  #     enabled : 有効フラグ。false のとき半透明で描画
  #--------------------------------------------------------------------------
  def draw_actor_icon(actor, x, y, enabled = true)
    return unless actor
    self.contents.fill_rect(x, y, 24, 24, COLOR_AIB_1)
    self.contents.fill_rect(x + 1, y + 1, 22, 22, COLOR_AIB_2)
    return unless actor.character_name
    return if actor.character_name.empty?
    bitmap = Cache.character(actor.character_name)
    sign = actor.character_name[/^[\!\$]./]
    if sign != nil and sign.include?('$')
      cw = bitmap.width / 3
      ch = bitmap.height / 4
    else
      cw = bitmap.width / 12
      ch = bitmap.height / 8
    end
    n = actor.character_index
    src_rect = Rect.new((n%4*3+1)*cw, (n/4*4)*ch, 20, 20)
    src_rect.x += (cw - src_rect.width) / 2
    src_rect.y += (ch - src_rect.height) / 4
    opacity = (enabled ? 255 : translucent_alpha)
    self.contents.blt(x + 2, y + 2, bitmap, src_rect, opacity)
  end
  #--------------------------------------------------------------------------
  # ● 立ち絵の描画
  #--------------------------------------------------------------------------
  def draw_actor_portrait(actor, x, y, enabled = true)
    return unless actor
    bitmap = Cache.picture(actor.portrait_name)
    opacity = (enabled ? 255 : translucent_alpha)
    self.contents.blt(x, y, bitmap, bitmap.rect, opacity)
  end
  #--------------------------------------------------------------------------
  # ● ピクチャの描画
  #     [:pict, x, y, "file", "script"]
  #     [:pict, x, y, nil, "script"]
  #     [:pict, x, y, ["file","file"], "script(bool)"]
  #     [:pict, x, y, ["file","file"], "script(number)"]
  #     [:pict, x, y, "pattern", "script"]
  #--------------------------------------------------------------------------
  def draw_actor_picture(actor, x, y, file, script = nil)
    return unless actor
    r, f1, f2 = script && eval(script), *file
    case r
    when nil
      filename = (actor.battle_member? ? f1 : f2) || f1
    when true, false
      filename = r ? f1 : f2
    else
      filename = file.nil?             ? r
               : file.kind_of?(String) ? sprintf(file, *r)
               : file[r]
    end
    if filename && filename != ""
      bitmap = Cache.picture(filename % actor.id)
      self.contents.blt(x, y, bitmap, bitmap.rect)
    end
  end
  #--------------------------------------------------------------------------
  # ● テキストの描画
  #--------------------------------------------------------------------------
  def draw_actor_text(actor, x, y, text, script = nil)
    return if script && !eval(script)
    draw_text_ex(x, y, text.gsub(/\\{(\w+?)}/) { actor.__send__($1) })
  end
  #--------------------------------------------------------------------------
  # ● 数字画像の描画
  #--------------------------------------------------------------------------
  def draw_actor_number(actor, x, y, num, file)
    bitmap = Cache.picture(file)
    r_num = Rect.new(0, 0, bitmap.width / 13, bitmap.height)
    param = String(num.is_a?(String) ? eval(num) : num)
    param.split(//).each_with_index do |c,i|
      case c
      when ' ';   next
      when '+';   index = 10
      when '-';   index = 11
      when /\d/;  index = Integer(c)
      else;       index = 12
      end
      r_num.x = r_num.width * index
      self.contents.blt(x + r_num.width * i, y, bitmap, r_num)
    end
  end
  #--------------------------------------------------------------------------
  # ● 名前の描画
  #--------------------------------------------------------------------------
  def draw_actor_name(actor, x, y, width = 124)
    change_color(hp_color(actor))
    draw_text(x, y, width, line_height, actor.name)
  end
  #--------------------------------------------------------------------------
  # ● 職業の描画
  #--------------------------------------------------------------------------
  def draw_actor_class(actor, x, y, width = 124)
    change_color(normal_color)
    draw_text(x, y, width, line_height, actor.class.name)
  end
  #--------------------------------------------------------------------------
  # ● 二つ名の描画
  #--------------------------------------------------------------------------
  def draw_actor_nickname(actor, x, y, width = 124)
    change_color(normal_color)
    draw_text(x, y, width, line_height, actor.nickname)
  end
  #--------------------------------------------------------------------------
  # ● レベルの描画
  #--------------------------------------------------------------------------
  def draw_actor_level(actor, x, y, width = 64)
    if VISIBLE_SYSTEM
      change_color(system_color)
      draw_text(x, y, 32, line_height, Vocab::level_a)
    end
    change_color(normal_color)
    draw_text(x + width - 32, y, 32, line_height, actor.level, 2)
  end
  #--------------------------------------------------------------------------
  # ● レベルの描画 (経験値ゲージ付)
  #--------------------------------------------------------------------------
  def draw_actor_level_g(actor, x, y, width = 64)
    draw_gauge(x,y,width,actor.cm_exp_rate,exp_gauge_color1,exp_gauge_color2)
    if VISIBLE_SYSTEM
      change_color(system_color)
      draw_text(x, y, 32, line_height, Vocab::level_a)
    end
    change_color(tp_color(actor))
    draw_text(x + width - 32, y, 32, line_height, actor.level, 2)
  end
  #--------------------------------------------------------------------------
  # ● ステートおよび強化／弱体のアイコンを描画
  #--------------------------------------------------------------------------
  def draw_actor_icons(actor, x, y, width = 96, align = 0)
    icons = (actor.state_icons + actor.buff_icons)[0, width / 24]
    case align
    when 0; left = 0
    when 1; left = (width - icons.size * 24) / 2
    when 2; left = (width - icons.size * 24)
    end
    icons.each_with_index {|n, i| draw_icon(n, x + left + 24 * i, y) }
  end
  #--------------------------------------------------------------------------
  # ● 現在値／最大値を分数形式で描画
  #--------------------------------------------------------------------------
  def draw_current_and_max_values(x, y, width, current, max, color1, color2)
    change_color(color1)
    xr = x + width
    if width < 96
      draw_text(xr - 40, y, 42, line_height, current, 2)
    else
      draw_text(xr - 92, y, 42, line_height, current, 2)
      change_color(color2)
      draw_text(xr - 52, y, 12, line_height, "/", 2)
      draw_text(xr - 42, y, 42, line_height, max, 2)
    end
  end
  #--------------------------------------------------------------------------
  # ● HP の描画
  #--------------------------------------------------------------------------
  def draw_actor_hp(actor, x, y, width = 124)
    draw_gauge(x, y, width, actor.hp_rate, hp_gauge_color1, hp_gauge_color2)
    if VISIBLE_SYSTEM
      change_color(system_color)
      draw_text(x, y, 30, line_height, Vocab::hp_a)
    end
    draw_current_and_max_values(x, y, width, actor.hp, actor.mhp,
      hp_color(actor), normal_color)
  end
  #--------------------------------------------------------------------------
  # ● MP の描画
  #--------------------------------------------------------------------------
  def draw_actor_mp(actor, x, y, width = 124)
    draw_gauge(x, y, width, actor.mp_rate, mp_gauge_color1, mp_gauge_color2)
    if VISIBLE_SYSTEM
      change_color(system_color)
      draw_text(x, y, 30, line_height, Vocab::mp_a)
    end
    draw_current_and_max_values(x, y, width, actor.mp, actor.mmp,
      mp_color(actor), normal_color)
  end
  #--------------------------------------------------------------------------
  # ● TP の描画
  #--------------------------------------------------------------------------
  def draw_actor_tp(actor, x, y, width = 124)
    draw_gauge(x, y, width, actor.tp_rate, tp_gauge_color1, tp_gauge_color2)
    if VISIBLE_SYSTEM
      change_color(system_color)
      draw_text(x, y, 30, line_height, Vocab::tp_a)
    end
    change_color(tp_color(actor))
    draw_text(x + width - 42, y, 42, line_height, actor.tp.to_i, 2)
  end
  #--------------------------------------------------------------------------
  # ● 経験値の描画
  #--------------------------------------------------------------------------
  def draw_actor_exp(actor, x, y, width = 124)
    draw_gauge(x, y, width, actor.cm_exp_rate,
      exp_gauge_color1, exp_gauge_color2)
    if VISIBLE_SYSTEM
      change_color(system_color)
      draw_text(x, y, width, line_height, VOCABS[:exp_a])
    end
    change_color(normal_color)
    draw_text(x, y, width, line_height, actor.cm_remaining_exp, 2)
  end
  #--------------------------------------------------------------------------
  # ● 経験値情報の描画
  #--------------------------------------------------------------------------
  def draw_actor_exp_info(actor, x, y, width = 124)
    s1 = actor.max_level? ? "-------" : actor.exp
    s2 = actor.max_level? ? "-------" : actor.cm_remaining_exp
    s_next = sprintf(Vocab::ExpNext, Vocab::level)
    change_color(system_color)
    draw_text(x, y + line_height * 0, 180, line_height, Vocab::ExpTotal)
    draw_text(x, y + line_height * 2, 180, line_height, s_next)
    change_color(normal_color)
    draw_text(x, y + line_height * 1, 180, line_height, s1, 2)
    draw_text(x, y + line_height * 3, 180, line_height, s2, 2)
  end
  #--------------------------------------------------------------------------
  # ● 能力値の描画
  #--------------------------------------------------------------------------
  def draw_actor_param(actor, x, y, param_id, width = 124)
    if param_id < 0 || param_id > 7
      raise ArgumentError, "能力値の ID は 0 から 7 までの数値です。"
    end
    if VISIBLE_SYSTEM
      change_color(system_color)
      draw_text(x, y, width, line_height, Vocab::param(param_id))
    end
    change_color(normal_color)
    draw_text(x, y, width, line_height, actor.param(param_id), 2)
  end
  #--------------------------------------------------------------------------
  # ● 矩形の描画
  #--------------------------------------------------------------------------
  def draw_actor_rect(actor, x, y, w, h, color, script = nil)
    return if script && !eval(script)
    draw_fill_rect(x, y, w, h, str2color(color))
  end
  #--------------------------------------------------------------------------
  # ● アイテム名の描画
  #--------------------------------------------------------------------------
  def draw_item_name(item, x, y, width = 172, enabled = true)
    return unless item
    draw_icon(item.icon_index, x, y, enabled)
    change_color(normal_color, enabled)
    draw_text(x + 24, y, width, line_height, item.name)
  end
  #--------------------------------------------------------------------------
  # ● 通貨単位つき数値（所持金など）の描画
  #--------------------------------------------------------------------------
  def draw_currency_value(value, name, unit, x, y, width)
    cx = text_size(unit).width
    change_color(normal_color)
    draw_text(x, y, width - cx - 2, line_height, value, 2)
    if VISIBLE_SYSTEM
      change_color(system_color)
      draw_text(x, y, width, line_height, name)
      draw_text(x, y, width, line_height, unit, 2)
    end
  end
  #--------------------------------------------------------------------------
  # ● 通貨単位つき数値（所持金など）の描画
  #--------------------------------------------------------------------------
  def draw_gold(x, y, width)
    draw_currency_value(
      $game_party.gold, VOCABS[:gold], Vocab::currency_unit, x, y, width)
  end
end
