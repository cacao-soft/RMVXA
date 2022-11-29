#******************************************************************************
#
#    ＊ セルフ変数
#
#  --------------------------------------------------------------------------
#    バージョン ： 0.1.0
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#   ： イベント毎に保持する変数を追加します。
#
#  --------------------------------------------------------------------------
#   == 注意事項 ==
#
#    ※ 数値入力などの結果をセルフ変数に受け取ることはできません
#
#  --------------------------------------------------------------------------
#   == 使用方法 ==
#
#    ★ セルフ変数の操作
#     設定された範囲の変数がセルフ変数と認識されるため
#     通常の変数と同じ方法で操作できます。
#     0 を代入することで削除できます。セーブデータを圧迫しません。
#
#    ★ スクリプト
#     $game_variables[variable_id]
#       実行された場面で通常の変数かセルフ変数かを自動判定します。
#
#     $game_variables[key]
#       セルフ変数へ直接アクセスします。
#       key:
#         マップイベント  [map_id, event_id, variable_id]
#         コモンイベント  [-event_id, 0, variable_id]
#         バトルイベント  [0, troop_id, variable_id]
#
#******************************************************************************


#==============================================================================
# ◆ ユーザー設定
#==============================================================================
module SELFVAR
  #--------------------------------------------------------------------------
  # ◇ セルフ変数として扱う変数の範囲
  #--------------------------------------------------------------------------
  RANGE = 1..5
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Message
  #--------------------------------------------------------------------------
  # ● テキストの追加
  #--------------------------------------------------------------------------
  alias _cao_self_variables_add add
  def add(text)
    _cao_self_variables_add(text)
    @texts[-1] = @texts[-1].gsub("\\", "\e").tap {|s|
      s.gsub!(/\eV\[(\d+)\]/i) { $game_variables[$1.to_i] }
      s.gsub!(/\eV\[(\d+)\]/i) { $game_variables[$1.to_i] }
      s.gsub!("\e", "\\")
    }
  end
end
class Game_Variables
  #--------------------------------------------------------------------------
  # ● 変数の取得
  #--------------------------------------------------------------------------
  def [](variable_id)
    key = get_event_key(variable_id)
    if key
      @data2[key]
    else
      @data[variable_id] || 0
    end
  end
  #--------------------------------------------------------------------------
  # ● 変数の設定
  #--------------------------------------------------------------------------
  def []=(variable_id, value)
    key = get_event_key(variable_id)
    if key
      if value == 0
        @data2.delete(key)
      else
        @data2[key] = value
      end
      # @data2[key] = value
    else
      @data[variable_id] = value
    end
    on_change
  end
  private
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def get_event_key(variable_id)
    @data2 ||= Hash.new(0)
    if variable_id.is_a?(Array)
      return variable_id
    elsif SELFVAR::RANGE === variable_id
      if $game_party.in_battle              # バトルイベント
        # [0, troop_id, variable_id]
        return [0, $game_troop.instance_variable_get(:@troop_id), variable_id]
      elsif $game_map.current_event_id < 0  # コモンイベント
        # [-event_id, 0, variable_id]
        return [-$game_map.current_event_id, 0, variable_id]
      elsif $game_map.current_event_id > 0  # マップイベント
        # [map_id, event_id, variable_id]
        return [$game_map.map_id, $game_map.current_event_id, variable_id]
      end
    end
    return nil
  end
end
class Game_Map
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :current_event_id         # 実行中のイベントID
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_self_variables_initialize initialize
  def initialize
    _cao_self_variables_initialize
    @current_event_id = 0
  end
  #--------------------------------------------------------------------------
  # ● セットアップ
  #--------------------------------------------------------------------------
  alias _cao_self_variables_setup setup
  def setup(map_id)
    @current_event_id = 0
    _cao_self_variables_setup(map_id)
  end
  #--------------------------------------------------------------------------
  # ● 自動実行のコモンイベントを検出／セットアップ
  #--------------------------------------------------------------------------
  alias _cao_self_variables_setup_autorun_common_event setup_autorun_common_event
  def setup_autorun_common_event
    event = _cao_self_variables_setup_autorun_common_event
    @interpreter.common_event_id = event.id if event
    event
  end
end
class Game_Event < Game_Character
  #--------------------------------------------------------------------------
  # ● イベントページの条件合致判定
  #--------------------------------------------------------------------------
  alias _cao_self_variables_conditions_met? conditions_met?
  def conditions_met?(page)
    $game_map.current_event_id = @id
    _cao_self_variables_conditions_met?(page)
  end
end
class Game_CommonEvent
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    if @interpreter
      unless @interpreter.running?
        @interpreter.setup(@event.list)
        @interpreter.common_event_id = @event.id
      end
      @interpreter.update
    end
  end
end
class Game_Interpreter
  attr_accessor :common_event_id
  #--------------------------------------------------------------------------
  # ● クリア
  #--------------------------------------------------------------------------
  alias _cao_self_variables_clear clear
  def clear
    _cao_self_variables_clear
    @common_event_id = 0
  end
  #--------------------------------------------------------------------------
  # ● ファイバーの作成
  #--------------------------------------------------------------------------
  alias _cao_self_variables_create_fiber create_fiber
  def create_fiber
    _cao_self_variables_create_fiber
    if @fiber && $game_temp.common_event_reserved?
      @common_event_id = $game_temp.reserved_common_event.id
    end
  end
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    if @fiber
      $game_map.current_event_id =
        (@common_event_id == 0 ? @event_id : -@common_event_id)
      @fiber.resume
      $game_map.current_event_id = 0
    end
  end
end
