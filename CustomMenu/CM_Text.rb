#******************************************************************************
#
#    ＊ テキストウィンドウ
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.1.0
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： http://cacaosoft.webcrow.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#    ： テキストを表示するウィンドウを追加します。
#
#  --------------------------------------------------------------------------
#   == 注意事項 ==
#
#    ※ このスクリプトの動作には、Custom Menu Base が必要です。
#
#
#******************************************************************************


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO::CM::Text
  #--------------------------------------------------------------------------
  # ◇ ウィンドウの設定
  #--------------------------------------------------------------------------
  CONFIGURATION = {}    # <= 消さない！
  CONFIGURATION[:sample] = {
    :window  => [112, 88, 320, 240],
    :visible => "$game_switches[17]",
    :open    => 48,
    :text    => <<'EOS'
\C[16]\L[296,1,S]\I[125]\C[0]テストメッセージ\Y[+8]
\C[16]変数１番 : \C[0]\V[1]
\C[16]スイッチ１７番 : \C[0]\S[17,ON,OFF]
\C[16]戦闘回数 : \C[0]<% $game_system.battle_count %> \C[16]回\C[0]
EOS
  }
end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Window_MenuText < Window_Selectable
  include CAO::CM::Text
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  begin
    DATA_TEXTS = load_data("Data/cmText.rvdata2")
  rescue Errno::ENOENT
    DATA_TEXTS = {}
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  attr_accessor :command_window
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def initialize(ident)
    @ident = ident
    if params[:back] && !params[:back].empty?
      @background_sprite = Sprite.new
      @background_sprite.bitmap = Cache.system(params[:back])
    end
    super(*params[:window][0, 4])
    self.z = params[:window][4] || self.z
    self.opacity = params[:back] ? 0 : 255
    if params[:visible] == nil
      self.openness = 255
    else
      self.openness = eval(params[:visible].to_s) ? 255 : 0
    end
    
    if params[:slide]
      @slide = Slide.new(ident)
      self.x = @slide.x
      self.y = @slide.y
      self.openness = 255
    end
    @canvas = CAO::CM::Canvas.new(self)
    @frame_count = Graphics.frame_count % Graphics.frame_rate
    update_background
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def dispose
    super
    @background_sprite.dispose if @background_sprite
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def update
    super
    update_visible
    update_frame
    update_background
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ開閉
  #--------------------------------------------------------------------------
  def update_visible
    if params[:visible] && !@opening && !@closing
      if eval(params[:visible].to_s)
        open if close?
      else
        close if open?
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def update_frame
    # フレーム更新
    if params[:frame]
      @frame_count += 1
      if params[:frame] < @frame_count
        refresh
        @frame_count -= params[:frame]
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def update_background
    return unless @background_sprite
    @background_sprite.x = self.x
    @background_sprite.y = self.y
    @background_sprite.z = self.z
    @background_sprite.visible = self.openness == 255
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def params
    return CONFIGURATION[@ident]
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def param_text
    if params[:text]
      if params[:text].is_a?(Symbol)
        return DATA_TEXTS[params[:text]] || ""
      else
        return params[:text]
      end
    else
      return DATA_TEXTS[@ident] || ""
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def open
    super
    @slide.open if @slide
    self
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def close
    super
    @slide.close if @slide
    self
  end
  
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def open?
    return super unless @slide
    return @slide.open?
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def close?
    return super unless @slide
    return @slide.close?
  end
  #--------------------------------------------------------------------------
  # ● 開く処理の更新
  #--------------------------------------------------------------------------
  def update_open
    if @slide
      update_slide
    else
      self.openness += params[:open] ? params[:open] : 255
    end
    @opening = false if open?
  end
  #--------------------------------------------------------------------------
  # ● 閉じる処理の更新
  #--------------------------------------------------------------------------
  def update_close
    if @slide
      update_slide
    else
      self.openness -= params[:open] ? params[:open] : 255
      @closing = false if close?
    end
    if @command_window && close?
      @command_window.unlock.activate
      @command_window = nil
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def update_slide
    return unless @slide
    @slide.update
    self.x = @slide.x
    self.y = @slide.y
    @opening = false if @slide.open?
    @closing = false if @slide.close?
  end
  
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    @canvas.draw_text_ex(0, 0, param_text)
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def set_cancel_handler(method)
    return if handle?(:cancel)
    if method
      set_handler(:cancel, method)
    else
      @handler.delete(:cancel)
    end
  end
  #--------------------------------------------------------------------------
  # ● キャンセルハンドラの呼び出し
  #--------------------------------------------------------------------------
  def call_cancel_handler
    @handler[:cancel].call(@ident) if handle?(:cancel)
  end
end

class Window_MenuText::Slide
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  attr_reader :x, :y, :wx, :wy, :ox, :oy, :cx, :cy, :sx, :sy, :ex, :ey
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def initialize(ident)
    @config = CAO::CM::Text::CONFIGURATION[ident]
    
    @ox, @oy, @cx, @cy = @config[:slide]
    @wx, @wy, @ww, @wh = *@config[:window][0, 4]
    
    xx = @wx - (Graphics.width - @wx)
    yy = @wy - (Graphics.height - @wy)
    @sx = @ox < 0 ? Graphics.width  : @ox > 0 ? xx : @wx
    @sy = @oy < 0 ? Graphics.height : @oy > 0 ? yy : @wy
    
    @ex = @cx < 0 ? xx : @cx > 0 ? Graphics.width  : @wx
    @ey = @cy < 0 ? yy : @cy > 0 ? Graphics.height : @wy
    
    if @config[:visible] == nil || eval(@config[:visible].to_s)
      @x = @wx
      @y = @wy
    else
      @x = @sx
      @y = @sy
    end
    
    @opening = false  # 開いているフラグ
    @closing = false  # 閉じているフラグ
  end
  
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def update
    if @opening
      @x += @ox
      @y += @oy
      @x = @wx if @ox < 0 ? @x <= @wx : @x >= @wx
      @y = @wy if @oy < 0 ? @y <= @wy : @y >= @wy
      @opening = false if @x == @wx && @y == @wy
    elsif @closing
      @x += @cx
      @y += @cy
      @x = @ex if @cx < 0 ? @x <= @ex : @x >= @ex
      @y = @ey if @cy < 0 ? @y <= @ey : @y >= @ey
      if @x == @ex && @y == @ey
        @x = @sx
        @y = @sy
        @closing = false
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def open
    @opening = true
    @closing = false
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def close
    @opening = false
    @closing = true
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def open?
    return false if @opening
    return false if @closing
    return false if @x != @wx || @y != @wy
    return true
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def close?
    return false if @opening
    return false if @closing
    return true  if @x == @sx && @y == @sy
    return true  if @x == @ex && @y == @ey
    return false
  end
end

class Scene_Menu
  #--------------------------------------------------------------------------
  # ● オプションウィンドウの作成
  #--------------------------------------------------------------------------
  alias _cao_cm_text_create_option_window create_option_window
  def create_option_window
    _cao_cm_text_create_option_window
    @text_windows = {}
    CAO::CM::Text::CONFIGURATION.each_key do |ident|
      param = CAO::CM::Text::CONFIGURATION[ident]
      if param[:create].nil? ? true : eval(param[:create].to_s)
        @text_windows[ident] = Window_MenuText.new(ident)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● オプションウィンドウの更新
  #--------------------------------------------------------------------------
  alias _cao_cm_text_update_option_window update_option_window
  def update_option_window 
    _cao_cm_text_update_option_window
    @text_windows.each_value {|wnd| wnd.update }
  end
  #--------------------------------------------------------------------------
  # ● オプションウィンドウの解放
  #--------------------------------------------------------------------------
  alias _cao_cm_text_dispose_option_window dispose_option_window
  def dispose_option_window 
    _cao_cm_text_dispose_option_window
    @text_windows.each_value {|wnd| wnd.dispose }
  end
  #--------------------------------------------------------------------------
  # ○ コマンド実行後の処理
  #--------------------------------------------------------------------------
  alias _cao_cm_text_post_terminate post_terminate
  def post_terminate
    _cao_cm_text_post_terminate
    if current_console.current_data.refresh_items.include?(:text)
      @text_windows.each_value {|w| w.refresh }
    end
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def show_text_window(ident)
    current_console.lock.deactivate
    @text_windows[ident].set_cancel_handler(method(:close_text_window))
    @text_windows[ident].open
    @text_windows[ident].activate
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def close_text_window(ident)
    @text_windows[ident].command_window = current_console
    # @text_windows[ident].set_cancel_handler(nil)
    @text_windows[ident].close
    @text_windows[ident].deactivate
  end
  #--------------------------------------------------------------------------
  # ● 
  #--------------------------------------------------------------------------
  def oc_text_window(ident)
    @text_windows[ident].open  if @text_windows[ident].close?
    @text_windows[ident].close if @text_windows[ident].open?
  end
end
