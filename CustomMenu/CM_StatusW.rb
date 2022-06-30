#******************************************************************************
#
#    ＊ ステータスウィンドウ
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.1.3
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： http://cacaosoft.webcrow.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#    ： デフォルトっぽいステータスです。
#
#  --------------------------------------------------------------------------
#   == 注意事項 ==
#
#    ※ このスクリプトの動作には、Custom Menu Base が必要です。
#    ※ 横１列のみの場合は左右に、それ以外は上下のみスクロールします。
#
#
#******************************************************************************


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO::CM::Status
  #--------------------------------------------------------------------------
  # ◇ ウィンドウの位置・サイズ
  #--------------------------------------------------------------------------
  WINDOW_X = 160  # ｘ座標
  WINDOW_Y = 0    # ｙ座標
  WINDOW_W = 384  # 横幅
  WINDOW_H = 416  # 縦幅
  #--------------------------------------------------------------------------
  # ◇ １アクターのサイズ
  #--------------------------------------------------------------------------
  ITEM_W = 360
  ITEM_H = 98
  #--------------------------------------------------------------------------
  # ◇ 項目を横に並べる数
  #--------------------------------------------------------------------------
  COLUMN_MAX = 1
  #--------------------------------------------------------------------------
  # ◇ 表示項目の設定
  #--------------------------------------------------------------------------
  ITEM_PARAMS = []
  ITEM_PARAMS << [:face,    2,  2, 94]
  ITEM_PARAMS << [:fill,    2,  2, 94, 94, 128, '!actor.battle_member?']
  ITEM_PARAMS << [:name,  104,  7]
  ITEM_PARAMS << [:level, 104, 37]
  ITEM_PARAMS << [:state, 104, 67, 124]
  ITEM_PARAMS << [:class, 232,  7]
  ITEM_PARAMS << [:hp,    232, 37]
  ITEM_PARAMS << [:mp,    232, 67]
  #--------------------------------------------------------------------------
  # ◇ ウィンドウサイズの自動調整
  #--------------------------------------------------------------------------
  WINDOW_RESIZE = false
  #--------------------------------------------------------------------------
  # ◇ 戦闘メンバーのみ表示
  #--------------------------------------------------------------------------
  ::CAO::CM::BATTLER_ONLY = false
  #--------------------------------------------------------------------------
  # ◇ ウィンドウを非表示で開始
  #--------------------------------------------------------------------------
  WINDOW_HIDE = false
  #--------------------------------------------------------------------------
  # ◇ ウィンドウの可視状態
  #--------------------------------------------------------------------------
  VISIBLE_BACKWINDOW = true
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Window_MenuStatus
  include CAO::CM::Status
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(x, y)
    super(WINDOW_X, WINDOW_Y, window_width, window_height)
    self.openness = WINDOW_HIDE ? 0 : 255
    self.opacity = VISIBLE_BACKWINDOW ? 255 : 0
    @canvas = CAO::CM::Canvas.new(self)
    @pending_index = -1
    refresh
  end
  #--------------------------------------------------------------------------
  # ○ ウィンドウのアクティブ化
  #--------------------------------------------------------------------------
  def activate
    super
    open if WINDOW_HIDE
  end
  #--------------------------------------------------------------------------
  # ○ ウィンドウの非アクティブ化
  #--------------------------------------------------------------------------
  def deactivate
    super
    close if WINDOW_HIDE
  end
  #--------------------------------------------------------------------------
  # ○ 横に項目が並ぶときの空白の幅を取得
  #--------------------------------------------------------------------------
  def spacing
    return 0
  end
  #--------------------------------------------------------------------------
  # ○ ウィンドウ幅の取得
  #--------------------------------------------------------------------------
  def window_width
    WINDOW_W
  end
  #--------------------------------------------------------------------------
  # ○ ウィンドウ高さの取得
  #--------------------------------------------------------------------------
  def window_height
    WINDOW_H
  end
  #--------------------------------------------------------------------------
  # ○ ウィンドウ内容の幅を計算
  #--------------------------------------------------------------------------
  def contents_width
    (item_width + spacing) * col_max - spacing
  end
  #--------------------------------------------------------------------------
  # ○ ウィンドウ内容の高さを計算
  #--------------------------------------------------------------------------
  def contents_height
    item_height * (item_max / col_max.to_f).ceil
  end
  #--------------------------------------------------------------------------
  # ● 項目数の取得
  #--------------------------------------------------------------------------
  def item_max
    $game_party.members.size
  end
  #--------------------------------------------------------------------------
  # ● 桁数の取得
  #--------------------------------------------------------------------------
  def col_max
    return COLUMN_MAX
  end
  #--------------------------------------------------------------------------
  # ○ 項目の幅を取得
  #--------------------------------------------------------------------------
  def item_width
    ITEM_W
  end
  #--------------------------------------------------------------------------
  # ○ 項目の高さを取得
  #--------------------------------------------------------------------------
  def item_height
    ITEM_H
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウサイズの変更
  #--------------------------------------------------------------------------
  def resize_window
    padding_lr = self.padding * 2
    if self.contents_width < self.width - padding_lr
      self.width = self.contents_width + padding_lr
    end
    padding_tp = self.padding + self.padding_bottom
    if self.contents_height < self.height - padding_tp
      self.height = self.contents_height + padding_tp
    end
  end
  #--------------------------------------------------------------------------
  # ○ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    resize_window if WINDOW_RESIZE
    super
  end
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #--------------------------------------------------------------------------
  def draw_item(index)
    draw_item_background(index)
    actor = $game_party.members[index]
    rect = item_rect(index)
    @canvas.draw_actor_items(actor, rect.x, rect.y, ITEM_PARAMS)
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
end

class Scene_Menu
  #--------------------------------------------------------------------------
  # ● ステータスウィンドウの作成
  #--------------------------------------------------------------------------
  def create_status_window
    @status_window = Window_MenuStatus.new(0, 0)
  end
  #--------------------------------------------------------------------------
  # ● ステータスウィンドウの更新
  #--------------------------------------------------------------------------
  def update_status_window
    @status_window.unselect unless @status_window.active
  end
  #--------------------------------------------------------------------------
  # ○ コマンド実行後の処理
  #--------------------------------------------------------------------------
  alias _cao_cm_status_post_terminate post_terminate
  def post_terminate
    _cao_cm_status_post_terminate
    if current_console.current_data.refresh_items.include?(:status)
      @status_window.refresh
    end
  end
end

class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :in_menu                  # メニュー中フラグ
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def in_menu
    return true if SceneManager.scene_is?(Scene_Menu)
    return SceneManager.instance_variable_get(:@stack).any? do |obj|
      obj.is_a?(Scene_Menu)
    end
  end
  #--------------------------------------------------------------------------
  # ○ メンバーの取得
  #--------------------------------------------------------------------------
  def members
    return battle_members if in_battle
    return battle_members if CAO::CM::BATTLER_ONLY && in_menu
    return all_members
  end
end

class Scene_ItemBase < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ○ サブウィンドウの表示
  #--------------------------------------------------------------------------
  def show_sub_window(window)
    window.x = (Graphics.width - window.width) / 2
    window.y = (Graphics.height - window.height) / 2
    window.z = @viewport.z# + 1
    @last_viewport_color = @viewport.color.dup
    @viewport.color.set(16, 16, 16, 128)
    window.show.activate
  end
  #--------------------------------------------------------------------------
  # ○ サブウィンドウの非表示
  #--------------------------------------------------------------------------
  def hide_sub_window(window)
    @viewport.color.set(@last_viewport_color) if @last_viewport_color
    window.hide.deactivate
    activate_item_window
  end
end