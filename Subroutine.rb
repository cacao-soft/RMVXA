#******************************************************************************
#
#    ＊ イベントコマンドのサブルーチン化
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.0.0
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#   ： イベントコマンドでサブルーチンを作る機能を追加します。
#
#  --------------------------------------------------------------------------
#   == 使用方法 ==
#
#    ★ サブルーチンの定義
#     イベントコマンド「条件分岐」スクリプトに *ラベル名 のように設定する
#
#    ★ サブルーチンの実行
#     イベントコマンド「ラベルジャンプ」で *ラベル名 を実行する
#
#    ★ サブルーチンの呼び出し元に戻る
#     「分岐終了」に到達すると自動で呼び出し元に戻ります。
#     途中で戻りたい場合は「ラベルジャンプ」で return を実行する
#     呼び出し元が見つからない場合は例外が発生します。
#
#
#******************************************************************************


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
module Subroutine

  #--------------------------------------------------------------------------
  # ◇ サブルーチン定義の接頭辞
  #--------------------------------------------------------------------------
  PREFIX = "*"
  #--------------------------------------------------------------------------
  # ◇ リターン命令
  #--------------------------------------------------------------------------
  RETURN = "return"

end # Subroutine
end # CAO

#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Interpreter
  #--------------------------------------------------------------------------
  # ○ クリア
  #--------------------------------------------------------------------------
  alias _cao_subroutine_clear clear
  def clear
    _cao_subroutine_clear
    @caller = []
  end
  #--------------------------------------------------------------------------
  # ○ 条件分岐
  #--------------------------------------------------------------------------
  alias _cao_subroutine_command_111 command_111
  def command_111
    if @params[0] == 12 && subroutine_name?(@params[1])
      @branch[@indent] = false
      command_skip
    else
      _cao_subroutine_command_111
    end
  end
  #--------------------------------------------------------------------------
  # ◎ 分岐終了
  #--------------------------------------------------------------------------
  def command_412
    return if @caller.empty?
    index, indent = @caller[-1]
    return if @indent != indent
    @index = index
    @caller.pop
  end
  #--------------------------------------------------------------------------
  # ● サブルーチン？
  #--------------------------------------------------------------------------
  def subroutine_name?(label_name)
    label_name.start_with?(CAO::Subroutine::PREFIX)
  end
  #--------------------------------------------------------------------------
  # ○ ラベルジャンプ
  #--------------------------------------------------------------------------
  alias _cao_subroutine_command_119 command_119
  def command_119
    label_name = @params[0]
    if label_name == CAO::Subroutine::RETURN
      if @caller.empty?
        raise "サブルーチンの呼び出し元が見つかりません"
      else
        @index, @indent = @caller.pop
      end
    elsif subroutine_name?(label_name)
      @list.each_with_index do |command,i|
        next if command.code != 111
        next if command.parameters[0] != 12
        next if command.parameters[1] != label_name
        @caller << [@index, @indent]
        @index = i
        return
      end
    else
      _cao_subroutine_command_119
    end
  end
end
