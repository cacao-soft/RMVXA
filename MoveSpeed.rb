#******************************************************************************
#
#    ＊ 移動速度の変更
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.2.0
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#   ： プレイヤーの移動速度を上げます。
#   ： 常時ダッシュ機能を追加します。
#
#
#******************************************************************************


#==============================================================================
# ◆ 設定項目
#==============================================================================
class Game_Player
  #--------------------------------------------------------------------------
  # ◇ プレイヤーの移動速度の設定
  #--------------------------------------------------------------------------
  #     0 .. プリセットのまま
  #     1 .. 1.5 倍ほど速くする
  #     2 .. 2 倍ほど速くして、変化を緩やかにする
  #--------------------------------------------------------------------------
  PLAYER_SPEED_UP = 2
  #--------------------------------------------------------------------------
  # ◇ 常時ダッシュ
  #--------------------------------------------------------------------------
  ALWAYS_DASH = false
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Player < Game_Character
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  case PLAYER_SPEED_UP
  when 1
    SPEED_TABLE = [0.0,0.01171875,0.0234375,0.046875,0.09375,0.1875,0.375,0.75]
  when 2
    SPEED_TABLE = [0.0, 0.03125, 0.0625, 0.09375, 0.125, 0.25, 0.375, 0.5]
  else
    SPEED_TABLE = Array.new(7) {|i| 2 ** (i + 1) / 256.0 }.unshift(0.0)
  end
  #--------------------------------------------------------------------------
  # ○ ダッシュ状態判定
  #--------------------------------------------------------------------------
  def dash?
    return false if @move_route_forcing
    return false if $game_map.disable_dash?
    return false if vehicle
    return ALWAYS_DASH ^ Input.press?(:A)
  end
  #--------------------------------------------------------------------------
  # ○ 1 フレームあたりの移動距離を計算
  #--------------------------------------------------------------------------
  if PLAYER_SPEED_UP != 0
  def distance_per_frame
    return SPEED_TABLE[real_move_speed]
  end
  end # if PLAYER_SPEED_UP != 0
end

class Game_Follower
  #--------------------------------------------------------------------------
  # ○ 1 フレームあたりの移動距離を計算
  #--------------------------------------------------------------------------
  def distance_per_frame
    @preceding_character.distance_per_frame
  end
end
