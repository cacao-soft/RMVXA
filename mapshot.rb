#******************************************************************************
#
#    ＊ マップショット
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.2.1
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#    ： マップを１枚の画像にして保存します。
#
#  --------------------------------------------------------------------------
#   == 注意事項 ==
#
#    ※ 画像の保存に『画像保存』スクリプトが必要になります。
#    ※ ゲーム配布時には、削除してください。
#    ※ 撮影時にプレイヤーは非表示になります。
#
#  --------------------------------------------------------------------------
#   == 使用方法 ==
#
#    ★ マップ画像の保存
#     マップ画面で F6 キーを押してください。
#     右下まで移動すると停止しますが、画像を保存しています。
#     画面が元に戻るまで、しばらくお持ちください。
#     画像は、ゲームフォルダに保存されます。
#
#    ★ マップ画像の保存 (スクリプト)
#     CAO::MapShot.start
#
#
#******************************************************************************


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
  module MapShot
    #--------------------------------------------------------------------------
    # ◇ マップ画面での撮影ボタン
    #--------------------------------------------------------------------------
    KEY = :F6
    #--------------------------------------------------------------------------
    # ◇ 撮影時プレイヤーを非表示
    #--------------------------------------------------------------------------
    PLAYER_TRANSPARENT = true
    #--------------------------------------------------------------------------
    # ◇ 保存名
    #--------------------------------------------------------------------------
    SAVE_NAME = "MapShot/%2$s(%5$d)_%3$d%4$d.png"
    #--------------------------------------------------------------------------
    # ◇ 経過をコンソールに表示
    #--------------------------------------------------------------------------
    SHOW_MESSAGE = true
    #--------------------------------------------------------------------------
    # ◇ 完了を告げるメッセージボックスを表示
    #--------------------------------------------------------------------------
    SHOW_MSGBOX = true
  end # module MapShot
  end # module CAO


  #/////////////////////////////////////////////////////////////////////////////#
  #                                                                             #
  #                下記のスクリプトを変更する必要はありません。                 #
  #                                                                             #
  #/////////////////////////////////////////////////////////////////////////////#


  module CAO::MapShot
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def self.start
      return unless SceneManager.scene_is?(Scene_Map)
      SceneManager.scene.map_shot
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def self.mkdir(path)
      return if FileTest.directory?(path)
      parent = path.split(/[\\\/]/)[0..-2].join('/')
      self.mkdir(parent) unless parent.empty? || FileTest.directory?(parent)
      Dir.mkdir(path)
    end
  end

  class Sprite_Character < Sprite_Base
    #--------------------------------------------------------------------------
    # ● フレーム更新
    #--------------------------------------------------------------------------
    def update_snap
      self.x = @character.screen_x
      self.y = @character.screen_y
      self.z = @character.screen_z
      self.visible = !@character.transparent
      if @balloon_duration > 0
        @balloon_sprite.x = x
        @balloon_sprite.y = y - height
        @balloon_sprite.z = z + 200
      end
    end
  end

  class Spriteset_Map
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def update_snap
      @tilemap.ox = $game_map.display_x * 32
      @tilemap.oy = $game_map.display_y * 32
      @parallax.ox = @tilemap.ox
      @parallax.oy = @tilemap.oy
      @character_sprites.each {|sprite| sprite.update_snap }
      airship = $game_map.airship
      @shadow_sprite.x = airship.screen_x
      @shadow_sprite.y = airship.screen_y + airship.altitude
      @shadow_sprite.opacity = airship.altitude * 8
      Graphics.update
    end
  end

  class Scene_Map < Scene_Base
    #--------------------------------------------------------------------------
    # ● フレーム更新
    #--------------------------------------------------------------------------
  if CAO::MapShot::KEY
    alias _cao_mapshot_update update
    def update
      _cao_mapshot_update
      map_shot if Input.press?(CAO::MapShot::KEY)
    end
  end # if CAO::MapShot::KEY
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def map_shot
      if CAO::MapShot::SHOW_MESSAGE
        puts " == マップ画像の保存 =="
      end
      # プレイヤーを非表示
      if CAO::MapShot::PLAYER_TRANSPARENT
        last_player_transparent = $game_player.transparent
        $game_player.transparent = true
        $game_player.followers.update
      end
      # マップの撮影
      format_arg = [$game_map.map_id, $data_mapinfos[$game_map.map_id].name]
      bitmap = Bitmap.new([$game_map.width * 32, Graphics.width * 10].min,
                          [$game_map.height * 32, Graphics.height * 13].min)
      screen_width = $game_map.screen_tile_x
      screen_height = $game_map.screen_tile_y
      bitmap_tile_x = bitmap.width / 32
      bitmap_tile_y = bitmap.height / 32
      cnt = 1
      ($game_map.height * 32 / bitmap.height.to_f).ceil.times do |by|
        ($game_map.width * 32 / bitmap.width.to_f).ceil.times do |bx|
          (bitmap_tile_y / screen_height.to_f).ceil.times do |y|
            (bitmap_tile_x / screen_width.to_f).ceil.times do |x|
              tile_x = screen_width * x + bitmap_tile_x * bx
              tile_y = screen_height * y + bitmap_tile_y * by
              $game_map.set_display_pos(tile_x, tile_y)
              @spriteset.update_snap
              dx = $game_map.display_x * 32 - bitmap.width * bx
              dy = $game_map.display_y * 32 - bitmap.height * by
              snap = Graphics.snap_to_bitmap
              bitmap.blt(dx, dy, snap, snap.rect)
            end
          end
          # マップ画像の保存
          format_arg[2] = bx
          format_arg[3] = by
          format_arg[4] = cnt
          filename = CAO::MapShot::SAVE_NAME % format_arg
          CAO::MapShot.mkdir(File.dirname(filename))
          if CAO::MapShot::SHOW_MESSAGE
            puts "[#{"%02d"%cnt}] #{filename}"
          end
          bitmap.save_png(filename)
          bitmap.clear
          cnt += 1
        end
      end
      if CAO::MapShot::SHOW_MESSAGE
        puts " == 保存完了 =="
      end
      if CAO::MapShot::SHOW_MSGBOX
        msgbox "Complete!"
        Input.update
      end
      # プレイヤーの状態を戻す
      if CAO::MapShot::PLAYER_TRANSPARENT
        $game_player.transparent = last_player_transparent
      end
      $game_player.center($game_player.x, $game_player.y)
      $game_player.update
    end
  end
