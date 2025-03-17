#******************************************************************************
#
#    ＊ ＜拡張＞ 文章のスクロール表示
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.0.0
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： http://cacaosoft.webcrow.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#   ： イベントコマンド「文章のスクロール表示」でオプション指定可能にする
#
#  --------------------------------------------------------------------------
#   == 使用方法 ==
#
#    ★ オプションの指定
#     イベントコマンド「文章のスクロール表示」の先頭行を #! で始める。
#     各オプションは、半角空白で区切ります。
#
#    ★ オプション
#     noscroll: 自動スクロールを無効にし、上下ボタンで操作する。
#               Ｂボタンで閉じる。スクロール量は速度で変更可能。
#     window:   ウィンドウ枠を表示
#     arrow:    スクロール可否を示す矢印を表示
#     noover:   ウィンドウサイズを超える文章を破棄
#     stop:     下ボタンでスクロールを一時停止
#     cancel:   Ｂボタンで文章表示を終了
#     center:   文章を中央寄せ
#     right:    文章を右寄せ
#
#    ★ 特殊なオプション
#     このオプションは、他のオプションと併用できません。
#     skip: コメントと見なし、スキップする。
#     doc:  注釈と見なし、@comments に内容を保存する。
#     rgss: スクリプトと見なし、実行する。
#           さらに top オプションを加えるとトップレベルでの実行となる。
#
#******************************************************************************


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Message
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :scroll_no_scroll    # スクロール文章：自動スクロール無効
  attr_accessor :scroll_no_window    # スクロール文章：ウィンドウ枠非表示
  attr_accessor :scroll_no_arrow     # スクロール文章：枠矢印非表示
  attr_accessor :scroll_no_over      # スクロール文章：ウィンドウを超えない
  attr_accessor :scroll_no_cancel    # スクロール文章：キャンセルで閉じる
  attr_accessor :scroll_no_stop      # スクロール文章：一時停止
  attr_accessor :scroll_align        # スクロール文章：表示位置 (0-2)
  #--------------------------------------------------------------------------
  # ● クリア
  #--------------------------------------------------------------------------
  alias _cao_scrolltext_clear clear
  def clear
    _cao_scrolltext_clear
    clear_scrollex
  end
  #--------------------------------------------------------------------------
  # ● 拡張設定のクリア
  #--------------------------------------------------------------------------
  def clear_scrollex
    @scroll_no_scroll = false
    @scroll_no_window = true
    @scroll_no_arrow = true
    @scroll_no_over = false
    @scroll_no_cancel = true
    @scroll_no_stop = true
    @scroll_align = 0
  end
end
class Window_ScrollText < Window_Base
  #--------------------------------------------------------------------------
  # ● リセット
  #--------------------------------------------------------------------------
  def reset_window_settings
    self.opacity = $game_message.scroll_no_window ? 0 : 255
    self.arrows_visible = !$game_message.scroll_no_arrow
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    reset_window_settings
    reset_font_settings
    update_all_text_height
    create_contents
    draw_text_ex(4, 0, @text_ex)
    if $game_message.scroll_no_scroll
      self.oy = 0
    else
      self.oy = @scroll_pos = -height
    end
  end
  #--------------------------------------------------------------------------
  # ● 全テキストの描画に必要な高さを更新
  #--------------------------------------------------------------------------
  def update_all_text_height
    @text_ex = convert_escape_characters(@text)
    @text_heights = []
    @all_text_height = $game_message.scroll_no_scroll ? 0 : 1
    @text_ex.each_line do |line|
      height = calc_line_height(line, false)
      @text_heights << height
      @all_text_height += height
    end
    reset_font_settings
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ内容の高さを計算
  #--------------------------------------------------------------------------
  alias _cao_scrolltext_contents_height contents_height
  def contents_height
    if $game_message.scroll_no_over
      super
    else
      _cao_scrolltext_contents_height
    end
  end
  #--------------------------------------------------------------------------
  # ● メッセージの更新
  #--------------------------------------------------------------------------
  def update_message
    if $game_message.scroll_no_scroll
      over_height = contents.height - height
      if over_height > 0
        n = scroll_speed * 16
        oy = self.oy
        if Input.repeat?(:DOWN)
          oy += n
          oy = over_height if oy > over_height
        elsif Input.repeat?(:UP)
          oy -= n
          oy = 0 if oy < 0
        end
        self.oy = oy
      end
    elsif $game_message.scroll_no_stop || !Input.press?(:DOWN)
      @scroll_pos += scroll_speed
      self.oy = @scroll_pos
      terminate_message if @scroll_pos >= contents.height
    end
    terminate_message if cancel?
  end
  #--------------------------------------------------------------------------
  # ● キャンセル判定
  #--------------------------------------------------------------------------
  def cancel?
    return false unless Input.trigger?(:B)
    return true if $game_message.scroll_no_scroll
    return true unless $game_message.scroll_no_cancel
    return false
  end
  #--------------------------------------------------------------------------
  # ● 制御文字つきテキストの描画
  #--------------------------------------------------------------------------
  def draw_text_ex(x, y, text)
    reset_font_settings
    #text = convert_escape_characters(text)
    pos = {:x => x, :y => y, :new_x => x}
    @text_ex.each_line.with_index do |line,i|
      if $game_message.scroll_align != 0
        pos[:x] = contents_width - calc_line_width(line)
        pos[:x] -= $game_message.scroll_align == 1 ? pos[:x] / 2 : x
      end
      pos[:height] = @text_heights[i]#calc_line_height(line)
      process_character(line.slice!(0, 1), line, pos) until line.empty?
    end
  end
  #--------------------------------------------------------------------------
  # ● 行の幅を計算
  #     restore_font_size : 計算後にフォントサイズを元に戻す
  #--------------------------------------------------------------------------
  def calc_line_width(text, restore_font_size = true)
    result = 0
    last_font_size = contents.font.size
    text = text.clone
    until text.empty?
      c = text.slice!(0, 1)
      case c
      when "\n"   # 改行
        break
      when "\e"   # 制御文字
        case obtain_escape_code(text).upcase
        when 'C'
          obtain_escape_param(text)
        when 'I'
          obtain_escape_param(text)
          result += 24
        when '{'
          make_font_bigger
        when '}'
          make_font_smaller
        end
      else        # 普通の文字
        result += text_size(c).width
      end
    end
    contents.font.size = last_font_size if restore_font_size
    return result
  end
end
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● スクロール文章の表示
  #--------------------------------------------------------------------------
  alias _cao_scrolltext_command_105 command_105
  def command_105
    header = @list[@index+1].parameters[0]
    if header.start_with?("#!")
      @index += 1
      params = header[2..-1].split(" ").map(&:downcase)
      case params[0]
      when "skip"
        command_105_skip
        return
      when "doc"
        @comments = command_105_array
        return
      when "script", "rgss"
        command_105_script(params[1] == "top" ? TOPLEVEL_BINDING : binding)
        return
      else
        setup_scroll_text(params)
      end
    end
    _cao_scrolltext_command_105
  end
  #--------------------------------------------------------------------------
  # ● スクロール文章の表示のセットアップ
  #--------------------------------------------------------------------------
  def setup_scroll_text(params)
    Fiber.yield while $game_message.visible
    $game_message.clear_scrollex
    params.each do |param|
      case param
      when "noscroll" then $game_message.scroll_no_scroll = true
      when "window"   then $game_message.scroll_no_window = false
      when "arrow"    then $game_message.scroll_no_arrow = false
      when "noover"   then $game_message.scroll_no_over = true
      when "stop"     then $game_message.scroll_no_stop = false
      when "cancel"   then $game_message.scroll_no_cancel = false
      when "center"   then $game_message.scroll_align = 1
      when "right"    then $game_message.scroll_align = 2
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● コマンドスキップ
  #    文章のスクロールを飛ばしてインデックスを進める。
  #--------------------------------------------------------------------------
  def command_105_skip
    @index += 1 while next_event_code == 405
  end
  #--------------------------------------------------------------------------
  # ● 文章のスクロールのインデックスを進めながら文章を配列化
  #--------------------------------------------------------------------------
  def command_105_array
    result = []
    while next_event_code == 405
      @index += 1
      result << @list[@index].parameters[0]
    end
    result
  end
  #--------------------------------------------------------------------------
  # ● スクリプト
  #--------------------------------------------------------------------------
  def command_105_script(b)
    cmd_index = @index
    script = command_105_array.join("\n")
    begin
      b.eval(script, "文章のスクロール表示(#{cmd_index+1})", 1)
    rescue SyntaxError
      msg = "文章のスクロール表示(#{cmd_index+1}):" \
            "#{@index-cmd_index}:" \
            "実行されたイベントコマンドを確認してください。"
      raise SyntaxError, msg, []
    rescue => e
      raise e
    end
  end
end
