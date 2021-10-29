#******************************************************************************
#
#    ＊ コマンドスプライト
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.0.0
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： http://cacaosoft.webcrow.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#    ： スプライトをベースとしたメニュー項目です。
#
#  --------------------------------------------------------------------------
#   == 注意事項 ==
#
#    ※ このスクリプトの動作には、Custom Menu Base が必要です。
#    ※ 項目の設定は、Custom Menu Base で行ってください。
#
#
#******************************************************************************


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO::CM::Command
  #--------------------------------------------------------------------------
  # ◇ コマンドの位置
  #--------------------------------------------------------------------------
  POSITION = Array.new(7) {|i| [80, 40 * i + 80] }
  #--------------------------------------------------------------------------
  # ◇ カーソルの設定 (ファイル名, dx, dy, 後ろに表示, 点滅)
  #--------------------------------------------------------------------------
  CURSOR_IMAGE = ["cm_cursor", 0, 1, true, 4]
  #--------------------------------------------------------------------------
  # ◇ 項目の画像
  #--------------------------------------------------------------------------
  #     ["ファイル名", 分割数]
  #--------------------------------------------------------------------------
  COMMANDS_IMAGE = ["MenuCommands", 7]
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Spriteset_MenuMainCommand < Spriteset_CustomMenuCommand
  include CustomMenuCommand
  include CAO::CM::Command
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :index                    # カーソル位置
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def initialize
    super(:main)
    self.viewport = Viewport.new
    self.viewport.z = 100
    clear_command_list
    make_command_list
    create_command_sprites
    create_cursor_sprite
    activate
    select(0)
  end
  #--------------------------------------------------------------------------
  # ● カーソルデータの取得
  #--------------------------------------------------------------------------
  def cursor_data
    return CURSOR_IMAGE
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def create_command_sprites
    super do |sp,i|
      sp.x, sp.y = CAO::CM::Command::POSITION[i]
      sp.visible = false
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def refresh
    refresh_commands {|sp| sp.visible = true }
  end
  #--------------------------------------------------------------------------
  # ●  (要再定義)
  #--------------------------------------------------------------------------
  def command_filename
    return "" unless CAO::CM::Command::COMMANDS_IMAGE
    return "" if CAO::CM::Command::COMMANDS_IMAGE.empty?
    return CAO::CM::Command::COMMANDS_IMAGE[0]
  end
  #--------------------------------------------------------------------------
  # ● コマンド総数の取得 (要再定義)
  #--------------------------------------------------------------------------
  def command_max
    return 0 if command_filename.empty?
    return CAO::CM::Command::COMMANDS_IMAGE[1]
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def visible=(value)
    super
    @command_sprites.each {|sp| sp.visible = value }
  end
  #--------------------------------------------------------------------------
  # ● 前回の選択位置を復帰
  #--------------------------------------------------------------------------
  def select_last
    select_symbol(Window_MenuCommand.class_variable_get(:@@last_command_symbol))
  end
  #--------------------------------------------------------------------------
  # ● 項目の選択位置を記憶
  #--------------------------------------------------------------------------
  def save_command_position
    Window_MenuCommand.class_variable_set(
      :@@last_command_symbol, current_symbol)
  end
end

class Scene_Menu
  #--------------------------------------------------------------------------
  # ● コマンドウィンドウの作成
  #--------------------------------------------------------------------------
  def create_command_window
    @command_window = Spriteset_MenuMainCommand.new
    @command_window.set_handler(:cancel, method(:return_scene))
    @command_window.set_handlers(self)
    @command_window.select_last
  end
  #--------------------------------------------------------------------------
  # ● コマンドウィンドウの更新
  #--------------------------------------------------------------------------
  def update_command_window
    @command_window.update
  end
  #--------------------------------------------------------------------------
  # ● コマンドウィンドウの解放
  #--------------------------------------------------------------------------
  def dispose_command_window
    @command_window.dispose
  end
  #--------------------------------------------------------------------------
  # ○ コマンド実行後の処理
  #--------------------------------------------------------------------------
  alias _cao_cm_command_post_terminate post_terminate
  def post_terminate
    _cao_cm_command_post_terminate
    if current_console.current_data.refresh_items.include?(:command)
      @command_window.refresh
    end
  end
end
