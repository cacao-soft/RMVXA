#******************************************************************************
#
#    ＊ サブコマンドウィンドウ
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.1.2
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： http://cacaosoft.webcrow.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#    ： ウィンドウをベースとしたサブコマンドを追加します。
#
#  --------------------------------------------------------------------------
#   == 注意事項 ==
#
#    ※ 動作には Custom Menu Base と コマンドウィンドウ が必要です。
#    ※ 項目の設定は、Custom Menu Base で行ってください。
#
#
#******************************************************************************


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO::CM::SubCommand
  #--------------------------------------------------------------------------
  # ◇ ウィンドウの設定
  #--------------------------------------------------------------------------
  CONFIGURATION = {}
  CONFIGURATION[:sub] = {
    dx: 160, dy: 0, column: 1, width: 160
  }
  #--------------------------------------------------------------------------
  # ◇ 自動位置修正
  #--------------------------------------------------------------------------
  AUTO_ALIGNMENT = true
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Window_MenuSubCommand < Window_CustomMenuCommand
  include CAO::CM::SubCommand
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize
    super(nil)
    self.openness = 0
    deactivate
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ幅の取得
  #--------------------------------------------------------------------------
  def window_width
    return params(:width, super)
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ高さの取得
  #--------------------------------------------------------------------------
  def window_height
    return params(:height, fitting_height(row_max))
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def window_opacity
    return params(:opacity, false) ? 0 : 255
  end
  #--------------------------------------------------------------------------
  # ● 桁数の取得
  #--------------------------------------------------------------------------
  def col_max
    return (params(:column, super) < 0) ? item_max : params(:column, super)
  end
  #--------------------------------------------------------------------------
  # ● 横に項目が並ぶときの空白の幅を取得
  #--------------------------------------------------------------------------
  def spacing
    return params(:space, super)
  end
  #--------------------------------------------------------------------------
  # ● アライメントの取得
  #--------------------------------------------------------------------------
  def alignment
    return params(:align, super)
  end
  #--------------------------------------------------------------------------
  # ● 決定ボタンが押されたときの処理
  #--------------------------------------------------------------------------
  def process_ok
    symbol = @@last_command_symbol
    super
    @@last_command_symbol = symbol
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def params(key, default)
    return CONFIGURATION[@ident] && CONFIGURATION[@ident][key] || default
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def init_command(ident)
    @ident = ident
    clear_command_list
    make_command_list
    self.width = window_width
    self.height = window_height
    create_contents
    refresh
    self.x = params(:x, 0)
    self.y = params(:y, 0)
    self.opacity = window_opacity
    select(0)
  end
end

class Scene_Menu
  #--------------------------------------------------------------------------
  # ○ オプションウィンドウの作成
  #--------------------------------------------------------------------------
  alias _cao_cm_sub_create_option_window create_option_window
  def create_option_window
    _cao_cm_sub_create_option_window
    @subcommand_window = Window_MenuSubCommand.new
  end
  #--------------------------------------------------------------------------
  # ○ サブコマンドウィンドウを開く
  #--------------------------------------------------------------------------
  alias _cao_cm_sub_open_sub_command open_sub_command
  def open_sub_command
    symbol = @command_window.current_data.sub
    subconf = CAO::CM::SubCommand::CONFIGURATION[symbol]
    if subconf
      cr = @command_window.item_rect(@command_window.index)
      if subconf[:dx]
        @subcommand_window.x += @command_window.x
        @subcommand_window.x += cr.x + subconf[:dx]
      end
      if subconf[:dy]
        @subcommand_window.y += @command_window.y
        @subcommand_window.y += cr.y + subconf[:dy]
      end
    end
    # 画面内に収まるように位置を調整
    if CAO::CM::SubCommand::AUTO_ALIGNMENT
      if Graphics.width < @subcommand_window.x + @subcommand_window.width
        @subcommand_window.x = Graphics.width - @subcommand_window.width
      end
      @subcommand_window.x = 0 if @subcommand_window.x < 0
      if Graphics.height < @subcommand_window.y + @subcommand_window.height
        @subcommand_window.y = Graphics.height - @subcommand_window.height
      end
      @subcommand_window.y = 0 if @subcommand_window.y < 0
    end
    _cao_cm_sub_open_sub_command
  end
  #--------------------------------------------------------------------------
  # ○ コマンド実行後の処理
  #--------------------------------------------------------------------------
  alias _cao_cm_sub_post_terminate post_terminate
  def post_terminate
    _cao_cm_sub_post_terminate
    if current_console.current_data.refresh_items.include?(:command)
      @subcommand_window.refresh
    end
  end
end
