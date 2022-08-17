#******************************************************************************
#
#    ＊ 前後通行可能タイル
#
#  --------------------------------------------------------------------------
#    バージョン ： 0.0.1
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#   ： 大きいキャラの上に柵などの☆タイルが表示されないようにする
#
#  --------------------------------------------------------------------------
#   == 使用方法 ==
#
#    タイルセットの通行設定で☆ブロックと下方向の通行禁止を設定します
#
#
#******************************************************************************


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Map
  attr_accessor :__map_data
  #--------------------------------------------------------------------------
  # ● セットアップ
  #--------------------------------------------------------------------------
  alias _cao_both_setup setup
  def setup(map_id)
    @__map_data = nil
    _cao_both_setup(map_id)
  end
  #--------------------------------------------------------------------------
  # ● 通行チェック
  #     bit : 調べる通行禁止ビット
  #--------------------------------------------------------------------------
  def check_passage(x, y, bit)
    all_tiles(x, y).each do |tile_id|
      flag = tileset.flags[tile_id]
      next if tile_id == 0
      next if flag & 0x10 != 0 && flag & bit == 0 # [☆] : 通行に影響しない
      return true  if flag & bit == 0     # [○] : 通行可
      return false if flag & bit == bit   # [×] : 通行不可
    end
    return false                          # 通行不可
  end
  #--------------------------------------------------------------------------
  # ● 指定座標にあるタイル ID の取得
  #--------------------------------------------------------------------------
  def tile_id(x, y, z)
    unless @__map_data
      @__map_data = Table.new(@map.width, @map.height)
    end
    if z != 2
      @map.data[x, y, z]
    elsif @map.data[x, y, z] == 0
      @__map_data[x, y]
    else
      id = @map.data[x, y, z]
      if tileset.flags[id] & 0x0010 == 0x0010
        @__map_data[x, y], @map.data[x, y, z] = id, 0
      end
      id
    end || 0
  end
end
class Sprite_Tile
  def initialize(tile_id, tilemap)
    @sprite = nil
    @tile_id = tile_id
    @tilemap = tilemap
    index = tile_id % 256
    @tile_x = (index / 128 * 8 + index % 8) * 32
    @tile_y = index / 8 % 16 * 32
    set_base_point(0, 0, 0, 0)
  end
  def create_sprite
    @sprite = Sprite.new(@tilemap.viewport)
    @sprite.bitmap = @tilemap.bitmaps[@tile_id / 256 + 5]
    @sprite.src_rect.set(@tile_x, @tile_y, 32, 32)
    @sprite.z = 100
    @sprite.ox = @ox
    @sprite.oy = @oy
  end
  def dispose
    if @sprite
      @sprite.dispose
      @sprite = nil
    end
  end
  def set_base_point(x, y, ox = nil, oy = nil)
    @ox = ox if ox
    @oy = oy if oy
    @base_x = x + @ox
    @base_y = y + @oy
    self
  end
  def in_screen?
    return false if @x < -16
    return false if @y < 0
    return false if @x >= Graphics.width + 16
    return false if @y >= Graphics.height + 32
    return true
  end
  def update
    @x = @base_x - @tilemap.ox
    @y = @base_y - @tilemap.oy
    if in_screen?
      create_sprite unless @sprite
    else
      dispose if @sprite
    end
    if @sprite
      @sprite.x = @x
      @sprite.y = @y
      @sprite.update
    end
  end
end
class Tilemap_Both
  def initialize(tilemap)
    @sprites = []
    @tilemap = tilemap
  end
  def refresh
    dispose
    $game_map.height.times do |y|
      $game_map.width.times do |x|
        tile_id = $game_map.tile_id(x, y, 2)
        next if @tilemap.map_data[x, y, 2] == tile_id
        @sprites <<
          Sprite_Tile.new(tile_id, @tilemap).set_base_point(x * 32, y * 32, 16, 32)
      end
    end
  end
  def update
    @sprites.each(&:update)
  end
  def dispose
    @sprites.each(&:dispose)
    @sprites.clear
  end
end
class Spriteset_Map
  #--------------------------------------------------------------------------
  # ● タイルセットのロード
  #--------------------------------------------------------------------------
  alias _cao_both_load_tileset load_tileset
  def load_tileset
    _cao_both_load_tileset
    @tilemap2 ||= Tilemap_Both.new(@tilemap)
    @tilemap2.refresh
  end
  #--------------------------------------------------------------------------
  # ● タイルマップの解放
  #--------------------------------------------------------------------------
  alias _cao_both_dispose_tilemap dispose_tilemap
  def dispose_tilemap
    @tilemap2.dispose
    _cao_both_dispose_tilemap
  end
  #--------------------------------------------------------------------------
  # ● タイルマップの更新
  #--------------------------------------------------------------------------
  alias _cao_both_update_tilemap update_tilemap
  def update_tilemap
    _cao_both_update_tilemap
    @tilemap2.update
  end
end
