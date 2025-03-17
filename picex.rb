#******************************************************************************
#
#    ＊ ＜拡張＞ ピクチャの操作
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.0.3
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#   ： ピクチャに関する機能を拡張します。
#
#  --------------------------------------------------------------------------
#   == 注意事項 ==
#
#   ※ ピクチャと同時にウィンドウが作成されるようになります。
#
#
#******************************************************************************


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
  module PicEx
    #--------------------------------------------------------------------------
    # ◇ フォント設定
    #--------------------------------------------------------------------------
    FONTS    = {}
    FONTS[0] = nil
    FONTS[1] = "ＭＳ ゴシック"
    FONTS[2] = ["ＭＳ 明朝", 28, :OF, :ST]
    FONTS[3] = ["", 0, "00FF00"]
    #--------------------------------------------------------------------------
    # ◇ ウィンドウの初期設定
    #--------------------------------------------------------------------------
    STDW_PADDING     = 12             # 余白
    STDW_BACKOPACITY = 192            # ウィンドウの不透明度
    #--------------------------------------------------------------------------
    # ◇ 文字描画の設定
    #--------------------------------------------------------------------------
    AOC_FONT_SIZE = 4                 # 制御文字 \{ \} による変化量
    WLH_MARGIN = 4                    # 文字の行幅 (上下の空間)
  end # module PicEx
  end # module CAO


  #/////////////////////////////////////////////////////////////////////////////#
  #                                                                             #
  #                下記のスクリプトを変更する必要はありません。                 #
  #                                                                             #
  #/////////////////////////////////////////////////////////////////////////////#


  module Cache
    #--------------------------------------------------------------------------
    # ● 空のビットマップを作成
    #--------------------------------------------------------------------------
    def self.nil_bitmap
      @cache[nil] = Bitmap.new(32, 32) unless include?(nil)
      return @cache[nil]
    end
  end

  class Rect
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def to_a
      return [self.x, self.y, self.width, self.height]
    end
  end

  class Bitmap
    #--------------------------------------------------------------------------
    # ● ウィンドウの描画
    #     x, y, width, height, {windowskin = nil, tone = nil, opacity = 192}
    #--------------------------------------------------------------------------
    #     windowskin : (nil)    デフォルトのスキン画像を使用 ("Window")
    #                : (String) スキン画像のファイル名 (Graphics/System 内のもの)
    #                : (Bitmap) スキン画像
    #--------------------------------------------------------------------------
    def draw_window(*args)
      case args.size
      when 0
        x, y, width, height = 0, 0, self.width, self.height
        windowskin, tone, opacity = nil, nil, nil
      when 1
        x, y, width, height = 0, 0, self.width, self.height
        windowskin = _load_windowskin(args[0][:windowskin])
        tone       = args[0][:tone]
        opacity    = args[0][:opacity]
      when 2
        x, y, width, height = args[0].to_a
        windowskin = _load_windowskin(args[1][:windowskin])
        tone       = args[1][:tone]
        opacity    = args[1][:opacity]
      when 4
        x, y, width, height = args[0..3]
        windowskin, tone, opacity = nil, nil, nil
      when 5
        x, y, width, height = args[0..3]
        windowskin = _load_windowskin(args[4][:windowskin])
        tone       = args[4][:tone]
        opacity    = args[4][:opacity]
      else
        # TODO:
      end
      windowskin ||= _load_windowskin(nil)
      tone       ||= $game_system.window_tone
      opacity    ||= 192

      buffer1 = Bitmap.new(width, height)
      buffer2 = Bitmap.new(width, height)

      # 背景の描画
      sr = Rect.new(0, 0, 64, 64)
      dr = Rect.new(0, 0, width, height)
      buffer1.stretch_blt(dr, windowskin, sr)
      buffer1.add_synthesis(tone.red, tone.green, tone.blue) if tone
      buffer1.blur
      buffer2.blt(0, 0, buffer1, buffer1.rect)
      dr.set(2, 2, width - 4, height - 4)
      buffer1.clear
      buffer1.stretch_blt(dr, buffer2, buffer2.rect)
      sr.set(0, 64, 64, 64)
      (width / 64 + 1).times do |x|
        (height / 64 + 1).times do |y|
          buffer1.blt(x * 64 + 2, y * 64 + 2, windowskin, sr)
        end
      end
      buffer1.clear_rect(width - 2, 0, 2, height)
      buffer1.clear_rect(0, height - 2, width, 2)
      self.blt(x, y, buffer1, buffer1.rect, opacity)

      # フレームの描画
      buffer1.clear
      ((width - 32) / 32 + 1).times do |i|
        sr.set(80, 0, 32, 16)   # 上
        buffer1.blt(i*32+16, 0, windowskin, sr)
        sr.set(80, 48, 32, 16)  # 下
        buffer1.blt(i*32+16, height-16, windowskin, sr)
      end
      ((height - 32) / 32 + 1).times do |i|
        sr.set(64, 16, 16, 32)  # 左
        buffer1.blt(0, i * 32 + 16, windowskin, sr)
        sr.set(112, 16, 16, 32) # 右
        buffer1.blt(width - 16, i * 32 + 16, windowskin, sr)
      end
      buffer1.clear_rect(width - 16, 0, 16, 16)
      buffer1.clear_rect(0, height - 16, 16, 16)
      buffer1.clear_rect(width - 16, height - 16, 16, 16)
      sr.set(0, 0, 16, 16)
      4.times do |i|
        sr.x = i % 2 * 48 + 64
        sr.y = i / 2 * 48
        buffer1.blt(i % 2 * (width - 16), i / 2 * (height - 16), windowskin, sr)
      end
      self.blt(x, y, buffer1, buffer1.rect)

      # バッファの解放
      buffer1.dispose
      buffer2.dispose
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def add_synthesis(red, green, blue)
      self.width.times do |x|
        self.height.times do |y|
          c = get_pixel(x, y)
          c.red   += red
          c.green += green
          c.blue  += blue
          c.red   = 0 if c.red < 0
          c.green = 0 if c.green < 0
          c.blue  = 0 if c.blue < 0
          set_pixel(x, y, c)
        end
      end
    end
    #--------------------------------------------------------------------------
    # ● ウィンドウスキン画像に変換
    #--------------------------------------------------------------------------
    def _load_windowskin(param)
      case param
      when nil
        return Cache.system("Window")
      when String
        return Cache.system(param)
      when Bitmap
        return param
      else
        msg = "wrong argument type #{param.class} (expected String)"
        raise TypeError, msg, caller(2).first
      end
    end
    private :_load_windowskin
  end

  class CAO::PicEx::Bitmap
    #--------------------------------------------------------------------------
    # ● 公開インスタンス変数
    #--------------------------------------------------------------------------
    attr_reader   :type                     # 画像読み込みタイプ
    attr_reader   :width                    # 画像の横幅
    attr_reader   :height                   # 画像の縦幅
    attr_reader   :text                     # 描画テキスト
    attr_accessor :need_refresh             # 更新要求
    #--------------------------------------------------------------------------
    # ● オブジェクト初期化
    #--------------------------------------------------------------------------
    def initialize
      clear_instance_variables
    end
    #--------------------------------------------------------------------------
    # ● インスタンス変数のクリア
    #--------------------------------------------------------------------------
    def clear_instance_variables
      @text = ""

      @width = 0
      @height = 0

      @type = nil
      @filname = ""
      @index = 0
      @hue = 0

      @window_option = nil

      @need_refresh = false
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def clear
      clear_instance_variables
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def refresh
      @need_refresh = true
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def none?
      return @type == nil
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def create(width, height, options = nil)
      clear_instance_variables
      @type = :bitmap
      @width = width
      @height = height
      if options.kind_of?(Hash)
        @type = :window
        @window_option = options
      end
      @need_refresh = true
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def load(type, filename, index = 0, hue = 0)
      clear_instance_variables
      @type = type
      @filname = filename
      @index = index
      @hue = hue
      @need_refresh = true
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def bitmap
      case @type
      when :bitmap
        source = nil
      when :window
        source = Bitmap.new(@width, @height)
        source.draw_window(@window_option)
      when :picture
        bitmap = Cache.picture(@filname)
        source = Bitmap.new(bitmap.width, bitmap.height)
        source.blt(0, 0, bitmap, bitmap.rect)
      when :icon
        source = Bitmap.new(24, 24)
        rect = Rect.new(@index % 16 * 24, @index / 16 * 24, 24, 24)
        source.blt(0, 0, Cache.system("Iconset"), rect)
      when :system
        bitmap = Cache.system(@filname)
        source = Bitmap.new(bitmap.width, bitmap.height)
        source.blt(0, 0, bitmap, bitmap.rect)
      when :battler
        bitmap = Cache.battler(@filname, 0)
        source = Bitmap.new(bitmap.width, bitmap.height)
        source.blt(0, 0, bitmap, bitmap.rect)
      when :parallax
        bitmap = Cache.parallax(@filname)
        source = Bitmap.new(bitmap.width, bitmap.height)
        source.blt(0, 0, bitmap, bitmap.rect)
      when :character
        bitmap = Cache.character(@filname)
        sign = @filname[/^[\!\$]./]
        if sign && sign.include?('$')
          cw, ch = bitmap.width / 3, bitmap.height / 4
        else
          cw, ch = bitmap.width / 12, bitmap.height / 8
        end
        source = Bitmap.new(cw, ch)
        rect = Rect.new((@index%4*3+1)*cw, (@index/4*4)*ch, cw, ch)
        source.blt(0, 0, bitmap, rect)
      when :face
        source = Bitmap.new(96, 96)
        rect = Rect.new(@index % 4 * 96, @index / 4 * 96, 96, 96)
        source.blt(0, 0, Cache.face(@filname), rect)
      else
        # TODO:
      end
      if source
        result = Bitmap.new(source.width, source.height)
        result.blt(0, 0, source, source.rect)
        result.hue_change(@hue) if @hue != 0
        source.dispose
      else
        result = Bitmap.new(@width, @height)
      end
      @width, @height = result.width, result.height
      return result
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def set_text(*texts)
      @text = texts.join("\n")
      @need_refresh = true
    end
  end

  class CAO::PicEx::Window
    #--------------------------------------------------------------------------
    # ● 公開インスタンス変数
    #--------------------------------------------------------------------------
    attr_reader   :width                    # ウィンドウの横幅
    attr_reader   :height                   # ウィンドウの縦幅
    attr_reader   :skin_name                # ウィンドウスキン名
    attr_reader   :tone                     # ウィンドウカラー
    attr_reader   :contents_width           # ウィンドウ内容の横幅
    attr_reader   :contents_height          # ウィンドウ内容の縦幅
    attr_reader   :text                     # 描画テキスト
    attr_accessor :padding                  # ウィンドウ余白
    attr_accessor :contents_x               # ウィンドウ内容のｘ座標
    attr_accessor :contents_y               # ウィンドウ内容のｙ座標
    attr_accessor :back_opacity             # ウィンドウ背景の不透明度
    attr_accessor :need_refresh             # 更新要求
    #--------------------------------------------------------------------------
    # ● オブジェクト初期化
    #--------------------------------------------------------------------------
    def initialize
      @tone = Tone.new
      clear_instance_variables
    end
    #--------------------------------------------------------------------------
    # ● インスタンス変数のクリア
    #--------------------------------------------------------------------------
    def clear_instance_variables
      @text = ""

      @width = 0
      @height = 0
      @contents_x = 0
      @contents_y = 0
      @contents_width = 0
      @contents_height = 0
      @padding = standard_padding

      @skin_name = "Window"
      @tone.set($game_system.window_tone)
      @back_opacity = standard_back_opacity

      @need_refresh = false
      @created = false
      @visible = true
    end
    #--------------------------------------------------------------------------
    # ● 標準パディングサイズの取得
    #--------------------------------------------------------------------------
    def standard_padding
      return CAO::PicEx::STDW_PADDING
    end
    #--------------------------------------------------------------------------
    # ● 標準の取得
    #--------------------------------------------------------------------------
    def standard_back_opacity
      return CAO::PicEx::STDW_BACKOPACITY
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def clear
      clear_instance_variables
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def refresh
      @need_refresh = true
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def none?
      return !@created
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def create(*args)
      clear_instance_variables
      case args.size
      when 2,3
        @width, @height = *args
        @padding = args[2] || standard_padding
        @contents_width = @width - (@padding * 2)
        @contents_height = @height - (@padding * 2)
      when 4,5
        @width, @height, @contents_width, @contents_height = *args
        @padding = args[4] || standard_padding
      else
        # TODO:
        raise
      end
      @created = true
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def windowskin(filename = nil, tone = nil)
      @skin_name = filename if filename
      @tone.set(*tone)      if tone
      return @skin_name.empty? ? Cache.nil_bitmap : Cache.system(@skin_name)
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def resize(width, height)
      @width  = width
      @height = height
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def resize_contents(width, height)
      @contents_width  = width
      @contents_height = height
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def set_text(*texts)
      @text = texts.join("\n")
      @need_refresh = true
    end
  end

  module Pictures
  class << self
    include Enumerable
    #--------------------------------------------------------------------------
    # ● Game_Picture の参照
    #--------------------------------------------------------------------------
    def [](pic_id)
      if pic_id.is_a?(Range)
        return pic_id.map {|id| self[id] }
      else
        if $game_party.in_battle
          return $game_troop.screen.pictures[pic_id]
        else
          return $game_map.screen.pictures[pic_id]
        end
      end
    end
    #--------------------------------------------------------------------------
    # ● イテレータ
    #--------------------------------------------------------------------------
    def each
      pics = ($game_party.in_battle ? $game_troop : $game_map).screen.pictures
      if block_given?
        pics.each {|picture| yield picture }
      else
        pics.instance_variable_get(:@data).compact.each
      end
    end
    #--------------------------------------------------------------------------
    # ● すべてのピクチャを消去
    #--------------------------------------------------------------------------
    def erase
      self.each {|picture| picture.erase }
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def save(filename, *pics)
      unless Bitmap.method_defined?(:save)
        msgbox "画像保存スクリプトを導入してください。"
        return
      end

      spriteset = SceneManager.scene.instance_variable_get(:@spriteset)
      sprites = spriteset.instance_variable_get(:@picture_sprites).select do |sp|
        sp && !sp.bitmap.disposed? &&
        pics.include?(sp.instance_variable_get(:@picture).number)
      end

      if sprites.empty?
        msgbox "ピクチャが表示されていません。"
      else
        # 画像サイズの算出
        rect = Rect.new(sprites[0].x, sprites[0].y, 0, 0)
        sprites.each do |sp|
          rect.x = sp.x if rect.x > sp.x
          rect.y = sp.y if rect.y > sp.y
          x2 = sp.x + sp.bitmap.width
          y2 = sp.y + sp.bitmap.height
          rect.width  = x2 if rect.width  < x2
          rect.height = y2 if rect.height < y2
        end
        # 画像保存
        buffer = Bitmap.new(rect.width - rect.x, rect.height - rect.y)
        sprites.each do |sp|
          dr = Rect.new
          dr.x = sp.x - rect.x
          dr.y = sp.y - rect.y
          dr.width = sp.bitmap.width * sp.zoom_x
          dr.height = sp.bitmap.height * sp.zoom_y
          buffer.stretch_blt(dr, sp.bitmap, sp.bitmap.rect, sp.opacity)
        end
        buffer.save(filename, :PNG)
      end
    end
  end # class << self
  end # module Pictures

  class Game_Picture
    #--------------------------------------------------------------------------
    # ● 公開インスタンス変数
    #--------------------------------------------------------------------------
    attr_reader   :bitmap                   # 画像の設定
    attr_reader   :window                   # ウィンドウの設定
    attr_accessor :mirror                   # 反転
    attr_accessor :angle                    # 回転角度
    #--------------------------------------------------------------------------
    # ● オブジェクト初期化
    #--------------------------------------------------------------------------
    alias _cao_picex_initialize initialize
    def initialize(number)
      _cao_picex_initialize(number)
      init_ext
    end
    #--------------------------------------------------------------------------
    # ● 拡張の初期化
    #--------------------------------------------------------------------------
    def init_ext
      @mirror = false
      @window = CAO::PicEx::Window.new
      @bitmap = CAO::PicEx::Bitmap.new
      @assocpic_id = 0
    end
    #--------------------------------------------------------------------------
    # ● ピクチャの表示
    #--------------------------------------------------------------------------
    alias _cao_picex_show show
    def show(name, origin, x, y, zoom_x, zoom_y, opacity, blend_type)
      erase
      _cao_picex_show(name, origin, x, y, zoom_x, zoom_y, opacity, blend_type)
    end
    #--------------------------------------------------------------------------
    # ● 消去済み？
    #--------------------------------------------------------------------------
    def erased?
      return false unless @name.empty?
      return false unless @window.none?
      return false unless @bitmap.none?
      return true
    end
    #--------------------------------------------------------------------------
    # ● ピクチャが表示されていないか判定
    #--------------------------------------------------------------------------
    alias none? erased?
    #--------------------------------------------------------------------------
    # ● ピクチャの消去
    #--------------------------------------------------------------------------
    alias _cao_picex_erase erase
    def erase
      _cao_picex_erase
      @mirror = false
      @assocpic_id = 0
      @window.clear
      @bitmap.clear
      refresh
    end
    #--------------------------------------------------------------------------
    # ● ピクチャの反転
    #--------------------------------------------------------------------------
    def reverse
      @mirror = !@mirror
    end
    #--------------------------------------------------------------------------
    # ● ピクチャの可視状態の取得
    #--------------------------------------------------------------------------
    def visible
      return @opacity != 0
    end
    #--------------------------------------------------------------------------
    # ● ピクチャの可視状態の設定
    #--------------------------------------------------------------------------
    def visible=(value)
      @opacity = value ? 255 : 0
    end
    #--------------------------------------------------------------------------
    # ● ピクチャを id に関連付け
    #--------------------------------------------------------------------------
    def assoc(id)
      @assocpic_id = id
    end
    #--------------------------------------------------------------------------
    # ● ピクチャの関連付けを解除
    #--------------------------------------------------------------------------
    def dissoc
      @assocpic_id = 0
    end
    #--------------------------------------------------------------------------
    # ● ピクチャに param を関連付け
    #--------------------------------------------------------------------------
    def <<(param)
      case param
      when Integer
        Pictures[param].assoc(@number)
      when Array
        param.each {|id| Pictures[id].assoc(@number) }
      when Game_Picture
        param.assoc(@number)
      else
        # TODO:
      end
      return self
    end
    #--------------------------------------------------------------------------
    # ● 関連ピクチャとｘ座標を同期
    #--------------------------------------------------------------------------
    def x
      return @x if @assocpic_id == 0
      pic = Pictures[@assocpic_id]
      return @x + pic.x if pic.origin == 0
      obj = (pic.width == 0) ? Cache.picture(pic.name) : pic
      return @x + pic.x - (obj.width / 2)
    end
    #--------------------------------------------------------------------------
    # ● 関連ピクチャとｙ座標を同期
    #--------------------------------------------------------------------------
    def y
      return @y if @assocpic_id == 0
      pic = Pictures[@assocpic_id]
      return @y + pic.y if pic.origin == 0
      obj = (pic.height == 0) ? Cache.picture(pic.name) : pic
      return @y + pic.y - (obj.height / 2)
    end
    #--------------------------------------------------------------------------
    # ● ピクチャの横幅
    #--------------------------------------------------------------------------
    def width
      return @window.none? ? @bitmap.width : @window.width
    end
    #--------------------------------------------------------------------------
    # ● ピクチャの縦幅
    #--------------------------------------------------------------------------
    def height
      return @window.none? ? @bitmap.height : @window.height
    end
    #--------------------------------------------------------------------------
    # ● ピクチャの移動
    #--------------------------------------------------------------------------
    def pos(x, y, origin = nil)
      @origin = origin if origin
      @x = x.to_f
      @y = y.to_f
    end
    #--------------------------------------------------------------------------
    # ● ピクチャの拡大
    #--------------------------------------------------------------------------
    def zoom(zoom_x, zoom_y = nil)
      if zoom_y
        @zoom_x = zoom_x.to_f
        @zoom_y = zoom_y.to_f
      else
        @zoom_x = zoom_x.to_f
        @zoom_y = zoom_x.to_f
      end
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def load(type, filename, index = 0, hue = 0)
      @bitmap.load(type, filename, index, hue)
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def refresh
      @window.refresh
      @bitmap.refresh
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def target(duration, argh)
      init_target
      if argh.kind_of?(Hash)
        @target_zoom_x = @target_zoom_y = argh[:zoom].to_f if argh[:zoom]
        @origin         = argh[:o]            if argh[:o]
        @target_x       = argh[:x].to_f       if argh[:x]
        @target_y       = argh[:y].to_f       if argh[:y]
        @target_zoom_x  = argh[:zoom_x].to_f  if argh[:zoom_x]
        @target_zoom_y  = argh[:zoom_y].to_f  if argh[:zoom_y]
        @target_opacity = argh[:opacity].to_f if argh[:opacity]
      end
      @duration = (duration < 1) ? 1 : duration
    end
  end

  class Game_Interpreter
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def picex_text_picture
      return nil unless next_event_code == 405
      return nil unless @list[@index + 1].parameters[0][/^<PICEX(\d+)([BW])>/i]
      case $2.upcase
      when 'B'; return Pictures[$1.to_i].bitmap
      when 'W'; return Pictures[$1.to_i].window
      end
      return nil
    end
    #--------------------------------------------------------------------------
    # ● スクロール文章の表示
    #--------------------------------------------------------------------------
    alias _cao_picex_command_105 command_105
    def command_105
      picture = picex_text_picture
      if picture
        @index += 1
        ary = []
        while next_event_code == 405
          @index += 1
          ary << @list[@index].parameters[0]
        end
        picture.set_text(ary)
      else
        _cao_picex_command_105
      end
    end
  end

  class Canvas_Picture < Window_Base
    #--------------------------------------------------------------------------
    # ● オブジェクト初期化
    #--------------------------------------------------------------------------
    def initialize(bitmap, text)
      @bitmap = bitmap
      @text = text#.dup
      refresh
    end
    #--------------------------------------------------------------------------
    # ● ウィンドウ内容の取得
    #--------------------------------------------------------------------------
    def contents
      return @bitmap
    end
    #--------------------------------------------------------------------------
    # ● ウィンドウスキンの取得
    #--------------------------------------------------------------------------
    def windowskin
      return Cache.system("Window")
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def default_pos
      return { :x => 0, :y => 0, :height => line_height, :align => 0, :lh => [] }
    end
    #--------------------------------------------------------------------------
    # ● リフレッシュ
    #--------------------------------------------------------------------------
    def refresh
      self.contents.clear
      texts = @text.split(/\r?[\n]|\\n/)
      pos = default_pos
      pos[:lh] = texts.map {|s| calc_line_height(convert_escape_characters(s)) }
      reset_font_settings
      texts.each do |text|
        text = convert_escape_characters(text)
        pos[:x] = calc_line_start_x(text, pos[:align])
        pos[:height] = calc_line_height(text)
        process_character(text.slice!(0, 1), text, pos) until text.empty?
        pos[:y] += pos[:height]
        pos[:lh].shift
      end
    end
    #--------------------------------------------------------------------------
    # ● 文字色コードをカラーへ変換
    #--------------------------------------------------------------------------
    def str2color(value)
      case value
      when Color
        return value
      when Array
        return Color.new(*value)
      when Integer
        num = value
      when Symbol, String
        text = value.to_s.sub(/^(0x|x)/, "")
        case text.size
        when 1; text = text * 6 << 'FF'
        when 2; text = text[0] * 6 << text[1] * 2
        when 3; text = text[0] * 2 << text[1] * 2 << text[2] * 2 << 'FF'
        when 4; text = text[0] * 2 << text[1] * 2 << text[2] * 2 << text[3] * 2
        when 6; text = text[0, 6] << 'FF'
        end
        num = eval("0x#{text}")
      end
      return Color.new(num >> 24, num >> 16 & 255, num >> 8 & 255, num & 255)
    end
    #--------------------------------------------------------------------------
    # ● プレイ時間を取得
    #--------------------------------------------------------------------------
    def play_time(format = '%3d:%02d:%02d')
      total = Graphics.frame_count / Graphics.frame_rate
      return sprintf(format,
        (total / 3600), (total / 60 % 60), (total % 60), (total / 60), total)
    end
    #--------------------------------------------------------------------------
    # ● 制御文字の事前変換
    #    実際の描画を始める前に、原則として文字列に変わるものだけを置き換える。
    #    文字「\」はエスケープ文字（\e）に変換。
    #--------------------------------------------------------------------------
    def convert_escape_characters(text)
      result = text.to_s.clone
      result.gsub!(/\r\n/)          { "\n" }
      result.gsub!(/\\/)            { "\e" }
      result.gsub!(/\e\e/)          { "\\" }
      result.gsub!(/\e({+)/i)       { "\e{" * $1.count("{") }
      result.gsub!(/\e(}+)/i)       { "\e}" * $1.count("}") }
      result.gsub!(/\eV\[(\d+)\]/i) { $game_variables[$1.to_i] }
      result.gsub!(/\eV\[(\d+)\]/i) { $game_variables[$1.to_i] }
      result.gsub!(/\eS\[(\d+),(.*?),(.*?)\]/i) { $game_switches[$1.to_i]?$2:$3 }
      result.gsub!(/\eN\[(\d+)\]/i) { actor_name($1.to_i) }
      result.gsub!(/\eP\[(\d+)\]/i) { party_member_name($1.to_i) }
      result.gsub!(/\eG/i)          { Vocab::currency_unit }
      result.gsub!(/\e\$/)          { $game_party.gold }
      result.gsub!(/\eW/)           { $game_party.steps }
      result.gsub!(/\eT\[(.+?)\]/i) { play_time($1) }
      result.gsub!(/\eT/i)          { play_time }
      result.gsub!(/\en/)           { "\n" }
      result.gsub!(/<%(.*?)%>/)     { eval($1) }
      result
    end
    #--------------------------------------------------------------------------
    # ● 制御文字の引数を破壊的に取得
    #--------------------------------------------------------------------------
    def obtain_escape_param(text)
      text.slice!(/^\[-?\d+\]/)[/-?\d+/].to_i rescue 0
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def obtain_escape_value(text, value)
      text.slice!(/^\[([+-]?\d+)([+-]?)\]/i)
      return value + $1.to_i if $2 == '+'
      return value - $1.to_i if $2 == '-'
      return $1.to_i
    end
    #--------------------------------------------------------------------------
    # ● 制御文字の処理
    #     code : 制御文字の本体部分（「\C[1]」なら「C」）
    #--------------------------------------------------------------------------
    def process_escape_character(code, text, pos)
      case code.upcase
      when 'C'
        change_color(text_color(obtain_escape_param(text)))
      when 'I'
        process_draw_icon(obtain_escape_param(text), pos)
      when '{'
        make_font_bigger
      when '}'
        make_font_smaller
      when 'X'
        pos[:x] = obtain_escape_value(text, pos[:x])
      when 'Y'
        pos[:y] = obtain_escape_value(text, pos[:y])
      when 'S'
        change_size(obtain_escape_param(text))
      when 'F'
        change_font(obtain_escape_param(text))
      when 'A'
        change_alignment(obtain_escape_param(text), text, pos)
      end
    end
    #--------------------------------------------------------------------------
    # ● フォント設定のリセット
    #--------------------------------------------------------------------------
    def reset_font_settings
      change_color(normal_color)
      contents.font.name      = Font.default_name
      contents.font.size      = Font.default_size
      contents.font.bold      = Font.default_bold
      contents.font.italic    = Font.default_italic
      contents.font.shadow    = Font.default_shadow
      contents.font.outline   = Font.default_outline
      contents.font.out_color = Font.default_out_color
    end
    #--------------------------------------------------------------------------
    # ● フォントを大きくする
    #--------------------------------------------------------------------------
    def make_font_bigger
      if contents.font.size + CAO::PicEx::AOC_FONT_SIZE <= 96
        contents.font.size += CAO::PicEx::AOC_FONT_SIZE
      end
    end
    #--------------------------------------------------------------------------
    # ● フォントを小さくする
    #--------------------------------------------------------------------------
    def make_font_smaller
      if contents.font.size - CAO::PicEx::AOC_FONT_SIZE >= 6
        contents.font.size -= CAO::PicEx::AOC_FONT_SIZE
      end
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def change_alignment(align, text, pos)
      case align
      when 0..2
        pos[:x] = calc_line_start_x(text, align)
        pos[:align] = align
      when 3
        pos[:y] += 0
      when 4
        pos[:y] += (self.contents.height - pos[:y] - pos[:lh].inject(:+)) / 2
      when 5
        pos[:y] = self.contents.height - pos[:height]
      end
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def calc_line_start_x(text, align)
      case align
      when 0
        return 0
      when 1
        return (self.contents.width - calc_line_width(text)) / 2
      when 2
        return self.contents.width - calc_line_width(text)
      end
    end
    #--------------------------------------------------------------------------
    # ● 行の幅を計算
    #--------------------------------------------------------------------------
    def calc_line_width(text)
      src_font = self.contents.font.dup
      text = text.dup
      pos = default_pos
      pos[:lh] = [pos[:height]]
      w = 0
      until text.empty?
        c = text.slice!(0, 1)
        if c == "\e"
          case obtain_escape_code(text).upcase
          when 'C'
            obtain_escape_param(text)
          when 'I'
            obtain_escape_param(text)
            w += 24
          when '{'
            make_font_bigger
          when '}'
            make_font_smaller
          when 'X', 'Y'
            obtain_escape_value(text, 0)
          when 'S'
            change_size(obtain_escape_param(text))
          when 'F'
            change_font(obtain_escape_param(text))
          when 'A'
            change_alignment(obtain_escape_param(text), text, pos)
          end
        else
          w += self.contents.text_size(c).width
        end
      end
      self.contents.font = src_font
      return w
    end
    #--------------------------------------------------------------------------
    # ● 行の高さを計算
    #--------------------------------------------------------------------------
    def calc_line_height(text)
      now_size = contents.font.size
      max_size = 0
      text = text.dup
      until text.empty?
        next if text.slice!(0) != "\e"
        case text.slice!(0).upcase
        when '{'
          now_size += CAO::PicEx::AOC_FONT_SIZE
        when '}'
          now_size -= CAO::PicEx::AOC_FONT_SIZE
        when 'S'
          now_size = obtain_escape_param(text)
        when 'F'
          param = CAO::PicEx::FONTS[obtain_escape_param(text)]
          now_size = Font.default_size if param == nil || param[1] == nil
          now_size = param[1] if param && param[1].kind_of?(Integer)
        end
        now_size = Font.default_size if now_size == 0
        now_size = [6, [now_size, 96].min].max
        max_size = now_size if max_size < now_size
      end
      max_size = contents.font.size if max_size == 0
      return max_size + CAO::PicEx::WLH_MARGIN
    end
    #--------------------------------------------------------------------------
    # ● テキスト描画色の変更
    #--------------------------------------------------------------------------
    def change_color(color, enabled = true)
      if block_given?
        last_color = self.contents.font.color.dup
        change_color(color, enabled)
        yield
        self.contents.font.color = last_color
      else
        self.contents.font.color.set(color)
        self.contents.font.color.alpha = translucent_alpha unless enabled
      end
    end
    #--------------------------------------------------------------------------
    # ● テキストサイズの変更
    #--------------------------------------------------------------------------
    def change_size(value)
      if block_given?
        last_size = self.contents.font.size
        change_size(value)
        yield
        self.contents.font.size = last_size
      else
        if value == 0
          self.contents.font.size = Font.default_size
        else
          self.contents.font.size = [6, [value, 96].min].max
        end
      end
    end
    #--------------------------------------------------------------------------
    # ● フォント設定の変更
    #--------------------------------------------------------------------------
    #     カラー設定では、シンボル使用不可。(オプションとの関係上)
    #--------------------------------------------------------------------------
    def change_font(id)
      params = CAO::PicEx::FONTS[id]
      case params
      when nil
        reset_font_settings
      when String
        self.contents.font.name = params.empty? ? Font.default_name : params
      else
        # フォント名
        if params[0].kind_of?(String)
          if params[0].empty?
            self.contents.font.name = Font.default_name
          else
            self.contents.font.name = params[0]
          end
        end
        # 文字サイズ
        if params[1].kind_of?(Integer)
          change_size(params[1])
        end
        # 文字カラー
        if params[2]
          if params[2].kind_of?(Integer)
            self.contents.font.color = text_color(params[2])
          elsif !params[2].kind_of?(Symbol)
            self.contents.font.color = str2color(params[2])
          end
        end
        # 縁取りカラー
        if params[3]
          if params[3].kind_of?(Integer)
            self.contents.font.out_color = text_color(params[3])
          elsif !params[3].kind_of?(Symbol)
            self.contents.font.out_color = str2color(params[3])
          end
        end
        # オプション
        params.select {|param| param.kind_of?(Symbol) }.each do |param|
          case param
          when :BT; self.contents.font.bold = true
          when :BF; self.contents.font.bold = false
          when :IT; self.contents.font.italic = true
          when :IF; self.contents.font.italic = false
          when :LT; self.contents.font.outline = true
          when :LF; self.contents.font.outline = false
          when :ST; self.contents.font.shadow = true
          when :SF; self.contents.font.shadow = false
          end
        end
      end
    end
  end

  class Window_Picture < Window_Base
    #--------------------------------------------------------------------------
    # ● オブジェクト初期化
    #--------------------------------------------------------------------------
    def initialize(window, viewport)
      @window = window
      super(0, 0, 0, 0)
      self.viewport = viewport
      hide
      refresh
    end
    #--------------------------------------------------------------------------
    # ● 解放
    #--------------------------------------------------------------------------
    def dispose
      self.contents.dispose unless disposed?
      super
    end
    #--------------------------------------------------------------------------
    # ● 標準パディングサイズの取得
    #--------------------------------------------------------------------------
    def standard_padding
      return @window.standard_padding
    end
    #--------------------------------------------------------------------------
    # ● ウィンドウ内容の幅を計算
    #--------------------------------------------------------------------------
    def contents_width
      return @window.contents_width
    end
    #--------------------------------------------------------------------------
    # ● ウィンドウ内容の高さを計算
    #--------------------------------------------------------------------------
    def contents_height
      return @window.contents_height
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def update
      super
      update_size
      update_padding
      update_scroll
      create_contents if resize_contents?
      # refresh if @window.need_refresh       # Sprite_Picture で行う
    end
    #--------------------------------------------------------------------------
    # ● の更新
    #--------------------------------------------------------------------------
    def update_size
      self.width  = @window.width  if self.width  != @window.width
      self.height = @window.height if self.height != @window.height
    end
    #--------------------------------------------------------------------------
    # ● パディングの更新
    #--------------------------------------------------------------------------
    def update_padding
      self.padding = @window.padding if self.padding != @window.padding
    end
    #--------------------------------------------------------------------------
    # ● の更新
    #--------------------------------------------------------------------------
    def update_scroll
      self.ox = @window.contents_x
      self.oy = @window.contents_y
    end
    #--------------------------------------------------------------------------
    # ● 色調の更新
    #--------------------------------------------------------------------------
    def update_tone
      self.tone.set(@window.tone)
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def resize_contents?
      return false if @window.none?
      return true  if self.contents.width  != @window.contents_width
      return true  if self.contents.height != @window.contents_height
      return false
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def refresh
      self.contents.clear
      unless @window.text.empty?
        Canvas_Picture.new(self.contents, @window.text)
      end
      @window.need_refresh = false
    end
  end

  class Sprite_Picture < Sprite
    #--------------------------------------------------------------------------
    # ● オブジェクト初期化
    #     picture : Game_Picture
    #--------------------------------------------------------------------------
    def initialize(viewport, picture)
      @picture = picture
      @picture.bitmap.need_refresh = true
      create_window(viewport)
      super(viewport)
      update
    end
    #--------------------------------------------------------------------------
    # ● 解放
    #--------------------------------------------------------------------------
    def dispose
      if @picture.erased?
        screen = ($game_party.in_battle ? $game_troop : $game_map).screen
        pictures = screen.instance_variable_get(:@pictures)
        pictures.instance_variable_get(:@data)[@picture.number] = nil
      end
      dispose_window
      dispose_bitmap
      super
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def dispose_bitmap
      self.bitmap.dispose if @last_bitmap_type
    end
    #--------------------------------------------------------------------------
    # ● フレーム更新
    #--------------------------------------------------------------------------
    alias _cao_picex_update update
    def update
      _cao_picex_update
      update_window
    end
    #--------------------------------------------------------------------------
    # ● 転送元ビットマップの更新
    #--------------------------------------------------------------------------
    def update_bitmap
      if @picture.bitmap.none?
        self.bitmap.dispose if @last_bitmap_type
        if @picture.name.empty?
          self.bitmap = Cache.nil_bitmap
        else
          self.bitmap = Cache.picture(@picture.name)
        end
        @picture.bitmap.need_refresh = false
      else
        if @picture.bitmap.need_refresh
          self.bitmap.dispose if self.bitmap
          self.bitmap = @picture.bitmap.bitmap
          unless @picture.bitmap.text.empty?
            Canvas_Picture.new(self.bitmap, @picture.bitmap.text)
          end
          @picture.bitmap.need_refresh = false
        end
      end
      @last_bitmap_type = @picture.bitmap.type
    end
    #--------------------------------------------------------------------------
    # ● その他の更新
    #--------------------------------------------------------------------------
    alias _cao_picex_update_other update_other
    def update_other
      _cao_picex_update_other
      self.mirror = @picture.mirror
    end
    #--------------------------------------------------------------------------
    # ● ウィンドウの生成
    #--------------------------------------------------------------------------
    def create_window(viewport)
      @window = Window_Picture.new(@picture.window, viewport)
    end
    #--------------------------------------------------------------------------
    # ● ウィンドウの解放
    #--------------------------------------------------------------------------
    def dispose_window
      @window.contents.dispose
      @window.dispose
    end
    #--------------------------------------------------------------------------
    # ● ウィンドウを表示
    #--------------------------------------------------------------------------
    def show_window
      @window.visible = true
    end
    #--------------------------------------------------------------------------
    # ● ウィンドウを隠す
    #--------------------------------------------------------------------------
    def hide_window
      @window.visible = false
    end
    #--------------------------------------------------------------------------
    # ● ウィンドウの更新
    #--------------------------------------------------------------------------
    def update_window
      if @picture.window.none?
        hide_window
      else
        show_window
        @window.update
        update_window_position
        update_window_other
      end
      update_window_contents
    end
    #--------------------------------------------------------------------------
    # ● ウィンドウ内容の更新
    #--------------------------------------------------------------------------
    def update_window_contents
      @window.refresh if @picture.window.need_refresh
    end
    #--------------------------------------------------------------------------
    # ● ウィンドウ位置の更新
    #--------------------------------------------------------------------------
    def update_window_position
      @window.x = @picture.x
      @window.y = @picture.y
      @window.z = @picture.number
      if @picture.origin == 0
        self.x += @picture.window.padding
        self.y += @picture.window.padding
      else
        @window.x -= @window.width / 2
        @window.y -= @window.height / 2
      end
    end
    #--------------------------------------------------------------------------
    # ● その他の更新
    #--------------------------------------------------------------------------
    def update_window_other
      @window.windowskin = @picture.window.windowskin
      @window.opacity = @picture.opacity
      @window.contents_opacity = @picture.opacity
      @window.back_opacity = @picture.window.back_opacity
      # Tone 更新は Window_Picture
    end
  end
