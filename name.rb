#******************************************************************************
#
#    ＊ ＜拡張＞ 名前入力の処理
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.1.5
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#   ： 漢字や独自の定義を使用する機能を追加します。
#   ： ランダムネーム機能を追加します。
#
#  --------------------------------------------------------------------------
#   == 使用方法 ==
#
#    ★ アクターの名前変更
#     イベントコマンド「名前入力の処理」を実行してください。
#
#    ★ 表示グラフィックの変更
#     $game_temp.name_mode = 0     # 画像なし
#     $game_temp.name_mode = 1     # 顔グラのみ
#     $game_temp.name_mode = 2     # 歩行グラのみ
#     $game_temp.name_mode = 3     # 顔グラと歩行グラ
#
#
#******************************************************************************


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
module NameInput
  #--------------------------------------------------------------------------
  # ◇ グラフィック表示の初期設定
  #--------------------------------------------------------------------------
  DEFAULT_MODE = 1
  #--------------------------------------------------------------------------
  # ◇ 入力文字が空の場合の初期設定
  #--------------------------------------------------------------------------
  DEFAULT_EMPTY = 0

  #--------------------------------------------------------------------------
  # ◇ メニューの設定
  #--------------------------------------------------------------------------
  COMMANDS = []
  COMMANDS[0] = ["ひらがな", 0]
  COMMANDS[1] = ["カタカナ", 1]
  COMMANDS[2] = ["Ａ Ｂ Ｃ", 2]
  COMMANDS[3] = ["漢　　字", 3]
  COMMANDS[4] = ["", nil]
  COMMANDS[5] = ["元に戻す", :default]
  COMMANDS[6] = ["おまかせ", :random]
  COMMANDS[7] = ["", nil]
  COMMANDS[8] = ["決　　定", :ok]
  #--------------------------------------------------------------------------
  # ◇ 文字セットの決定時に移動
  #--------------------------------------------------------------------------
  AUTO_SWITCH = true
  #--------------------------------------------------------------------------
  # ◇ 漢字入力後に頭文字選択へ戻る
  #--------------------------------------------------------------------------
  AUTO_RETURN = true
  #--------------------------------------------------------------------------
  # ◇ メニューを左側に表示する
  #--------------------------------------------------------------------------
  LEFT_MENU = true
  #--------------------------------------------------------------------------
  # ◇ 独立したメニューを使用する
  #--------------------------------------------------------------------------
  SEPARATE_MENU = false
  #--------------------------------------------------------------------------
  # ◇ ウィンドウを切り離す
  #--------------------------------------------------------------------------
  SEPARATE_WINDOW = false

  #--------------------------------------------------------------------------
  # ◇ ショートカットキーの設定
  #--------------------------------------------------------------------------
  PROCESS_BUTTON = {}
  PROCESS_BUTTON[:A] = :jump
  PROCESS_BUTTON[:X] = :back
  PROCESS_BUTTON[:Y] = :default
  PROCESS_BUTTON[:Z] = :random
  PROCESS_BUTTON[:L] = nil
  PROCESS_BUTTON[:R] = nil
  #--------------------------------------------------------------------------
  # ◇ キャンセルボタンの設定
  #--------------------------------------------------------------------------
  COMMAND_BUTTON_B = :cancel      # メニューでの動作
  INPUT_BUTTON_B   = :now         # 文字選択での動作

  #--------------------------------------------------------------------------
  # ◇ 基本文字セットの設定
  #--------------------------------------------------------------------------
  USE_HIRAGANA     = true         # ひらがな
  USE_KATAKANA     = true         # カタカナ
  USE_ALPHANUMERIC = true         # 英数字
  #--------------------------------------------------------------------------
  # ◇ 漢字入力時のひらがなをシステムカラーにする
  #--------------------------------------------------------------------------
  CHANGE_KANA_COLOR = true

  #--------------------------------------------------------------------------
  # ◇ 背景画像
  #--------------------------------------------------------------------------
  #   背景画像は、544x416 で "Graphics/System" フォルダに保存してください。
  #     ""  .. ファイル名を文字列で記述してください。
  #     nil .. 画像を使用しない。
  #--------------------------------------------------------------------------
  # 前景画像（最前面に表示されます。）
  FILE_FOREGROUND_NAME = nil
  # 背景画像（デフォルトのマップ画像と入れ替えます。）
  FILE_BACKGROUND_NAME = nil
  # ウィンドウ背景画像（デフォルトのマップ画像の上に表示されます。）
  FILE_BACKIMAGE_NAME  = nil
  #--------------------------------------------------------------------------
  # ◇ ウィンドウの可視状態
  #--------------------------------------------------------------------------
  VISIBLE_BACKWINDOW = true

  #--------------------------------------------------------------------------
  # ◇ ランダムネーム
  #--------------------------------------------------------------------------
  RANDOM_NAME = {}      # <= 削除しないでください。
  RANDOM_NAME[nil] = [  # デフォルト
    "ラルフ", "ウルリカ", "ベネット", "イルヴァ", "ロレンス",
    "オスカー", "ヴェラ", "エルマー",
    "エリック", "ナタリー", "テレンス", "アーネスト", "リョーマ",
    "ブレンダ", "リック", "アリス", "イザベル", "ノア"
  ]

  RANDOM_NAME["男"] = [
    "ラルフ", "ロレンス","オスカー", "エルマー", "エリック", "テレンス",
    "アーネスト", "リョーマ", "リック", "ノア"
  ]
  RANDOM_NAME["女"] = [
    "ウルリカ", "ベネット", "イルヴァ", "ヴェラ", "ナタリー", "ブレンダ",
    "アリス", "イザベル"
  ]

  #--------------------------------------------------------------------------
  # ◇ 用語設定
  #--------------------------------------------------------------------------
  VOCAB_FULL_SPACE = "全空"
  VOCAB_HALF_SPACE = "半空"

end # module NameInput
end # module CAO


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Temp
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :name_mode                #
  attr_accessor :name_empty               #
end

Window_NameInput::TABLE = []
if CAO::NameInput::USE_HIRAGANA
  Window_NameInput::TABLE << [
    'あ','い','う','え','お',  'が','ぎ','ぐ','げ','ご',
    'か','き','く','け','こ',  'ざ','じ','ず','ぜ','ぞ',
    'さ','し','す','せ','そ',  'だ','ぢ','づ','で','ど',
    'た','ち','つ','て','と',  'ば','び','ぶ','べ','ぼ',
    'な','に','ぬ','ね','の',  'ぱ','ぴ','ぷ','ぺ','ぽ',
    'は','ひ','ふ','へ','ほ',  'ぁ','ぃ','ぅ','ぇ','ぉ',
    'ま','み','む','め','も',  'っ','ゃ','ゅ','ょ','ゎ',
    'や', '' ,'ゆ', '' ,'よ',  'わ','を','ん',"\343\202\224",'☆',
    'ら','り','る','れ','ろ',  'ー','～','・',' ' ,'　'
  ]
end
if CAO::NameInput::USE_KATAKANA
  Window_NameInput::TABLE << [
    'ア','イ','ウ','エ','オ',  'ガ','ギ','グ','ゲ','ゴ',
    'カ','キ','ク','ケ','コ',  'ザ','ジ','ズ','ゼ','ゾ',
    'サ','シ','ス','セ','ソ',  'ダ','ヂ','ヅ','デ','ド',
    'タ','チ','ツ','テ','ト',  'バ','ビ','ブ','ベ','ボ',
    'ナ','ニ','ヌ','ネ','ノ',  'パ','ピ','プ','ペ','ポ',
    'ハ','ヒ','フ','ヘ','ホ',  'ァ','ィ','ゥ','ェ','ォ',
    'マ','ミ','ム','メ','モ',  'ッ','ャ','ュ','ョ','ヮ',
    'ヤ', '' ,'ユ', '' ,'ヨ',  'ワ','ヲ','ン','ヴ','＝',
    'ラ','リ','ル','レ','ロ',  'ー','～','・',' ' ,'　'
  ]
end
if CAO::NameInput::USE_ALPHANUMERIC
  Window_NameInput::TABLE << [
    'Ａ','Ｂ','Ｃ','Ｄ','Ｅ',  'ａ','ｂ','ｃ','ｄ','ｅ',
    'Ｆ','Ｇ','Ｈ','Ｉ','Ｊ',  'ｆ','ｇ','ｈ','ｉ','ｊ',
    'Ｋ','Ｌ','Ｍ','Ｎ','Ｏ',  'ｋ','ｌ','ｍ','ｎ','ｏ',
    'Ｐ','Ｑ','Ｒ','Ｓ','Ｔ',  'ｐ','ｑ','ｒ','ｓ','ｔ',
    'Ｕ','Ｖ','Ｗ','Ｘ','Ｙ',  'ｕ','ｖ','ｗ','ｘ','ｙ',
    'Ｚ','［','］','＾','＿',  'ｚ','｛','｝','｜','～',
    '０','１','２','３','４',  '！','＃','＄','％','＆',
    '５','６','７','８','９',  '（','）','＊','＋','－',
    '／','＝','＠','＜','＞',  '：','；','？',' ' ,'　'
  ]
end

#==============================================================================
# ■ Window_NameEdit
#------------------------------------------------------------------------------
# 　名前入力画面で、名前を編集するウィンドウです。
#==============================================================================

class Window_NameEdit < Window_Base
  include CAO::NameInput
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  MODO_NONE      = 0                      # なし
  MODE_FACE      = 1                      # 顔グラの描画
  MODE_CHARA     = 2                      # 歩行グラの描画
  WORD_RANDNAME  = /^<RN:(.+?)>$/         # ランダムネームのキーワード取得
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(actor, max_char)
    mode = $game_temp.name_mode || DEFAULT_MODE
    super(0, 0, 496, (mode & MODE_FACE != 0) ? 120 : 72)
    self.x = (Graphics.width - self.width) / 2
    self.y = (Graphics.height - (self.height + fitting_height(9) + 8)) / 2
    @actor = actor
    @max_char = max_char * 2
    @mode = mode
    @default_name = actor.name
    self.name = actor.name
    deactivate
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def name_size
    return @size_table.inject(:+) || 0
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def char_size(ch)
    return (ch[/[!-~ ｦ-ﾟ]/] && ch.size < 2) ? 1 : 2
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def item_max
    blank = @max_char - name_size
    return @size_table.size + blank / 2 + blank % 2
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def name
    return @name_table.join('')
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def name=(new_name)
    @name_table = new_name.to_s.scan(/[ｦ-ﾝ][ﾞﾟ]|./)
    @size_table = @name_table.map {|c| char_size(c) }
    @index = @name_table.size
    break unless back while @max_char < name_size
    refresh
  end
  #--------------------------------------------------------------------------
  # ○ デフォルトの名前に戻す
  #--------------------------------------------------------------------------
  def restore_default
    self.name = @default_name
    return !@name_table.empty?
  end
  #--------------------------------------------------------------------------
  # ○ 文字の追加
  #     ch : 追加する文字
  #--------------------------------------------------------------------------
  def add(ch)
    ch_size = char_size(ch)
    return false if @max_char < name_size + ch_size
    @name_table.push(ch)
    @size_table.push(ch_size)
    @index += 1
    refresh
    return true
  end
  #--------------------------------------------------------------------------
  # ○ 一文字戻す
  #--------------------------------------------------------------------------
  def back
    return false if @index == 0
    @name_table.pop
    @size_table.pop
    @index -= 1
    refresh
    return true
  end
  #--------------------------------------------------------------------------
  # ○ 顔グラフィックの幅を取得
  #--------------------------------------------------------------------------
  def face_width
    return (@mode & MODE_FACE != 0) ? 96 : 32
  end
  #--------------------------------------------------------------------------
  # ○ 文字の幅を取得
  #--------------------------------------------------------------------------
  def char_width
    @char_width ||= text_size("A").width * 2
  end
  #--------------------------------------------------------------------------
  # ● 文字の左右の余白
  #--------------------------------------------------------------------------
  def char_margin
    return 1
  end
  #--------------------------------------------------------------------------
  # ○ 名前を描画する左端の座標を取得
  #--------------------------------------------------------------------------
  def left
    name_center = (contents_width + face_width) / 2
    name_width = (@max_char / 2 + 1) * char_width
    return [name_center - name_width / 2, contents_width - name_width].min
  end
  #--------------------------------------------------------------------------
  # ○ 項目を描画する矩形の取得
  #--------------------------------------------------------------------------
  def item_rect(index)
    sizes = Array.new(index + 1) {|i| @size_table[i] || 2 }
    sizes.map! {|n| (n == 2) ? char_width : char_width / 2 }
    rect = Rect.new(0, 0, 0, line_height)
    rect.x = left + sizes.inject(:+) - sizes.last
    rect.y = (contents_height - line_height) / 2
    if item_max - index == 1 && name_size.odd?
      rect.width = char_width / 2
    else
      rect.width = sizes.last
    end
    return rect
  end
  #--------------------------------------------------------------------------
  # ● 項目を描画する矩形の取得（テキスト用）
  #--------------------------------------------------------------------------
  def item_rect_for_text(index)
    rect = item_rect(index)
    rect.x -= 2
    rect.width += 4
    rect
  end
  #--------------------------------------------------------------------------
  # ○ 下線の矩形を取得
  #--------------------------------------------------------------------------
  def underline_rect(index)
    rect = item_rect(index)
    rect.x += 1 + char_margin
    rect.y += rect.height - 4
    rect.width -= 2 + char_margin * 2
    rect.height = 2
    rect
  end
  #--------------------------------------------------------------------------
  # ● カーソルの更新
  #--------------------------------------------------------------------------
  def update_cursor
    if @index < 0 || name_size >= @max_char
      self.cursor_rect.empty
    else
      self.cursor_rect.set(item_rect(@index))
    end
  end
  #--------------------------------------------------------------------------
  # ○ リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    draw_edit_face(0, 0)
    item_max.times {|i| draw_underline(i) }
    @name_table.size.times {|i| draw_char(i) }
    cursor_rect.set(item_rect(@index))
    update_cursor
  end
  #--------------------------------------------------------------------------
  # ○ 文字を描画
  #--------------------------------------------------------------------------
  def draw_char(index)
    change_color(normal_color)
    draw_text(item_rect_for_text(index), @name_table[index] || "", 1)
  end
  #--------------------------------------------------------------------------
  # ● 顔グラの描画
  #--------------------------------------------------------------------------
  def draw_edit_face(x, y)
    if @mode & MODE_FACE != 0
      draw_actor_face(@actor, x, y)
      pos_chara = [x + 16, x + contents_height, 0]
    end
    if @mode & MODE_CHARA != 0
      pos_chara ||= [x + 24, x + contents_height, contents_height]
      draw_actor_graphic(@actor, *pos_chara)
    end
  end
  #--------------------------------------------------------------------------
  # ● アクターの歩行グラフィック描画
  #--------------------------------------------------------------------------
  def draw_actor_graphic(actor, x, y, height = 0)
    return unless actor.character_name
    bitmap = Cache.character(actor.character_name)
    sign = actor.character_name[/^[\!\$]./]
    if sign && sign.include?('$')
      cw = bitmap.width / 3
      ch = bitmap.height / 4
    else
      cw = bitmap.width / 12
      ch = bitmap.height / 8
    end
    src_rect = Rect.new(0, 0, cw, ch)
    src_rect.x = (actor.character_index % 4 * 3 + 1) * cw
    src_rect.y = (actor.character_index / 4 * 4) * ch
    if height != 0
       y += (ch - height < 0) ? (ch - height) / 2 : ch - height
    end
    self.contents.blt(x - cw / 2, y - ch, bitmap, src_rect)
  end
  #--------------------------------------------------------------------------
  # ● ランダムネームから
  #--------------------------------------------------------------------------
  def choose_name
    ward = @actor.actor.note[WORD_RANDNAME, 1]
    ward = @actor.class.note[WORD_RANDNAME, 1] unless ward
    if RANDOM_NAME[ward]
      self.name = RANDOM_NAME[ward].sample
    else
      restore_default
    end
  end
end

class Window_NameInput
  include CAO::NameInput
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  CHAR_FULL_SPACE = "　"
  CHAR_HALF_SPACE = " "
  WORD_FULL_CHAR  = /[ぁ-#{"\343\202\224"}]/
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader :page
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(edit_window)
    @edit_window = edit_window
    @page = 0         # 文字の種類
    @category = 0     #
    @last_index = 0

    x = edit_window.x
    width = edit_window.width
    if SEPARATE_WINDOW
      x     += Window_NameCommand::WIDTH if LEFT_MENU
      width -= Window_NameCommand::WIDTH
    end
    super(x, edit_window.y + edit_window.height + 8, width, fitting_height(9))

    if LEFT_MENU
      deactivate
      @index = -1
    else
      activate
      @index = 0
    end
    update_cursor
    refresh
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ内容の高さを計算
  #--------------------------------------------------------------------------
  def contents_height
    return item_max / 10 * line_height
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    create_contents
    draw_characters_table
    self.top_row = 0
    self.index %= item_max if @index > 0
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def draw_characters_table
    change_color(normal_color)
    char_table.each_with_index do |c,i|
      if CHANGE_KANA_COLOR && classificatory?
        change_color(c.match(WORD_FULL_CHAR) ? system_color : normal_color)
      end
      case c
      when CHAR_FULL_SPACE; c = VOCAB_FULL_SPACE
      when CHAR_HALF_SPACE; c = VOCAB_HALF_SPACE
      end
      draw_text(item_rect(i), c, 1)
    end
  end
  #--------------------------------------------------------------------------
  # ● 文字を描画する左端の座標を取得
  #--------------------------------------------------------------------------
  def left
    return !SEPARATE_WINDOW && LEFT_MENU ? 128 : 0
  end
  #--------------------------------------------------------------------------
  # ● 項目を描画する矩形の取得
  #--------------------------------------------------------------------------
  def item_rect(index)
    rect = Rect.new
    rect.x = index % 10 * 32 + index % 10 / 5 * 16 + left
    rect.y = index / 10 * line_height
    rect.width = 32
    rect.height = line_height
    rect
  end
  #--------------------------------------------------------------------------
  # ● 項目を描画する矩形の取得
  #--------------------------------------------------------------------------
  def change_charcters_table(page)
    return if @page == page
    raise "指定された文字セットが見つかりません。(#{page})" unless TABLE[page]
    @last_index = 0
    @category = 0
    @page = page
    refresh
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def restore_index
    @index = @last_index
  end
  #--------------------------------------------------------------------------
  # ● 桁数の取得
  #--------------------------------------------------------------------------
  def col_max
    return 10
  end
  #--------------------------------------------------------------------------
  # ● 項目数の取得
  #--------------------------------------------------------------------------
  def item_max
    return char_table.size
  end
  #--------------------------------------------------------------------------
  # ● 表示する文字セットの取得
  #--------------------------------------------------------------------------
  def char_table
    return TABLE[@page][@category] if classificatory?
    return TABLE[@page]
  end
  #--------------------------------------------------------------------------
  # ○ 文字表の取得
  #--------------------------------------------------------------------------
  def table
    return TABLE
  end
  #--------------------------------------------------------------------------
  # ○ 文字の取得
  #--------------------------------------------------------------------------
  def character
    return char_table[@index] || ""
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def classificatory?
    return TABLE[@page].kind_of?(Hash)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def change_category?
    return classificatory? && @category == 0 && !character.empty?
  end
  #--------------------------------------------------------------------------
  # ○ カーソルの移動処理
  #--------------------------------------------------------------------------
  def process_cursor_move
    last_page = @page
    super
    update_cursor
    Sound.play_cursor if @page != last_page
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  remove_method :update_cursor      # カーソルの更新
  #--------------------------------------------------------------------------
  # ● カーソルを下に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_down(wrap = false)
    if index < item_max - col_max || wrap
      select((index + col_max) % item_max)
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルを上に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  def cursor_up(wrap = false)
    if index >= col_max || wrap
      select((index - col_max + item_max) % item_max)
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルを右に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  alias _cao_name_cursor_right cursor_right
  def cursor_right(wrap)
    if !SEPARATE_MENU && wrap && @index % col_max == col_max - 1
      call_handler(:switching)
    else
      _cao_name_cursor_right(wrap)
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルを左に移動
  #     wrap : ラップアラウンド許可
  #--------------------------------------------------------------------------
  alias _cao_name_cursor_left cursor_left
  def cursor_left(wrap)
    if !SEPARATE_MENU && wrap && @index % col_max == 0
      call_handler(:switching)
    else
      _cao_name_cursor_left(wrap)
    end
  end
  #--------------------------------------------------------------------------
  # ● 次の文字セット
  #--------------------------------------------------------------------------
  alias next_charset cursor_pagedown
  #--------------------------------------------------------------------------
  # ● 前の文字セット
  #--------------------------------------------------------------------------
  alias prev_charset cursor_pageup
  #--------------------------------------------------------------------------
  # ○ 次のページへ移動
  #--------------------------------------------------------------------------
  def cursor_pagedown
    super unless PROCESS_BUTTON[:R]
  end
  #--------------------------------------------------------------------------
  # ○ 前のページへ移動
  #--------------------------------------------------------------------------
  def cursor_pageup
    super unless PROCESS_BUTTON[:L]
  end
  #--------------------------------------------------------------------------
  # ○ 決定やキャンセルなどのハンドリング処理
  #--------------------------------------------------------------------------
  def process_handling
    return unless open? && active
    process_cancel if Input.repeat?(:B)
    process_ok     if Input.trigger?(:C)
  end
  #--------------------------------------------------------------------------
  # ○ 決定ボタンが押されたときの処理
  #--------------------------------------------------------------------------
  def process_ok
    if change_category?
      Sound.play_cursor
      @category = character
      @last_index = @index
      @index = 0
      refresh
    elsif !character.empty?
      on_name_add
      if AUTO_RETURN && @category != 0
        @category = 0
        refresh
        self.index = @last_index
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ キャンセルボタンが押されたときの処理
  #--------------------------------------------------------------------------
  def process_cancel
    if classificatory? && @category != 0
      Sound.play_cancel
      @category = 0
      refresh
      self.index = @last_index
    elsif SEPARATE_MENU
      @last_index = @index
      @category = 0
      refresh
      call_handler(:switching)
    elsif INPUT_BUTTON_B
      call_handler(INPUT_BUTTON_B)
    end
  end
end

class Window_NameCommand < Window_Selectable
  include CAO::NameInput
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  WIDTH = 128
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(input_window)
    @input_window = input_window
    super(input_window.x, input_window.y, WIDTH, input_window.height)
    if SEPARATE_WINDOW
      self.x += (LEFT_MENU ? -WIDTH : input_window.width)
    else
      self.x += (LEFT_MENU ? 12 : input_window.width - WIDTH - 12)
    end
    self.opacity = 0 unless SEPARATE_WINDOW
    self.active = LEFT_MENU
    select(0) if LEFT_MENU || SEPARATE_MENU
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 項目数の取得
  #--------------------------------------------------------------------------
  def item_max
    return 9
  end
  #--------------------------------------------------------------------------
  # ● 項目の選択
  #--------------------------------------------------------------------------
  def select(index)
    return unless index
    index %= item_max
    if COMMANDS[index][1]
      self.index = index
    elsif @index < 0
      result = COMMANDS[index, item_max].index {|o| o[1] }
      result &&= [result + index, item_max - 1].min
      result ||= COMMANDS.rindex {|o| o[1] }
      self.index = result
    else
      method = (@index < index) ? :index : :rindex
      result = COMMANDS.rotate(index).send(method) {|o| o[1] }
      self.index = (result + index) % item_max
    end
  end
  #--------------------------------------------------------------------------
  # ● 項目の描画
  #--------------------------------------------------------------------------
  def draw_item(index)
    if COMMANDS[index][1]
      change_color(normal_color)
      rect = item_rect(index)
      rect.x += 2
      rect.width -= 4
      draw_text(rect, COMMANDS[index][0], 1)
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルを下に移動
  #--------------------------------------------------------------------------
  def cursor_down(wrap = false)
    end_index = COMMANDS.rindex {|o| o[1] }
    select((index + 1) % item_max) if index < end_index || wrap
    end
  #--------------------------------------------------------------------------
  # ● カーソルを上に移動
  #--------------------------------------------------------------------------
  def cursor_up(wrap = false)
    start_index = COMMANDS.index {|o| o[1] }
    select((index - 1 + item_max) % item_max) if index > start_index || wrap
  end
  #--------------------------------------------------------------------------
  # ● カーソルを右に移動
  #--------------------------------------------------------------------------
  def cursor_right(wrap = false)
    call_handler(:switching) unless SEPARATE_MENU
  end
  #--------------------------------------------------------------------------
  # ● カーソルを左に移動
  #--------------------------------------------------------------------------
  def cursor_left(wrap = false)
    call_handler(:switching) unless SEPARATE_MENU
  end
  #--------------------------------------------------------------------------
  # ○ 決定ボタンが押されたときの処理
  #--------------------------------------------------------------------------
  def process_ok
    return unless COMMANDS[@index][1]
    if COMMANDS[@index][1].kind_of?(Integer)
      @input_window.change_charcters_table(COMMANDS[@index][1])
      if SEPARATE_MENU || AUTO_SWITCH
        Sound.play_cursor
        call_handler(:switching)
      end
    else
      call_handler(COMMANDS[@index][1])
    end
  end
  #--------------------------------------------------------------------------
  # ○ キャンセルボタンが押されたときの処理
  #--------------------------------------------------------------------------
  def process_cancel
    Input.update
    call_cancel_handler
  end
end

class Scene_Name
  include CAO::NameInput
  #--------------------------------------------------------------------------
  # ○ 開始処理
  #--------------------------------------------------------------------------
  def start
    super
    @actor = $game_actors[@actor_id]
    @edit_window = Window_NameEdit.new(@actor, @max_char)
    create_input_window
    create_command_window
    hide_all_backwindows unless VISIBLE_BACKWINDOW
  end
  #--------------------------------------------------------------------------
  # ● 全ウィンドウを非表示
  #--------------------------------------------------------------------------
  def hide_all_backwindows
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      ivar.opacity = 0 if ivar.is_a?(Window)
    end
  end
  #--------------------------------------------------------------------------
  # ○ 終了処理
  #--------------------------------------------------------------------------
  def terminate
    super
    $game_temp.name_mode = nil
    $game_temp.name_empty = nil
  end
  #--------------------------------------------------------------------------
  # ● 文字選択ウィンドウの作成
  #--------------------------------------------------------------------------
  def create_input_window
    @input_window = Window_NameInput.new(@edit_window)
    @input_window.set_handler(:switching, method(:activate_command_window))
    @input_window.set_handler(:back, method(:on_name_back))
    set_handler(@input_window, INPUT_BUTTON_B) if INPUT_BUTTON_B
  end
  #--------------------------------------------------------------------------
  # ● メニューウィンドウの作成
  #--------------------------------------------------------------------------
  def create_command_window
    @command_window = Window_NameCommand.new(@input_window)
    @command_window.set_handler(:switching, method(:activate_input_window))
    if COMMAND_BUTTON_B
      name = :"on_name_#{COMMAND_BUTTON_B}"
      @command_window.set_handler(:cancel, method(name))
    end
    COMMANDS.each do |a|
      set_handler(@command_window, a[1]) if a[1].kind_of?(Symbol)
    end
  end
  #--------------------------------------------------------------------------
  # ● 背景の作成
  #--------------------------------------------------------------------------
  def create_background
    if FILE_BACKGROUND_NAME
      @background_sprite = Sprite.new
      @background_sprite.bitmap = Cache.system(FILE_BACKGROUND_NAME)
    else
      super
    end
    if FILE_BACKIMAGE_NAME
      @backimage_sprite = Sprite.new
      @backimage_sprite.bitmap = Cache.system(FILE_BACKIMAGE_NAME)
    end
    if FILE_FOREGROUND_NAME
      @foreground_sprite = Sprite.new
      @foreground_sprite.z = 500
      @foreground_sprite.bitmap = Cache.system(FILE_FOREGROUND_NAME)
    end
  end
  #--------------------------------------------------------------------------
  # ● 背景の解放
  #--------------------------------------------------------------------------
  def dispose_background
    super
    @backimage_sprite.dispose if @backimage_sprite
    @foreground_sprite.dispose if @foreground_sprite
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def activate_command_window
    @command_window.activate
    unless SEPARATE_MENU
      index = @input_window.index / 10 - @input_window.top_row
      @command_window.select(index)
    end
    @input_window.deactivate
    @input_window.unselect
    Input.update
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def activate_input_window
    @input_window.activate
    if SEPARATE_MENU
      @input_window.restore_index
    else
      index = (@command_window.index + @input_window.top_row) * 10
      if Input.trigger?(:LEFT)
        @input_window.select(index + 9)
      elsif Input.trigger?(:RIGHT)
        @input_window.select(index)
      else
        @input_window.restore_index
        @input_window.update_cursor
      end
    end
    @command_window.deactivate
    @command_window.unselect unless SEPARATE_MENU
    Input.update
  end
  #--------------------------------------------------------------------------
  # ◎ フレーム更新
  #--------------------------------------------------------------------------
  def update
    super
    process_button
  end
  #--------------------------------------------------------------------------
  # ● ハンドリング処理
  #--------------------------------------------------------------------------
  def process_button
    PROCESS_BUTTON.each do |key,handle|
      next unless PROCESS_BUTTON[key] && Input.trigger?(key)
      __send__("on_name_#{handle}")
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def set_handler(window, handle)
    window.set_handler(handle, method(:"on_name_#{handle}"))
  end
  #--------------------------------------------------------------------------
  # ● 入力名を適用する
  #--------------------------------------------------------------------------
  def on_name_ok
    case @edit_window.name.empty? && ($game_temp.name_empty || DEFAULT_EMPTY)
    when 0
      Sound.play_buzzer
    when 1
      if @edit_window.restore_default
        Sound.play_ok
        on_input_ok
      else
        Sound.play_buzzer
      end
    else
      Sound.play_ok
      on_input_ok
    end
  end
  #--------------------------------------------------------------------------
  # ● 名前入力をやめる
  #--------------------------------------------------------------------------
  def on_name_cancel
    case @edit_window.name.empty? && ($game_temp.name_empty || DEFAULT_EMPTY)
    when 0,1
      Sound.play_buzzer
    else
      Sound.play_cancel
      return_scene
    end
  end
  #--------------------------------------------------------------------------
  # ● 一文字削除
  #--------------------------------------------------------------------------
  def on_name_back
    Sound.play_cancel if @edit_window.back
  end
  #--------------------------------------------------------------------------
  # ● 決定にジャンプ
  #--------------------------------------------------------------------------
  def on_name_jump
    index = COMMANDS.index {|cmd| cmd[1] == :ok }
    return unless index
    Sound.play_cursor
    @command_window.activate
    @command_window.select(index)
    @input_window.deactivate
    @input_window.unselect
    Input.update
  end
  #--------------------------------------------------------------------------
  # ● 現在の文字セットにジャンプ
  #--------------------------------------------------------------------------
  def on_name_now
    index = COMMANDS.index {|cmd| cmd[1] == @input_window.page }
    return unless index
    Sound.play_cursor
    @command_window.activate
    @command_window.select(index)
    @input_window.deactivate
    @input_window.unselect
    Input.update
  end
  #--------------------------------------------------------------------------
  # ● デフォルトの名前に戻す
  #--------------------------------------------------------------------------
  def on_name_default
    Sound.play_cancel
    @edit_window.restore_default
  end
  #--------------------------------------------------------------------------
  # ● ランダムに名前を入力する
  #--------------------------------------------------------------------------
  def on_name_random
    Sound.play_ok
    @edit_window.choose_name
  end
  #--------------------------------------------------------------------------
  # ● 次の文字セットに変更
  #--------------------------------------------------------------------------
  def on_name_next
    Sound.play_cursor
    @input_window.next_charset
  end
  #--------------------------------------------------------------------------
  # ● 前の文字セットに変更
  #--------------------------------------------------------------------------
  def on_name_prev
    Sound.play_cursor
    @input_window.prev_charset
  end
end
