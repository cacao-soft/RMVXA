#******************************************************************************
#
#    ＊ 行動範囲の設定
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.0.0
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#    ： プレイヤー、イベントの行動範囲をリージョンで制限する機能を追加します。
#    ： 指定されたエリア内でのみ移動できる「行動可能エリア」を追加します。
#    ： 指定されたエリアに移動できない「進入禁止エリア」を追加します。
#
#  --------------------------------------------------------------------------
#   == 注意事項 ==
#
#    ※ Game_CharacterBase#passable? を再定義しています。
#
#  --------------------------------------------------------------------------
#   == 使用方法 ==
#
#    ★ プレイヤーの行動範囲を設定
#     行動可能エリア : $game_player.activity_area = [id]
#     進入禁止エリア : $game_player.ropedoff_area = [id]
#
#    ★ イベントの行動範囲を設定
#     行動可能エリア : $game_map.events[n].activity_area = [id]
#     進入禁止エリア : $game_map.events[n].ropedoff_area = [id]
#     ※ スクリプトでの設定は、一時的なものです。通常は、注釈をお使いください。
#
#     注釈に『行動可能エリア：id』
#     注釈に『進入禁止エリア：id』
#     複数のエリアを設定する場合は、(,)で区切ってください。
#     この設定は、ページごとに適用されます。
#
#    ※ エリアの設定には、リージョンを使用します。
#    ※ リージョンの設定を行っていないタイルのリージョンＩＤは 0 です。
#
#
#******************************************************************************


class Game_CharacterBase
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor  :activity_area         # 行動可能エリアIDの配列
  attr_accessor  :ropedoff_area         # 進入禁止エリアIDの配列
  #--------------------------------------------------------------------------
  # ○ 通行可能判定
  #     d : 方向（2,4,6,8）
  #--------------------------------------------------------------------------
  def passable?(x, y, d)
    x2 = $game_map.round_x_with_direction(x, d)
    y2 = $game_map.round_y_with_direction(y, d)
    return false unless $game_map.valid?(x2, y2)
    return true if @through || debug_through?
    return false if ropedoff_area?(x2, y2)
    return false unless map_passable?(x, y, d)
    return false unless map_passable?(x2, y2, reverse_dir(d))
    return false if collide_with_characters?(x2, y2)
    return false unless activity_area?(x2, y2)
    return true
  end
  #--------------------------------------------------------------------------
  # ● 行動エリア内判定
  #     x : X 座標
  #     y : Y 座標
  #--------------------------------------------------------------------------
  def activity_area?(x, y)
    return true if @activity_area.nil? || @activity_area.empty?
    return @activity_area.include?($game_map.region_id(x, y))
  end
  #--------------------------------------------------------------------------
  # ● 禁止エリア内判定
  #     x : X 座標
  #     y : Y 座標
  #--------------------------------------------------------------------------
  def ropedoff_area?(x, y)
    return false if @ropedoff_area.nil? || @ropedoff_area.empty?
    return @ropedoff_area.include?($game_map.region_id(x, y))
  end
end

class Game_Event
  #--------------------------------------------------------------------------
  # ○ イベントページの設定をクリア
  #--------------------------------------------------------------------------
  alias _cao_restricted_area_clear_page_settings clear_page_settings
  def clear_page_settings
    _cao_restricted_area_clear_page_settings
    @activity_area = []
    @ropedoff_area = []
  end
  #--------------------------------------------------------------------------
  # ○ イベントページの設定をセットアップ
  #--------------------------------------------------------------------------
  alias _cao_restricted_area_setup_page_settings setup_page_settings
  def setup_page_settings
    _cao_restricted_area_setup_page_settings
    @list.each do |cmd|
      next if cmd.code != 108 && cmd.code != 408
      case cmd.parameters[0]
      when /^行動可能エリア：(\d+(?:,\s*\d+)*)/
        @activity_area = $1.split(/,\s*/).collect {|item| item.to_i }
      when /^進入禁止エリア：(\d+(?:,\s*\d+)*)/
        @ropedoff_area = $1.split(/,\s*/).collect {|item| item.to_i }
      end
    end
  end
end
