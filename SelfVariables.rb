#=============================================================================
#  [RGSS3] セルフ変数 - v0.0.2
# ---------------------------------------------------------------------------
#  Copyright (c) 2022 CACAO
#  Released under the MIT License.
#  https://opensource.org/licenses/MIT
# ---------------------------------------------------------------------------
#  [Twitter] https://twitter.com/cacao_soft/
#  [GitHub]  https://github.com/cacao-soft/
#=============================================================================

# セルフ変数の値はセルフスイッチに保存する
# 文章の表示系の制御文字で表示するには、別の変数に代入して表示する
# 数値入力などでは、セルフ変数に値を代入できない
# 戦闘時の動作は未確認

# セルフ変数として扱う範囲
SELF_VARIABLE_ID_RANGE = 1..5


class Game_Variables
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def clear_event
    @self_variable_key = nil
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def set_event(map_id, event_id)
    if map_id == 0 || event_id == 0
      clear_event
    else
      @self_variable_key = [map_id, event_id]
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def get_event_key(variable_id)
    if variable_id.is_a?(Array)
      variable_id
    elsif SELF_VARIABLE_ID_RANGE === variable_id && @self_variable_key
      @self_variable_key[2] = variable_id
      @self_variable_key
    else
      nil
    end
  end
  #--------------------------------------------------------------------------
  # ● 変数の取得
  #--------------------------------------------------------------------------
  def [](variable_id)
    key = get_event_key(variable_id)
    if key
      $game_self_switches.instance_variable_get(:@data)[key] || 0
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
      $game_self_switches.instance_variable_get(:@data)[key] = value
    else
      @data[variable_id] = value
    end
    on_change
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  def update
    if @fiber
      $game_variables.set_event(@map_id, @event_id)
      @fiber.resume
    else
      $game_variables.clear_event
    end
  end
end