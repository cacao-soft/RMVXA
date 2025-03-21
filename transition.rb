#******************************************************************************
#
#    ＊ トランジション
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.0.0
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#    ： トランジション処理を追加します。
#    ： フェードアウト・インの時間を指定可能にします。
#
#  --------------------------------------------------------------------------
#   == 使用方法 ==
#
#    ★ トランジション準備
#       prepare_transition
#
#    ★ トランジション開始
#       perform_transition(duration = 30, filename = "", vague = 40)
#       start_transition(duration = 30, filename = "", vague = 40)
#
#    ★ 画面のフェードアウト
#       start_fadeout(duration = 30)
#
#    ★ 画面のフェードイン
#       start_fadein(duration = 30)
#
#
#******************************************************************************


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● トランジション準備
  #--------------------------------------------------------------------------
  def prepare_transition
    Fiber.yield while $game_message.visible
    Graphics.freeze
  end
  #--------------------------------------------------------------------------
  # ● トランジション実行
  #--------------------------------------------------------------------------
  def perform_transition(duration = 30, filename = "", vague = 40)
    begin Fiber.yield end while $game_message.visible
    Graphics.transition(duration, "Graphics/Transitions/#{filename}", vague)
  end
  alias start_transition perform_transition
  #--------------------------------------------------------------------------
  # ● 画面のフェードアウト
  #--------------------------------------------------------------------------
  def start_fadeout(duration = 30)
    Fiber.yield while $game_message.visible
    screen.start_fadeout(duration)
    wait(duration)
  end
  #--------------------------------------------------------------------------
  # ● 画面のフェードイン
  #--------------------------------------------------------------------------
  def start_fadein(duration = 30)
    Fiber.yield while $game_message.visible
    screen.start_fadein(duration)
    wait(duration)
  end
end
