#******************************************************************************
#
#    ＊ ヘルプウィンドウ
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.1.0
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： http://cacaosoft.webcrow.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#    ： 項目の説明を表示するウィンドウを追加します。
#
#  --------------------------------------------------------------------------
#   == 注意事項 ==
#
#    ※ このスクリプトの動作には、Custom Menu Base が必要です。
#
#
#******************************************************************************


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO::CM::Help
  #--------------------------------------------------------------------------
  # ◇ ウィンドウの位置とサイズ
  #--------------------------------------------------------------------------
  WINDOW_X = 0      # ｘ座標
  WINDOW_Y = 0      # ｙ座標
  WINDOW_W = 544    # 横幅
  WINDOW_H = 48     # 縦幅
  #--------------------------------------------------------------------------
  # ◇ テキストの最大表示行数
  #--------------------------------------------------------------------------
  ROW_MAX = 1
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


class Window_MenuHelp < Window_Base
  include CAO::CM::Help
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(WINDOW_X, WINDOW_Y, WINDOW_W, WINDOW_H)
    self.opacity = VISIBLE_BACKWINDOW ? 255 : 0
    @canvas = CAO::CM::Canvas.new(self)
  end
  #--------------------------------------------------------------------------
  # ● 行の高さを取得
  #--------------------------------------------------------------------------
  def line_height
    return contents_height / ROW_MAX
  end
  #--------------------------------------------------------------------------
  # ● テキスト設定
  #--------------------------------------------------------------------------
  def set_text(text)
    if text != @text
      @text = text
      refresh
    end
  end
  #--------------------------------------------------------------------------
  # ● クリア
  #--------------------------------------------------------------------------
  def clear
    set_text("")
  end
  #--------------------------------------------------------------------------
  # ● アイテム設定
  #     item : スキル、アイテム等
  #--------------------------------------------------------------------------
  def set_item(item)
    set_text(item ? item.description : "")
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    @canvas.draw_text_ex(4, 0, @text)
  end
end

class Scene_Menu
  #--------------------------------------------------------------------------
  # ○ オプションウィンドウの作成
  #--------------------------------------------------------------------------
  alias _cao_cm_help_create_option_window create_option_window
  def create_option_window
    _cao_cm_help_create_option_window
    @help_window = Window_MenuHelp.new
  end
  #--------------------------------------------------------------------------
  # ○ オプションウィンドウの更新
  #--------------------------------------------------------------------------
  alias _cao_cm_help_update_command_window update_command_window
  def update_command_window 
    _cao_cm_help_update_command_window
    unless @status_window && @status_window.active
      @help_window.set_item(@command_window.current_data)
      if @subcommand_window && @subcommand_window.active
        @help_window.set_item(@subcommand_window.current_data)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ コマンド実行後の処理
  #--------------------------------------------------------------------------
  alias _cao_cm_help_post_terminate post_terminate
  def post_terminate
    _cao_cm_help_post_terminate
    if current_console.current_data.refresh_items.include?(:help)
      @help_window.refresh
    end
  end
end
