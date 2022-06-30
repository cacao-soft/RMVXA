#******************************************************************************
#
#    ＊ ぽぽぽメッセージウィンドウ
#
#  --------------------------------------------------------------------------
#    バージョン ： 0.0.2
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#   ： メッセージに合わせてサイズの変わるメッセージウィンドウに変更します
#
#  --------------------------------------------------------------------------
#   == 使用方法 ==
#
#    ★ ぽぽぽ機能を使用する
#     SWITCH_ID で設定した番号のスイッチを ON にする
#
#
#******************************************************************************


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
module PppMsg

  #--------------------------------------------------------------------------
  # ◇ ぽぽぽ機能をオフにするスイッチの番号
  #--------------------------------------------------------------------------
  SWITCH_ID = 1
  #--------------------------------------------------------------------------
  # ◇ 戦闘メッセージの表示位置 (ぽぽぽ機能 ON のときのみ)
  #--------------------------------------------------------------------------
  BATTLE_MSG_POSITION = 1
  #--------------------------------------------------------------------------
  # ◇ 文字表示のウェイト時間 (ぽぽぽ機能 ON のときのみ)
  #--------------------------------------------------------------------------
  WAIT = 3

end # module PppMsg
end # module CAO


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class << CAO::PppMsg
  def on?
    $game_switches[CAO::PppMsg::SWITCH_ID]
  end
end
class << BattleManager
  #--------------------------------------------------------------------------
  # ● 戦闘開始
  #--------------------------------------------------------------------------
  alias _cao_pppmsg_battle_start battle_start
  def battle_start
    update_message_position
    _cao_pppmsg_battle_start
  end
  #--------------------------------------------------------------------------
  # ● 勝敗判定
  #--------------------------------------------------------------------------
  alias _cao_pppmsg_judge_win_loss judge_win_loss
  def judge_win_loss
    update_message_position
    _cao_pppmsg_judge_win_loss
  end
  private
  def update_message_position
    if CAO::PppMsg.on?
      $game_message.position = CAO::PppMsg::BATTLE_MSG_POSITION
    end
  end
end
class Window_Message < Window_Base
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_pppmsg_initialize initialize
  def initialize
    _cao_pppmsg_initialize
    reset_window_size
    redefine_update_placement
  end
  #--------------------------------------------------------------------------
  # ● サブウィンドウの update_placement を再定義
  #--------------------------------------------------------------------------
  def redefine_update_placement
    [@choice_window, @number_window, @item_window].each do |wnd|
      class << wnd
        alias _cao_pppmsg_update_placement update_placement
      end
      def wnd.update_placement
        _cao_pppmsg_update_placement
        if CAO::PppMsg.on?
          top_y = @message_window.y
          bottom_y = @message_window.y + @message_window.height
          padding_top = @message_window.y
          padding_bottom = Graphics.height - bottom_y
          padding = padding_top
          padding = padding_bottom if padding_top < padding_bottom
          padding = [self.padding, (padding - self.height) / 2].min
          self.x = @message_window.x
          self.x += (@message_window.width - self.width) / 2
          self.y = top_y - self.height - padding
          self.y = bottom_y + padding if padding_top < padding_bottom
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 表示行数の取得
  #--------------------------------------------------------------------------
  def visible_line_number
    return CAO::PppMsg.on? ? 8 : 4
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウサイズのリセット
  #--------------------------------------------------------------------------
  def reset_window_size
    if CAO::PppMsg.on?
      self.arrows_visible = false
      self.width = self.padding * 2
      self.height = self.padding * 2 + line_height
      self.x = Graphics.width / 2 - self.padding
      if $game_party.in_battle || @position == 1
        self.y = Graphics.height / 2 - self.padding
      else
        onethird_height = Graphics.height / 3
        self.y = (@position == 0) ? 0 : Graphics.height - onethird_height
        self.y += (onethird_height - self.height) / 2
      end
    else
      update_placement
      self.arrows_visible = true
      self.width = window_width
      self.height = window_height
    end
  end
  #--------------------------------------------------------------------------
  # ● 通常文字の処理
  #--------------------------------------------------------------------------
  def process_normal_character(c, pos)
    super
    contents_width = self.width - (self.padding * 2)
    text_width = pos[:x] - contents_width
    if text_width > 0
      self.width += text_width
      self.x -= text_width / 2
    end
    wait_for_one_character
  end
  #--------------------------------------------------------------------------
  # ● 改行文字の処理
  #--------------------------------------------------------------------------
  def process_new_line(text, pos)
    @line_show_fast = false
    super
    if need_new_page?(text, pos)
      input_pause
      new_page(text, pos)
    elsif text != ""
      contents_height = self.height - (self.padding * 2)
      if contents_height < pos[:y] + pos[:height]
        self.height += pos[:height]
        self.y -= pos[:height] / 2
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 改ページ処理
  #--------------------------------------------------------------------------
  alias _cao_pppmsg_new_page new_page
  def new_page(text, pos)
    _cao_pppmsg_new_page(text, pos)
    reset_window_size
  end
  #--------------------------------------------------------------------------
  # ● 全テキストの処理
  #--------------------------------------------------------------------------
  alias _cao_pppmsg_process_all_text process_all_text
  def process_all_text
    reset_window_size
    _cao_pppmsg_process_all_text
  end
  #--------------------------------------------------------------------------
  # ● 一文字出力後のウェイト時間
  #--------------------------------------------------------------------------
  def wait_time
    CAO::PppMsg.on? ? CAO::PppMsg::WAIT : 1
  end
  #--------------------------------------------------------------------------
  # ● 一文字出力後のウェイト
  #--------------------------------------------------------------------------
  def wait_for_one_character
    update_show_fast
    unless @show_fast || @line_show_fast
      wait_time.times { Fiber.yield }
    end
  end
end
