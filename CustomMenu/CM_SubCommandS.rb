#******************************************************************************
#
#    ＊ サブコマンドスプライト
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.0.0
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： http://cacaosoft.webcrow.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#    ： スプライトをベースとしたサブコマンドを追加します。
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
    image: ["MenuCommands", 7],
    # ファイル名, dx, dy, 上下, 点滅
    cursor: ["", 4, 1, 0, 0],
    pos: [
      [48,16], [48,66], [48,116], [48,166],
      [248,48], [248,98], [248,148], [248,198]
    ]
  }
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Spriteset_MenuSubCommand < Spriteset_CustomMenuCommand
  include CustomMenuCommand
  include CAO::CM::SubCommand
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def initialize
    super(nil)
    self.viewport = Viewport.new
    self.viewport.z = 100
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def init_command(ident)
    @ident = ident
    clear_command_list
    make_command_list
    create_command_sprites
    create_cursor_sprite
    deactivate
    select(0)
    refresh
  end
  #--------------------------------------------------------------------------
  # ●  (要再定義)
  #--------------------------------------------------------------------------
  def command_filename
    return "" unless CONFIGURATION[@ident][:image]
    return "" if CONFIGURATION[@ident][:image].empty?
    return CONFIGURATION[@ident][:image][0]
  end
  #--------------------------------------------------------------------------
  # ● コマンド総数の取得 (要再定義)
  #--------------------------------------------------------------------------
  def command_max
    return 0 if command_filename.empty?
    return CONFIGURATION[@ident][:image][1]
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def create_command_sprites
    super do |sp,i|
      sp.x, sp.y = CONFIGURATION[@ident][:pos][i]
      sp.visible = false
    end
    self.openness = 0
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def refresh
    refresh_commands {|sp| sp.visible = true }
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def visible=(value)
    super
    @command_sprites.each {|sp| sp.visible = value }
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def open
    refresh
    super
  end
  #--------------------------------------------------------------------------
  # ● カーソルデータの取得
  #--------------------------------------------------------------------------
  def cursor_data
    return CONFIGURATION[@ident][:cursor]
  end
end

class Scene_Menu
  #--------------------------------------------------------------------------
  # ○ オプションウィンドウの作成
  #--------------------------------------------------------------------------
  alias _cao_cm_sub_create_option_window create_option_window
  def create_option_window
    _cao_cm_sub_create_option_window
    @subcommand_window = Spriteset_MenuSubCommand.new
  end
  #--------------------------------------------------------------------------
  # ○ オプションウィンドウの更新
  #--------------------------------------------------------------------------
  alias _cao_cm_sub_update_option_window update_option_window
  def update_option_window 
    _cao_cm_sub_update_option_window
    @subcommand_window.update if @subcommand_window
  end
  #--------------------------------------------------------------------------
  # ○ オプションウィンドウの解放
  #--------------------------------------------------------------------------
  alias _cao_cm_sub_dispose_option_window dispose_option_window
  def dispose_option_window 
    _cao_cm_sub_dispose_option_window
    @subcommand_window.dispose if @subcommand_window
  end
  #--------------------------------------------------------------------------
  # ○ コマンド実行後の処理
  #--------------------------------------------------------------------------
  alias _cao_cm_sub_post_terminate post_terminate
  def post_terminate
    _cao_cm_sub_post_terminate
    item = current_console.current_data
    if @subcommand_window && item.refresh_items.include?(:command)
      @subcommand_window.refresh
    end
  end
end
