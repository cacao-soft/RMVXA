#******************************************************************************
#
#    ＊ ＜拡張＞ ＥＶ出現条件
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.0.0
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#   ： 注釈を使用してイベントの出現条件を拡張します。
#
#  --------------------------------------------------------------------------
#   == 使用方法 ==
#
#    ★ 出現条件の設定
#     イベントコマンド「注釈」の１行目に <出現条件> と入力してください。
#    ※ このコマンドは、必ずページの先頭で設定してください。
#    ※ 続けて注釈を設定すると、出現条件の設定の続きと解釈されます。
#
#    ★ 条件の書き方
#     原則、１行１条件で記述します。
#     条件の末尾に | を記述すると、条件を満たしていなくても次の条件を評価し、
#     条件を満たすときは、次の条件を無視します。
#     条件の末尾に \ を記述すると、次の行も同行とみなします。
#
#    ★ 組み合わせ
#     スイッチ[番号] op 真偽値
#     スイッチ[番号] op スイッチ[番号]
#     変数[番号] op 数値
#     変数[番号] op 変数[番号]
#    ※ 演算子(op)には、== != < <= => > の６種類が使用できます。
#
#    ★ スクリプト
#     条件の先頭に ? を記述するとスクリプトで記述されたとみなします。
#
#    ★ 設定例
#     スイッチ[1] == ON
#     変数[3] == 123
#     ? $game_variables[6] == "あいうえお"
#
#    ※ プリセットでは想定されない条件が設定できます。
#       条件を満たしてもイベントが更新されない場合は、条件に関連するイベントの
#       後に $game_map.need_refresh = true を実行してマップを更新してください。
#
#******************************************************************************


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Event
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  TRIGGER_S = /^<出現条件>/
  TRIGGER_E = /^<条件終了>/

  CP_OPERATOR = / *(==|!=|<|<=|=>|>|&&|\|\|) */
  CP_TRUE     = /真|TRUE|ON|有/i
  CP_FALSE    = /偽|FALSE|OFF|無/i

  CP_SSWITCHE = /(?:SS|セルフスイッチ)\[([ABCD])\]/i
  CP_SWITCHE  = /(?:S|スイッチ)\[(\d+)\]/i
  CP_VARIABLE = /(?:V|変数)\[(\d+)\]/i
  CP_GOLD     = /お金|ゴールド|所持金/i
  CP_ITEM     = /アイテム数\[(\d+)\]/i
  CP_WEAPON   = /武器数\[(\d+)\]/i
  CP_ARMOR    = /防具数\[(\d+)\]/i
  CP_ITEM2    = /アイテム\[(\d+)\]/i
  CP_WEAPON2  = /武器\[(\d+)\]/i
  CP_ARMOR2   = /防具\[(\d+)\]/i
  CP_ITEM3    = /(?:I|アイテム)\[(\d+)\]:([_0-9a-z!?]+)/i
  CP_WEAPON3  = /(?:W|武器)\[(\d+)\]:([_0-9a-z!?]+)/i
  CP_ARMOR3   = /(?:A|防具)\[(\d+)\]:([_0-9a-z!?]+)/i
  CP_ACTOR    = /(?:C|キャラ|アクター)\[(\d+)\]:([_0-9a-z!?]+)/i
  CP_PARTY    = /(?:P|パーティ)\[(\d+)\]:([_0-9a-z!?]+)/i
  CP_VEHICLE  = /移動タイプ|乗り物/i
  CP_VEHICLE2 = /(歩行|徒歩|小型船|大型船|飛行船)/i
  CP_TIME     = /時間\[(\d+), *(\d+), *(\d+)\]/
  CP_TIMER    = /タイマー動作/i
  CP_TIMER2   = /タイマー/i

  VEHICLE_TYPE = {
    "歩行"=>:walk, "徒歩"=>:walk,
    "小型船"=>:boat, "大型船"=>:ship, "飛行船"=>:airship
  }

  REGEXP_EVAL = /^[?]/i
  #--------------------------------------------------------------------------
  # ● 特殊文字の変換
  #--------------------------------------------------------------------------
  def convert_special_characters(s)
    s.strip!
    s.gsub!(CP_TRUE)     { true }
    s.gsub!(CP_FALSE)    { false }
    s.gsub!(CP_SSWITCHE) { $game_self_switches[[@map_id, @event.id, $1]] }
    s.gsub!(CP_SWITCHE)  { $game_switches[$1.to_i] }
    s.gsub!(CP_VARIABLE) { $game_variables[$1.to_i] }
    s.gsub!(CP_GOLD)     { $game_party.gold }
    s.gsub!(CP_ITEM)     { $game_party.item_number($data_items[$1.to_i]) }
    s.gsub!(CP_WEAPON)   { $game_party.item_number($data_weapons[$1.to_i]) }
    s.gsub!(CP_ARMOR)    { $game_party.item_number($data_armors[$1.to_i]) }
    s.gsub!(CP_ITEM2)    { $game_party.has_item?($data_items[$1.to_i], true) }
    s.gsub!(CP_WEAPON2)  { $game_party.has_item?($data_weapons[$1.to_i], true) }
    s.gsub!(CP_ARMOR2)   { $game_party.has_item?($data_armors[$1.to_i], true) }
    s.gsub!(CP_ITEM3)    { $data_items[$1.to_i].__send__($2) }
    s.gsub!(CP_WEAPON3)  { $data_weapons[$1.to_i].__send__($2) }
    s.gsub!(CP_ARMOR3)   { $data_armors[$1.to_i].__send__($2) }
    s.gsub!(CP_ACTOR)    { $game_actors[$1.to_i].__send__($2) }
    s.gsub!(CP_PARTY)    { $game_party.members[$1.to_i + 1].__send__($2) }
    s.gsub!(CP_VEHICLE)  { $game_player.instance_eval('@vehicle_type') }
    s.gsub!(CP_VEHICLE2) { VEHICLE_TYPE[$1] }
    s.gsub!(CP_TIME)     { $1.to_i * 3600 + $2.to_i * 60 + $3.to_i }
    s.gsub!(CP_TIMER)    { $game_timer.working? }
    s.gsub!(CP_TIMER2)   { $game_timer.sec }
    return s
  end
  #--------------------------------------------------------------------------
  # 〇 イベントページの条件合致判定
  #--------------------------------------------------------------------------
  alias _cao_ex_conditions_met? conditions_met?
  def conditions_met?(page)
    @_conditions_note = ""
    @_conditions_skip = false
    fcmd = page.list.first
    if fcmd.code == 108 && fcmd.parameters.first[TRIGGER_S]
      page.list[1..-1].each do |c|
        break if c.code != 108 && c.code != 408
        text = c.parameters.first
        break if text[TRIGGER_E]
        case text[-1]
        when "\\"
          @_conditions_note << text.chop
          next
        when "|"
          if @_conditions_skip
            @_conditions_note = ""
            next
          end
          if conditions_note_met?(@_conditions_note + text.chop)
            @_conditions_skip = true
          end
          next
        end
        next if conditions_note_met?(@_conditions_note + text)
        return false
      end
    end
    return _cao_ex_conditions_met?(page)
  end
  #--------------------------------------------------------------------------
  # ● イベントページの条件合致判定
  #--------------------------------------------------------------------------
  def conditions_note_met?(t)
    @_conditions_note = ""
    if @_conditions_skip
      @_conditions_skip = false
      return true
    end
    return eval(t[1..-1]) if t[REGEXP_EVAL]
    params = t.split(CP_OPERATOR).each {|s| convert_special_characters(s) }
    return params.empty? ? true : eval(params.join)
  rescue
    msgbox_p $!, t, params
    return false
  end
end
