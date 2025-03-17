#******************************************************************************
#
#    ＊ プチスロット
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.0.0
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#    ： 最低限のスロット処理を実装します。
#
#  --------------------------------------------------------------------------
#   == 注意事項 ==
#
#    ※ 実行結果や音楽はイベントで実装する必要があります。
#
#  --------------------------------------------------------------------------
#   == 使用方法 ==
#
#    ★ プチスロットの開始
#     start_pslot(スロットID, オプション)
#
#     オプションは、以下のキーを持つハッシュ(省略可能)
#       :spd, :pos, :x, :y, :mx, my, :bg, :fg
#
#
#******************************************************************************


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
  module PSLOT
    #--------------------------------------------------------------------------
    # ◇ スロットのパターン
    #--------------------------------------------------------------------------
    #   PATTERN[ID] = [タイプ, ファイル名 or 文字サイズ, 背景, 前景, [リール]]
    #--------------------------------------------------------------------------
    PATTERN = {}    # <= 消さないように注意
    PATTERN[0] = [  # テキスト
      :text, 32, "", "",
      [1,7,0,4,2,6,3,5],
      [3,6,1,5,7,4,0,2],
      [5,0,6,4,2,7,3,1],
    ]
    PATTERN[2] = [  # アイコン
      :icon, nil, "", "",
      [184,185,186,187,188,189,190,191],
      [191,188,186,190,187,184,189,185],
      [188,184,189,191,186,190,185,187],
    ]
    PATTERN[3] = [  # リール１つ
      :text, 20, "", "",
      [8,9,10],
    ]
    #--------------------------------------------------------------------------
    # ◇ シンボル文字
    #--------------------------------------------------------------------------
    SYMBOL_TEXT = [ "７", "＠", "＊", "＃", "★", "▲", "◆", "◎" ]
    #--------------------------------------------------------------------------
    # ◇ デフォルトのスピード
    #--------------------------------------------------------------------------
    #   数値が大きいほど速くなる (小数可)
    #--------------------------------------------------------------------------
    DEFAULT_SPEED = 4
    #--------------------------------------------------------------------------
    # ◇ デフォルトの位置
    #--------------------------------------------------------------------------
    #   0: 画面中央, 1: プレイヤーの頭上, 2: イベントの頭上
    #--------------------------------------------------------------------------
    DEFAULT_POSITION = 1
    #--------------------------------------------------------------------------
    # ◇ リール停止時の効果音
    #--------------------------------------------------------------------------
    SOUND_REEL_STOP = "Decision3"
  end # module PSLOT
  end # module CAO


  #/////////////////////////////////////////////////////////////////////////////#
  #                                                                             #
  #                下記のスクリプトを変更する必要はありません。                 #
  #                                                                             #
  #/////////////////////////////////////////////////////////////////////////////#


  class << Sound
    #--------------------------------------------------------------------------
    # ● リールストップ効果音
    #--------------------------------------------------------------------------
    @@reel_stop = RPG::SE.new(CAO::PSLOT::SOUND_REEL_STOP)
    def play_reel_stop
      @@reel_stop.play
    end
  end

  class << SceneManager
    #--------------------------------------------------------------------------
    # ● 公開インスタンス変数
    #--------------------------------------------------------------------------
    attr_accessor :result                   # 最後のシーン実行結果
  end

  class Game_Interpreter
    #--------------------------------------------------------------------------
    # ● プチスロット開始
    #--------------------------------------------------------------------------
    def start_pslot(id, option = {})
      Fiber.yield while $game_message.visible
      SceneManager.call(Scene_PetitSlot)
      SceneManager.scene.prepare(id, option)
      Fiber.yield
    end
  end

  class Game_PetitSlot
    #--------------------------------------------------------------------------
    # ● 公開インスタンス変数
    #--------------------------------------------------------------------------
    attr_reader   :id                       #
    attr_reader   :mode                     #
    attr_reader   :reels                    #
    attr_accessor :speed                    #
    attr_reader   :x                        # スロットの基準ｘ座標
    attr_reader   :y                        # スロットの基準ｙ座標
    attr_reader   :foreground_name          #
    attr_reader   :background_name          #
    attr_reader   :symbol_number            # シンボルの数
    attr_reader   :reel_number              # リールの数
    attr_reader   :symbol_width             # シンボルの横幅
    attr_reader   :symbol_height            # シンボルの縦幅
    attr_reader   :font_size                #
    attr_reader   :symbol_name              #
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def initialize(id, option = {})
      params = CAO::PSLOT::PATTERN[id]

      @id = id
      @mode = params[0]

      @background_name = params[2]
      @foreground_name = params[3]

      @reels = params.drop(4)
      @symbol_number = @reels.max_by {|a| a.size }.size
      @reel_number = @reels.size

      init_symbol_size(params[1])
      init_options(option)
      init_position
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def init_options(option)
      @_x              = option[:x]
      @_y              = option[:y]
      @mx              = option[:mx]  || 0
      @my              = option[:my]  || 0
      @pos             = option[:pos] || CAO::PSLOT::DEFAULT_POSITION
      @background_name = option[:bg]  || @background_name
      @foreground_name = option[:fg]  || @foreground_name
      @speed = option[:speed] || option[:spd] || CAO::PSLOT::DEFAULT_SPEED
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def init_position
      if @_x == nil || @_y == nil
        calc_position
      else
        @x = @_x || 0
        @y = @_y || 0
      end
      @x += @mx
      @y += @my
    end
    #--------------------------------------------------------------------------
    # ● スロットの横幅
    #--------------------------------------------------------------------------
    def width
      return @symbol_width * @reel_number
    end
    #--------------------------------------------------------------------------
    # ● スロットの縦幅
    #--------------------------------------------------------------------------
    def height
      return @symbol_height
    end
    #--------------------------------------------------------------------------
    # ● 各リールの横幅
    #--------------------------------------------------------------------------
    def reel_width
      return @symbol_width
    end
    #--------------------------------------------------------------------------
    # ● 各リールの縦幅
    #--------------------------------------------------------------------------
    def reel_height
      return @symbol_height * @symbol_number
    end
    #--------------------------------------------------------------------------
    # ● リール画像の横幅 (複数で１つ)
    #--------------------------------------------------------------------------
    def reel_bitmap_width
      return @symbol_width * @reel_number
    end
    #--------------------------------------------------------------------------
    # ● リール画像の縦幅 (複数で１つ)
    #--------------------------------------------------------------------------
    def reel_bitmap_height
      return @symbol_height * @symbol_number + @symbol_height
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def show_window?
      return  @background_name && !show_background?
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def show_foreground?
      return @foreground_name && !@foreground_name.empty?
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def show_background?
      return @background_name && !@background_name.empty?
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def symbol(reel_index, index)
      return @reels[reel_index][0] if index == 0
      return @reels[reel_index][@symbol_number - index]
    end
    #--------------------------------------------------------------------------
    # ● シンボルサイズの計算
    #--------------------------------------------------------------------------
    def init_symbol_size(param)
      @font_size = Font.default_size
      @symbol_name = ""
      case @mode
      when :text
        @font_size = param if param > 0
        b = Bitmap.new(32, 32)
        b.font.size = @font_size
        r = b.text_size("あ")
        @symbol_width = r.width + 4
        @symbol_height = r.height + 4
        b.dispose
      when :image
        @symbol_name = param
        b = Cache.picture(@symbol_name)
        @symbol_width = b.width
        @symbol_height = b.width
      when :icon
        @symbol_width = 24
        @symbol_height = 24
      else
        raise "must not happen"
      end
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def calc_position
      case @pos
      when 1  # プレイヤー
        bitmap = Cache.character($game_player.character_name)
        sign = $game_player.character_name[/^[\!\$]./]
        ch = bitmap.height / (sign && sign.include?('$') ? 4 : 8)
        @x = $game_player.x * 32 + 16 - self.width / 2
        @y = $game_player.y * 32 - 4 - ch + 32 - self.height
      when 2  # イベント
        ev = $game_map.events[$game_map.interpreter.event_id]
        bitmap = Cache.character(ev.character_name)
        sign = ev.character_name[/^[\!\$]./]
        ch = bitmap.height / (sign && sign.include?('$') ? 4 : 8)
        @x = ev.x * 32 + 16 - self.width / 2
        @y = ev.y * 32 - 4 - ch + 32 - self.height
      else    # 画面中央
        @x = (Graphics.width - self.width) / 2
        @y = (Graphics.height - self.height) / 2
      end
    end
  end

  class Game_PetitSlotResult
    include Enumerable
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def initialize(data)
      @data = data
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def each
      if defined? yield
        @data.each {|n| yield n }
      else
        @data.each
      end
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def inspect
      "Result: #{complete?} - " + @data.inspect
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def [](index)
      @data[index]
    end
    #--------------------------------------------------------------------------
    # ● 絵柄の判定
    #--------------------------------------------------------------------------
    def match?(*args)
      if args[0].is_a?(Array)   # 引数が配列 match?([1, 2, 3]) 完全一致
        return @data == args[0]
      else                      # 引数が数値 match?(1, 2, 3)   順不同、全一致
        return false if @data.size != args.size
        return @data.sort == args.sort
      end
    rescue
      raise $!.class, $!.message, caller(1)
    end
    #--------------------------------------------------------------------------
    # ● すべて同じ絵柄か
    #--------------------------------------------------------------------------
    def complete?
      return @data.count(@data[0]) == @data.size
    end
    #--------------------------------------------------------------------------
    # ● すべて異なる絵柄か
    #--------------------------------------------------------------------------
    def irreg?
      return @data.size == @data.uniq.size
    end
    #--------------------------------------------------------------------------
    # ● 表示されている絵柄の数をハッシュで取得 (絵柄 => 数)
    #--------------------------------------------------------------------------
    def count_map
      hash = Hash.new(0)
      @data.each {|n| hash[n] = hash[n] + 1 }
      return hash
    end
  end

  class Sprite_PetitSlot < Sprite
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def initialize(pslot, reel_index, viewport)
      super(viewport)
      @reel_index = reel_index
      @pslot = pslot
      @stop_index = -1
      @real_y = Float(@pslot.reel_height)
      self.x = @pslot.reel_width * reel_index
      self.oy = @real_y
      create_bitmap
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def create_bitmap
      reel = (@pslot.reels[@reel_index] + [@pslot.reels[@reel_index][0]]).reverse!
      bitmap = Bitmap.new(@pslot.reel_bitmap_width, @pslot.reel_bitmap_height)
      rect = Rect.new(0, 0, @pslot.symbol_width, @pslot.symbol_height)
      case @pslot.mode
      when :text
        bitmap.font.size = @pslot.font_size
        reel.map! {|n| CAO::PSLOT::SYMBOL_TEXT[n] }
        reel.each_with_index do |c, i|
          rect.y = rect.height * i
          bitmap.draw_text(rect, c, 1)
        end
      when :image
        reel.each_with_index do |n, i|
          rect.y = n * rect.height
          bitmap.blt(0, rect.height * i, Cache.picture(@pslot.symbol_name), rect)
        end
      when :icon
        reel.each_with_index do |n, i|
          rect.x = n % 16 * rect.width
          rect.y = n / 16 * rect.height
          bitmap.blt(0, rect.height * i, Cache.system("Iconset"), rect)
        end
      else
        raise "must not happen"
      end
      self.bitmap = bitmap
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def dispose
      self.bitmap.dispose if self.bitmap
      super
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def update
      super
      return if stopping?
      @real_y -= @pslot.speed
      if selected? && @real_y <= @stop_index * @pslot.symbol_height
        self.oy = @stop_index * @pslot.symbol_height
      else
        @real_y += @pslot.reel_height if @real_y < 0
        self.oy = @real_y
      end
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def index
      return self.oy / @pslot.height
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def stop
      @stop_index = self.index
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def symbol
      @pslot.symbol(@reel_index, self.index)
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def selected?
      return @stop_index >= 0
    end
    #--------------------------------------------------------------------------
    # ● 停止中判定
    #--------------------------------------------------------------------------
    def stopping?
      return selected? && self.oy == @stop_index * @pslot.symbol_height
    end
  end

  class Spriteset_PetitSlotReel
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    attr_reader :viewport
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def initialize(pslot, z)
      @pslot = pslot
      @viewport = Viewport.new(0, 0, @pslot.width, @pslot.height)
      @viewport.z = z + 1
      create_background
      create_reel_sprite
      create_foreground
      move(@pslot.x, @pslot.y)
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def create_reel_sprite
      @reel_sprites = Array.new(@pslot.reel_number) do |i|
        Sprite_PetitSlot.new(@pslot, i, @viewport)
      end
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def create_background
      return unless @pslot.show_background?
      @background_sprite = Sprite.new
      @background_sprite.z = @viewport.z - 1
      @background_sprite.bitmap = Cache.picture(@pslot.background_name)
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def create_foreground
      return unless @pslot.show_foreground?
      @foreground_sprite = Sprite.new
      @foreground_sprite.z = @viewport.z + 1
      @foreground_sprite.bitmap = Cache.picture(@pslot.foreground_name)
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def dispose_background
      return unless @background_sprite
      @background_sprite.dispose
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def dispose_foreground
      return unless @foreground_sprite
      @foreground_sprite.dispose
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def move(x, y)
      @viewport.rect.x = x
      @viewport.rect.y = y
      if @background_sprite
        dw = (@pslot.width - @background_sprite.bitmap.width) / 2
        dh = (@pslot.height - @background_sprite.bitmap.height) / 2
        @background_sprite.x = x + dw
        @background_sprite.y = y + dh
      end
      if @foreground_sprite
        dw = (@pslot.width - @foreground_sprite.bitmap.width) / 2
        dh = (@pslot.height - @foreground_sprite.bitmap.height) / 2
        @foreground_sprite.x = x + dw
        @foreground_sprite.y = y + dh
      end
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def update
      @reel_sprites.each {|sp| sp.update }
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def dispose
      dispose_background
      dispose_foreground
      @reel_sprites.each {|sp| sp.dispose }
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def stopping?
      return @reel_sprites.all? {|sp| sp.stopping? }
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def selected?
      return @reel_sprites.all? {|sp| sp.selected? }
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def stop
      sp = @reel_sprites.find {|sp| !sp.selected? }
      sp.stop if sp
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def result
      @reel_sprites.map {|sp| sp.symbol }
    end
  end

  class Window_PetitSlot < Window_Selectable
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def initialize(pslot)
      @pslot = pslot
      super(0, 0, window_width, window_height)
      self.x = @pslot.x
      self.y = @pslot.y
      self.opacity = @pslot.show_window? ? 255 : 0
      activate
    end
    #--------------------------------------------------------------------------
    # ● ウィンドウ幅の取得
    #--------------------------------------------------------------------------
    def window_width
      return @pslot.width + standard_padding * 2
    end
    #--------------------------------------------------------------------------
    # ● ウィンドウ高さの取得
    #--------------------------------------------------------------------------
    def window_height
      return @pslot.height + standard_padding * 2
    end
    #--------------------------------------------------------------------------
    # ● パディングの更新
    #--------------------------------------------------------------------------
    def update_padding
      self.padding = 0
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def x=(value)
      super(value - standard_padding)
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def y=(value)
      super(value - standard_padding)
    end
    #--------------------------------------------------------------------------
    # ● 決定ボタンが押されたときの処理
    #--------------------------------------------------------------------------
    def process_ok
      Sound.play_reel_stop
      Input.update
      deactivate
      call_ok_handler
    end
  end

  class Scene_PetitSlot < Scene_MenuBase
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def initialize
      @background_bitmap = Graphics.snap_to_bitmap
    end
    #--------------------------------------------------------------------------
    # ● 準備
    #--------------------------------------------------------------------------
    def prepare(id, option)
      @pslot = Game_PetitSlot.new(id, option)
    end
    #--------------------------------------------------------------------------
    # ● 開始処理
    #--------------------------------------------------------------------------
    def start
      super
      @slot_window = Window_PetitSlot.new(@pslot)
      @reel_spriteset = Spriteset_PetitSlotReel.new(@pslot, @slot_window.z)
      move_slot(@pslot.x, @pslot.y)
      @slot_window.set_handler(:ok, method(:on_ok))
    end
    #--------------------------------------------------------------------------
    # ● 終了処理
    #--------------------------------------------------------------------------
    def terminate
      SceneManager.result = Game_PetitSlotResult.new(@reel_spriteset.result)
      super
      @reel_spriteset.dispose
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def update
      super
      @reel_spriteset.update
      if @reel_spriteset.stopping?
        Graphics.wait(Graphics.frame_rate / 2)
        return_scene
      end
    end
    #--------------------------------------------------------------------------
    # ● 背景の作成
    #--------------------------------------------------------------------------
    def create_background
      @background_sprite = Sprite.new
      @background_sprite.bitmap = @background_bitmap
    end
    #--------------------------------------------------------------------------
    # ● 背景の解放
    #--------------------------------------------------------------------------
    def dispose_background
      @background_bitmap.dispose
      @background_sprite.dispose
    end
    #--------------------------------------------------------------------------
    # ● トランジション速度の取得
    #--------------------------------------------------------------------------
    def transition_speed
      return 0
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def move_slot(x, y)
      @slot_window.x = x
      @slot_window.y = y
      @reel_spriteset.move(x, y)
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def on_ok
      @reel_spriteset.stop
      @slot_window.activate unless @reel_spriteset.selected?
    end
  end
