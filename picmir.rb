#******************************************************************************
#
#    ＊ ピクチャの反転
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.0.1
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#   ： ピクチャを反転する機能を追加します。
#
#  --------------------------------------------------------------------------
#   == 使用方法 ==
#
#    ★ ラベル命令
#     以下の文をイベントコマンド「ラベル」に記入してください。
#       反転     .. ピクチャの反転：ID    (現在の向きから反転)
#       元の向き .. ピクチャの反転：ID, x (反転しないということで x )
#       逆の向き .. ピクチャの反転：ID, o (反転するので o )
#
#    ★ スクリプト
#     以下のスクリプトをイベントコマンド「スクリプト」で実行してください。
#       反転     .. screen.pictures[ID].mirror ^= true
#       元の向き .. screen.pictures[ID].mirror = false
#       逆の向き .. screen.pictures[ID].mirror = true
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
  # ○ ラベル
  #--------------------------------------------------------------------------
  alias cao_picmir_command_118 command_118
  def command_118
    case @params[0]
    when /ピクチャの反転：(\d+)(?:,\s*([ox]))?/i
      if $2
        screen.pictures[$1.to_i].mirror = ($2.upcase == "O")
      else
        screen.pictures[$1.to_i].mirror ^= true
      end
    when /Ｐ反転：\s*(\d+)/
      screen.pictures[$1.to_i].mirror ^= true
    when /Ｐ正向：\s*(\d+)/
      screen.pictures[$1.to_i].mirror = false
    when /Ｐ逆向：\s*(\d+)/
      screen.pictures[$1.to_i].mirror = true
    else
      cao_picmir_command_118
    end
  end
end

class Game_Picture
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :mirror                   # 反転
  #--------------------------------------------------------------------------
  # ○ 基本変数の初期化
  #--------------------------------------------------------------------------
  alias cao_picmir_init_basic init_basic
  def init_basic
    cao_picmir_init_basic
    @mirror = false
  end
end

class Sprite_Picture
  #--------------------------------------------------------------------------
  # ○ その他の更新
  #--------------------------------------------------------------------------
  alias cao_picmir_update_other update_other
  def update_other
    cao_picmir_update_other
    self.mirror = @picture.mirror
  end
end
