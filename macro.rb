#******************************************************************************
#
#    ＊ 共有マクロ
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.1.0
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#
#   == 概    要 ==
#
#   ： Shift + F9 にマクロ機能を追加します。
#
#  --------------------------------------------------------------------------
#   == 使用準備 ==
#
#    ★ マクロフォルダ
#     プロジェクトの親フォルダに _MCR_ フォルダを作成します。
#     その中の _ フォルダは、プロジェクト固有のマクロとなります。
#     _ 内に対象のプロジェクトと同名のフォルダを作成してください。
#
#    ■ RPGVXAce         |  [フォルダ構成]
#    ├□ _MCR_          |  _MCR_ マクロフォルダ (必須)
#    │├□ _            |  _     プロジェクトマクロフォルダ
#    ││└□ Project2   |
#    ││  └ Script.rb  |  _MCR_ 内にフォルダを作成してグループ分けできます。
#    │├□ Group1       |  _MCR_ 直下のものはプロジェクトマクロに追加される。
#    │├□ Group2       |
#    ││└ Script.rb    |  マクロファイルは、拡張子が rb のものだけです。
#    │└ Script.rb      |
#    ├■ Project1       |  ファイル名の先頭の半角英数字から空白までは、
#    └■ Project2       |  表示されないため順番など整理に使用してください。
#
#  --------------------------------------------------------------------------
#   == 使用方法 ==
#
#    ★ マクロ選択画面の表示
#     Shift + F9 を押します。ゲーム中どこでも表示できます。
#     マクロ実行後、画面を閉じます。１マクロ実行を想定しているため。
#     マクロ選択を継続する場合は Shift を押したまま決定します。
#
#******************************************************************************


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module CAO end    # define namespace
module CAO::MACRO
  # マクロフォルダ
  DIRECTORY = "../_MCR_"
  # 実行後閉じる (装飾キー押し実行で閉じない)
  RUN_ONCE = true
  # 装飾キー (:SHIFT or :CTRL)
  ATTRIBUTE_KEY = :SHIFT
  class << self
    #------------------------------------------------------------------------
    # ● マクロファイルの実行
    #------------------------------------------------------------------------
    def run(path, bind=nil)
      script = File.read(path)
      eval(script, BINDING(script[/\A#!(.+)/,1])||bind, File.basename(path))
    end
    private
    #------------------------------------------------------------------------
    # ● マクロの実行場所(binding)を取得
    #------------------------------------------------------------------------
    def BINDING(args)
      case args
      when /((?<=\A|\s))top(level)?(?=\s+|\z)/i
        TOPLEVEL_BINDING
      when /((?<=\A|\s))scene(?=\s+|\z)/i
        SceneManager.scene.instance_eval('binding')
      else
        nil
      end
    end
  end
end
class String
  #--------------------------------------------------------------------------
  # ● Win32API
  #--------------------------------------------------------------------------
  @mb2wc = Win32API.new('kernel32', 'MultiByteToWideChar', 'ilpipi', 'i')
  @wc2mb = Win32API.new('kernel32', 'WideCharToMultiByte', 'ilpipipp', 'i')
  class << self
    #------------------------------------------------------------------------
    # ● MultiByteToWideChar
    #------------------------------------------------------------------------
    def mb2wc(str, cp)
      length = @mb2wc.call(cp, 0, str, -1, nil, 0)
      buffer = "\0" * length * 2
      @mb2wc.call(cp, 0, str, -1, buffer, length)
      buffer
    end
    #------------------------------------------------------------------------
    # ● WideCharToMultiByte
    #------------------------------------------------------------------------
    def wc2mb(str, cp)
      length = @wc2mb.call(cp, 0, str, -1, nil, 0, nil, nil)
      buffer = "\0" * length
      @wc2mb.call(cp, 0, str, -1, buffer, length, nil, nil)
      buffer
    end
  end # class << self
  #--------------------------------------------------------------------------
  # ● 文字コードの変更
  #     cp : :utf8 or :system
  #--------------------------------------------------------------------------
  def iconv(cp)
    src, dest, enc =
      (cp == :utf8) ? [0, 65001, 'utf-8'] : [65001, 0, 'ascii-8bit']
    String.wc2mb(String.mb2wc(self, src), dest)
      .unpack('A*')[0].force_encoding(enc)
  end
end
# <!> DirEx は、本スクリプトでのみの使用を想定しているため不完全
module CAO::MACRO::DirEx
  #--------------------------------------------------------------------------
  # ● Win32API
  #--------------------------------------------------------------------------
  @fff = Win32API.new('kernel32', 'FindFirstFileA', 'pp', 'l')
  @fnf = Win32API.new('kernel32', 'FindNextFileA', 'lp', 'i')
  @fc  = Win32API.new('kernel32', 'FindClose', 'l', 'i')
  class << self
    #------------------------------------------------------------------------
    # ● カレントディレクトリの取得 (Dir.pwd 日本語対策版)
    #------------------------------------------------------------------------
    def pwd
      Dir.pwd.iconv(:utf8)
    end
    #------------------------------------------------------------------------
    # ● パスをディレクトリ毎に分割 (末尾の / は削除)
    #------------------------------------------------------------------------
    def split(path)
      path = path.chop if path.end_with?('/','\\')
      path.split(/[\/\\]/)
    end
    #------------------------------------------------------------------------
    # ● ディレクトリ名の取得 ( . を含む場合はファイルとして無視する)
    #------------------------------------------------------------------------
    def name(path)
      split(path).reverse.find {|name| !name[/[.*]/] }
    end
    #------------------------------------------------------------------------
    # ● ファイル探索
    #     opts :name : (真) 名前のみ     (未) ファイルパス
    #          :dir  : (真) フォルダのみ (未) 全ファイル
    #------------------------------------------------------------------------
    def glob(pattern, opts = {})
      result = []
      pattern = pattern.chop if pattern.end_with?('/', '\\')
      path = split(pattern)[0..-2].join('/')
      fd = "\0" * 318
      handle = @fff.call(pattern.iconv(:system), fd)
      if handle != -1
        loop do
          fa,fn = fd.unpack('L11A260').values_at(0, 11)
          if !opts[:dir] || fa & 0x10 != 0
            result << fn.iconv(:utf8)
          end
          fd = "\0" * 318
          break if @fnf.call(handle, fd) == 0
        end
        @fc.call(handle)
      end
      result = result.drop_while {|fn| fn.start_with?('.') }
      result.map! {|fn| "#{path}/#{fn}" } unless opts[:name]
      if block_given?
        result.each {|fn| yield fn }
      else
        return result
      end
    end
  end
end
def InputBox(msg, title="入力")
  cmd =  'mshta vbscript:execute("'
  cmd << 'r=InputBox(""' << msg << '"",""' << title << '""):'
  cmd << 'CreateObject(""Scripting.FileSystemObject"")'
  cmd << '.GetStandardStream(1).Write(r):close")'
  %x(#{cmd.encode("Shift_JIS", "UTF-8")}).encode("UTF-8", "Shift_JIS")
end
if $TEST && Dir.exist?(CAO::MACRO::DIRECTORY)
  class Scene_Base
    #------------------------------------------------------------------------
    # ○ フレーム更新
    #------------------------------------------------------------------------
    alias _cao_macro_update update
    def update
      _cao_macro_update
      update_call_macro
    end
    #------------------------------------------------------------------------
    # ● 装飾キー + F9 キーによるマクロ呼び出し判定
    #------------------------------------------------------------------------
    def update_call_macro
      if Input.press?(CAO::MACRO::ATTRIBUTE_KEY) && Input.press?(:F9)
        Scene_Macro.run
      end
    end
  end
end # if $TEST
module CAO::MACRO::Selectable
  #--------------------------------------------------------------------------
  # ● ウィンドウを画面中央へ移動
  #--------------------------------------------------------------------------
  def move_center
    help_height = @help_window && @help_window.height || 0
    self.x = (Graphics.width  - self.width)  / 2
    self.y = (Graphics.height - help_height - self.height) / 2 - help_height
  end
  #--------------------------------------------------------------------------
  # ● 除外するプロパティ名の配列を取得
  #--------------------------------------------------------------------------
  def reserved_properties
    [
      :init,    # オブジェクトの初期化に使用される
      :bind,    # CAO::MACRO::Scene_Base 外の実行場所 binding
      :command  # InputCommand などで渡されたブロック。決定時に実行される。
    ]
  end
  #--------------------------------------------------------------------------
  # ● Hash の key をメソッド名に value を返す特異メソッドを定義
  #--------------------------------------------------------------------------
  def define_properties(params)
    (params.keys - reserved_properties).each do |key|
      define_property(key, params[key])
    end
  end
  #--------------------------------------------------------------------------
  # ● 特異メソッドの定義
  #--------------------------------------------------------------------------
  def define_property(method_name, value)
    case value
    when nil
      # Do Nothing
    when Proc, Method
      define_singleton_method(method_name, value)
    else
      define_singleton_method(method_name) { value }
    end
  end
  #--------------------------------------------------------------------------
  # ● カーソルの移動処理
  #--------------------------------------------------------------------------
  def process_cursor_move
    return unless cursor_movable?
    last_index = @index
    process_cursor_button
    Sound.play_cursor if @index != last_index
  end
  #--------------------------------------------------------------------------
  # ● カーソルの移動のボタン判定処理
  #--------------------------------------------------------------------------
  def process_cursor_button
    cursor_down (Input.trigger?(:DOWN))  if Input.repeat?(:DOWN)
    cursor_up   (Input.trigger?(:UP))    if Input.repeat?(:UP)
    cursor_right(Input.trigger?(:RIGHT)) if Input.repeat?(:RIGHT)
    cursor_left (Input.trigger?(:LEFT))  if Input.repeat?(:LEFT)
    cursor_pagedown   if !handle?(:pagedown) && Input.trigger?(:R)
    cursor_pageup     if !handle?(:pageup)   && Input.trigger?(:L)
  end
  #--------------------------------------------------------------------------
  # ● 決定やキャンセルなどのハンドリング処理
  #--------------------------------------------------------------------------
  def process_handling
    return unless open? && active
    return process_ok       if ok_enabled?        && Input.trigger?(:C)
    return process_cancel   if cancel_enabled?    && Input.trigger?(:B)
    return process_pagedown if handle?(:pagedown) && Input.trigger?(:R)
    return process_pageup   if handle?(:pageup)   && Input.trigger?(:L)
    return process_btn_a    if handle?(:btn_a)    && Input.trigger?(:A)
    return process_btn_x    if handle?(:btn_x)    && Input.trigger?(:X)
    return process_btn_y    if handle?(:btn_y)    && Input.trigger?(:Y)
    return process_btn_z    if handle?(:btn_z)    && Input.trigger?(:Z)
  end
  #--------------------------------------------------------------------------
  # ● A ボタンが押されたときの処理
  #--------------------------------------------------------------------------
  def process_btn_a
    call_handler(:btn_a)
  end
  #--------------------------------------------------------------------------
  # ● X ボタンが押されたときの処理
  #--------------------------------------------------------------------------
  def process_btn_x
    call_handler(:btn_x)
  end
  #--------------------------------------------------------------------------
  # ● Y ボタンが押されたときの処理
  #--------------------------------------------------------------------------
  def process_btn_y
    call_handler(:btn_y)
  end
  #--------------------------------------------------------------------------
  # ● Z ボタンが押されたときの処理
  #--------------------------------------------------------------------------
  def process_btn_z
    call_handler(:btn_z)
  end
end
module CAO::MACRO
  class Scene_Base
    #--------------------------------------------------------------------------
    # ● シーン実行
    #--------------------------------------------------------------------------
    def self.run(params = {})
      self.new.run(params)
    end
    #--------------------------------------------------------------------------
    # ● 公開インスタンス変数
    #--------------------------------------------------------------------------
    attr_accessor :result                   # シーン実行結果
    #--------------------------------------------------------------------------
    # ● シーン実行
    #--------------------------------------------------------------------------
    def run(params = {})
      @params = params
      @params[:bind] = binding  # Scene_Macro の binding 固定
      main
      result
    end
    #--------------------------------------------------------------------------
    # ● メイン
    #--------------------------------------------------------------------------
    def main
      start
      init_scene
      Input.update
      update until scene_changing?
      Input.update
      terminate
    end
    #--------------------------------------------------------------------------
    # ● 初期化処理
    #--------------------------------------------------------------------------
    def init_scene
      instance_exec(&@params[:init]) if @params[:init]
    end
    #--------------------------------------------------------------------------
    # ● 開始処理
    #--------------------------------------------------------------------------
    def start
      create_main_viewport
    end
    #--------------------------------------------------------------------------
    # ● シーン変更中判定
    #--------------------------------------------------------------------------
    def scene_changing?
      @return_scene
    end
    #--------------------------------------------------------------------------
    # ● フレーム更新
    #--------------------------------------------------------------------------
    def update
      update_basic
    end
    #--------------------------------------------------------------------------
    # ● フレーム更新（基本）
    #--------------------------------------------------------------------------
    def update_basic
      Graphics.update
      Input.update
      update_all_windows
    end
    #--------------------------------------------------------------------------
    # ● 終了処理
    #--------------------------------------------------------------------------
    def terminate
      dispose_all_windows
      dispose_main_viewport
    end
    #--------------------------------------------------------------------------
    # ● ビューポートの作成
    #--------------------------------------------------------------------------
    def create_main_viewport
      @viewport = Viewport.new
      @viewport.z = 999999
    end
    #--------------------------------------------------------------------------
    # ● ビューポートの解放
    #--------------------------------------------------------------------------
    def dispose_main_viewport
      @viewport.dispose
    end
    #--------------------------------------------------------------------------
    # ● 全ウィンドウ
    #--------------------------------------------------------------------------
    def adjust_all_windows
      instance_variables.each do |varname|
        ivar = instance_variable_get(varname)
        ivar.viewport = @viewport if ivar.is_a?(Window)
        ivar.back_opacity = 255   if ivar.is_a?(Window)
      end
    end
    #--------------------------------------------------------------------------
    # ● 全ウィンドウの更新
    #--------------------------------------------------------------------------
    def update_all_windows
      instance_variables.each do |varname|
        ivar = instance_variable_get(varname)
        ivar.update if ivar.is_a?(Window)
      end
    end
    #--------------------------------------------------------------------------
    # ● 全ウィンドウの解放
    #--------------------------------------------------------------------------
    def dispose_all_windows
      instance_variables.each do |varname|
        ivar = instance_variable_get(varname)
        ivar.dispose if ivar.is_a?(Window)
      end
    end
    #--------------------------------------------------------------------------
    # ● Scene_Macro のインスタンスを取得
    #--------------------------------------------------------------------------
    def scene
      @params[:bind].eval("self")
    end
    #--------------------------------------------------------------------------
    # ● 呼び出し元のシーンへ戻る
    #--------------------------------------------------------------------------
    def return_scene(forced = true)
      @return_scene = true
      if !forced && Input.press?(ATTRIBUTE_KEY)
        @return_scene = !RUN_ONCE
      end
    end
    #--------------------------------------------------------------------------
    # ● コマンドの呼び出し
    #--------------------------------------------------------------------------
    def call_command(*args)
      instance_exec(*args, &@params[:command]) if @params[:command]
    end
    #--------------------------------------------------------------------------
    # ● デフォルトのハンドラを設定する
    #--------------------------------------------------------------------------
    def set_template_handler(window)
      if @params[:command]
        window.set_handler(:ok, method(:on_command))
      else
        window.set_handler(:ok, method(:on_ok))
      end
      window.set_handler(:cancel, method(:on_cancel))
    end
    #--------------------------------------------------------------------------
    # ● 決定されたとき (継承先で上書き)
    #--------------------------------------------------------------------------
    def on_ok
      # self.result = 0
      return_scene
    end
    #--------------------------------------------------------------------------
    # ● 決定されたとき (継承先で上書き)
    #--------------------------------------------------------------------------
    def on_command
      # call_command(value)
      # self.result = 0
      return_scene
    end
    #--------------------------------------------------------------------------
    # ● キャンセルされたとき
    #--------------------------------------------------------------------------
    def on_cancel
      self.result = nil
      return_scene
    end
  end
end
module CAO::MACRO
  class Window_Command < ::Window_Command
    include ::CAO::MACRO::Selectable
    #------------------------------------------------------------------------
    # ● オブジェクト初期化
    #------------------------------------------------------------------------
    def initialize(params = {})
      @commands = params[:commands] || []
      define_properties(params)
      super(0, 0)
      move_center
      select(params[:index] || 0)
    end
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def reserved_properties
      super + [:commands, :index]
    end
    #------------------------------------------------------------------------
    # ● 表示行数の取得
    #------------------------------------------------------------------------
    def visible_line_number
      num = (Graphics.height - standard_padding * 2) / line_height
      num = (item_max + col_max - 1) / col_max if item_max / col_max < num
      num
    end
    #------------------------------------------------------------------------
    # ● 横に項目が並ぶときの空白の幅を取得
    #------------------------------------------------------------------------
    def spacing
      return 8
    end
    #------------------------------------------------------------------------
    # ● コマンドリストの作成
    #------------------------------------------------------------------------
    def make_command_list
      clear_command_list
      @commands.each_with_index {|cmd,i| add_command(cmd, i) }
    end
    #------------------------------------------------------------------------
    # ● 結果
    #------------------------------------------------------------------------
    def result
      index
    end
  end
  class Scene_Command < Scene_Base
    #------------------------------------------------------------------------
    # ● 開始処理
    #------------------------------------------------------------------------
    def start
      super
      @command_window = Window_Command.new(@params)
      set_template_handler(@command_window)
      adjust_all_windows
    end
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def on_ok
      self.result = @command_window.result
      return_scene
    end
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def on_command
      call_command(@command_window.result)
      @command_window.activate
    end
  end
end
def InputCommand(params, &block)
  params[:command] = block if block
  CAO::MACRO::Scene_Command.run(params)
end
module CAO::MACRO
  class Window_Number < ::Window_Selectable
    include ::CAO::MACRO::Selectable
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    attr_reader :number
    #------------------------------------------------------------------------
    # ● オブジェクト初期化
    #------------------------------------------------------------------------
    def initialize(params = {})
      define_properties(params)
      @default_number = params.fetch(:number, nonzero ? 1 : 0)
      if nonzero && @default_number.zero?
        raise ArgumentError, "初期値 0 に nonzero が指定されています。"
      end
      super(0, 0, window_width, window_height)
      move_center
      select([0, [params.fetch(:index, item_max-1), item_max-1].min].max)
      activate
      reset
    end
    #------------------------------------------------------------------------
    # ● マイナス値を使用するか
    #------------------------------------------------------------------------
    def signedness
      false
    end
    #------------------------------------------------------------------------
    # ● ゼロにしない
    #------------------------------------------------------------------------
    def nonzero
      false
    end
    #------------------------------------------------------------------------
    # ● 項目の幅を取得
    #------------------------------------------------------------------------
    def item_width
      14
    end
    #------------------------------------------------------------------------
    # ● ウィンドウの幅を計算
    #------------------------------------------------------------------------
    def window_width
      item_max = self.item_max + (signedness ? 1 : 0)
      item_width * item_max + standard_padding * 2
    end
    #------------------------------------------------------------------------
    # ● ウィンドウの高さを計算
    #------------------------------------------------------------------------
    def window_height
      fitting_height(1)
    end
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def reserved_properties
      super + [:number]
    end
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def number=(value)
      num = value.abs.tap {|n| break @default_number if nonzero && n == 0 }
      @digits = sprintf("%0#{item_max}d", num).chars.map(&:to_i)
      @negative = value < 0
      refresh
      call_update_help
    end
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def number
      @digits.join.to_i.tap {|n| break -n if @negative }
    end
    #------------------------------------------------------------------------
    # ● カーソル位置の設定
    #------------------------------------------------------------------------
    def index=(index)
      @index = index
      update_cursor
      # call_update_help が必要なのは number が変更されたとき
    end
    #------------------------------------------------------------------------
    # ● 項目を描画する矩形の取得
    #------------------------------------------------------------------------
    def item_rect(index)
      super.tap {|rect| rect.x += item_width if signedness }
    end
    #------------------------------------------------------------------------
    # ● 項目を描画する矩形の取得（テキスト用）
    #------------------------------------------------------------------------
    def item_rect_for_text(index)
      item_rect(index).tap do |rect|
        rect.x += 2
        rect.width -= 2
      end
    end
    #------------------------------------------------------------------------
    # ● 全項目の描画
    #------------------------------------------------------------------------
    def draw_all_items
      draw_sign if signedness
      item_max.times {|i| draw_item(i) }
    end
    #------------------------------------------------------------------------
    # ● 項目の描画
    #------------------------------------------------------------------------
    def draw_item(index)
      change_color(normal_color)
      draw_text(item_rect_for_text(index), @digits[index], 1)
    end
    #------------------------------------------------------------------------
    # ● の描画
    #------------------------------------------------------------------------
    def draw_sign
      rect = Rect.new(0, 0, item_width, item_height)
      contents.clear_rect(rect)
      change_color(normal_color)
      draw_text(rect, @negative ? '-' : '+', 1)
    end
    #------------------------------------------------------------------------
    # ● 桁数の取得
    #------------------------------------------------------------------------
    def col_max
      item_max
    end
    #------------------------------------------------------------------------
    # ● 横に項目が並ぶときの空白の幅を取得
    #------------------------------------------------------------------------
    def spacing
      0
    end
    #------------------------------------------------------------------------
    # ● 項目数の取得
    #------------------------------------------------------------------------
    def item_max
      8
    end
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def reset
      self.number = @default_number
    end
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def changesign
      @negative = !@negative
      draw_sign
    end
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def zero?
      @digits.all? {|n| n == 0 }
    end
    #------------------------------------------------------------------------
    # ● カーソルを下に移動
    #------------------------------------------------------------------------
    def cursor_down(wrap = false)
      @digits[index] = (@digits[index] + 9) % 10
      self.number = 9 if nonzero && zero?
      redraw_item(index)
      Sound.play_cursor
      call_update_help
    end
    #------------------------------------------------------------------------
    # ● カーソルを上に移動
    #------------------------------------------------------------------------
    def cursor_up(wrap = false)
      @digits[index] = (@digits[index] + 1) % 10
      self.number = 1 if nonzero && zero?
      redraw_item(index)
      Sound.play_cursor
      call_update_help
    end
    #------------------------------------------------------------------------
    # ● R
    #------------------------------------------------------------------------
    def cursor_pagedown
      if signedness
        changesign
        Sound.play_cursor
      end
    end
    #------------------------------------------------------------------------
    # ● L
    #------------------------------------------------------------------------
    def cursor_pageup
      reset
      Sound.play_cursor
    end
    #------------------------------------------------------------------------
    # ● 結果
    #------------------------------------------------------------------------
    def result
      self.number
    end
  end
  class Scene_Number < Scene_Base
    #------------------------------------------------------------------------
    # ● 開始処理
    #------------------------------------------------------------------------
    def start
      super
      @number_window = Window_Number.new(@params)
      @number_window.set_handler(:ok, method(:on_ok))
      @number_window.set_handler(:cancel, method(:on_cancel))
      adjust_all_windows
    end
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def on_ok
      self.result = @number_window.result
      return_scene
    end
  end
end
def InputNumber(params = {})
  CAO::MACRO::Scene_Number.run(params)
end
module CAO::MACRO
  class Window_List < ::Window_Selectable
    include ::CAO::MACRO::Selectable
    #------------------------------------------------------------------------
    # ● オブジェクト初期化
    #------------------------------------------------------------------------
    def initialize(params = {})
      @commands = params[:commands] || []
      @data = params[:data] || []
      @digit_number = @commands.size.to_s.size
      @col_index = @digit_number
      define_properties(params)
      super(0, 0, window_width, window_height)
      move_center
      self.index = start_id
      activate
    end
    #------------------------------------------------------------------------
    # ● ウィンドウの幅を計算
    #------------------------------------------------------------------------
    def window_width
      380
    end
    #------------------------------------------------------------------------
    # ● ウィンドウの高さを計算
    #------------------------------------------------------------------------
    def window_height
      fitting_height(row_max + 1)
    end
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def reserved_properties
      super + [:commands, :data]
    end
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def index=(value)
      @index = (value < start_id) ? start_id : value
      @digits = sprintf("%0#{col_max}d", @index).chars.map(&:to_i)
      refresh
      call_update_help
    end
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def col_index=(value)
      @col_index = value
      update_cursor
    end
    #--------------------------------------------------------------------------
    # ● 横に項目が並ぶときの空白の幅を取得
    #--------------------------------------------------------------------------
    def spacing
      0
    end
    #--------------------------------------------------------------------------
    # ● 項目数の取得
    #--------------------------------------------------------------------------
    def item_max
      @commands.size
    end
    #--------------------------------------------------------------------------
    # ● 項目の幅を取得
    #--------------------------------------------------------------------------
    def item_width
      contents.width
    end
    #--------------------------------------------------------------------------
    # ● 項目の高さを取得
    #--------------------------------------------------------------------------
    def item_height
      line_height
    end
    #--------------------------------------------------------------------------
    # ● 行数の取得
    #--------------------------------------------------------------------------
    def row_max
      9
    end
    #--------------------------------------------------------------------------
    # ● 桁数の取得
    #--------------------------------------------------------------------------
    def col_max
      @digit_number
    end
    #--------------------------------------------------------------------------
    # ● リストの開始番号の取得
    #--------------------------------------------------------------------------
    def start_id
      0
    end
    #--------------------------------------------------------------------------
    # ● リストの最後の番号の取得
    #--------------------------------------------------------------------------
    def last_id
      item_max + start_id - 1
    end
    #--------------------------------------------------------------------------
    # ● 先頭の項目の ID の取得
    #--------------------------------------------------------------------------
    def top_item_id
      index - row_before
    end
    #--------------------------------------------------------------------------
    # ● 現在の行から前に何行あるか取得
    #--------------------------------------------------------------------------
    def row_before
      (row_max + 1) / 2
    end
    #--------------------------------------------------------------------------
    # ● 1 ページに表示できる行数の取得
    #--------------------------------------------------------------------------
    def page_row_max
      row_before * 2 + 1
    end
    #--------------------------------------------------------------------------
    # ● 項目を描画する矩形の取得
    #--------------------------------------------------------------------------
    def item_rect(index)
      rect = Rect.new
      rect.x = 0
      rect.y = (line_height * index) - (line_height / 2)
      rect.width = contents.width
      rect.height = line_height
      rect
    end
    #--------------------------------------------------------------------------
    # ● 桁の幅を取得
    #--------------------------------------------------------------------------
    def digit_width
      @digit_width ||= contents.text_size("0").width
    end
    #--------------------------------------------------------------------------
    # ● 桁を描画する矩形の取得
    #--------------------------------------------------------------------------
    def digit_rect(index)
      rect = item_rect(index)
      rect.width = digit_width
      if index < col_max
        rect.x = index * rect.width
      else
        rect.width *= col_max
      end
      rect
    end
    #--------------------------------------------------------------------------
    # ● 選択項目の有効状態を取得
    #--------------------------------------------------------------------------
    def current_item_enabled?
      start_id <= self.index && self.index <= last_id
    end
    #--------------------------------------------------------------------------
    # ● 全項目の描画
    #--------------------------------------------------------------------------
    def draw_all_items
      page_row_max.times {|i| draw_item(i) }
    end
    #------------------------------------------------------------------------
    # ● 項目の描画
    #------------------------------------------------------------------------
    def draw_item(index)
      change_color(normal_color)
      id = top_item_id + index
      return if self.index != id && (id < start_id || id > last_id)
      digits_width = digit_rect(col_max).width
      rect = digit_rect(index)
      rect.x = 0
      rect.width = digits_width + 4
      draw_text(rect, sprintf("%0#{col_max}d", id))
      rect.x += digits_width + 8
      rect.width = contents.width - rect.x
      draw_text(rect, command_name(id))
      draw_text(rect, command_data(id), 2)
    end
    #------------------------------------------------------------------------
    # ● 項目の再描画
    #------------------------------------------------------------------------
    def redraw_item_id(id)
      redraw_item(id - top_item_id)
    end
    #------------------------------------------------------------------------
    # ● 項目名の取得
    #------------------------------------------------------------------------
    def command_name(id)
      @commands[id]
    end
    #------------------------------------------------------------------------
    # ● 項目データの取得
    #------------------------------------------------------------------------
    def command_data(id)
      @data[id] || ""
    end
    #--------------------------------------------------------------------------
    # ● カーソルを下に移動
    #--------------------------------------------------------------------------
    def cursor_down(wrap = false)
      if @col_index < col_max
        digits = sprintf("%0#{col_max}d", self.index).chars.map(&:to_i)
        digits[@col_index] -= 1
        digits[@col_index] = 9 if digits[@col_index] < 0
        self.index = digits.join.to_i
      else
        if self.index < last_id
          self.index += 1
        else
          self.index = start_id
        end
      end
    end
    #--------------------------------------------------------------------------
    # ● カーソルを上に移動
    #--------------------------------------------------------------------------
    def cursor_up(wrap = false)
      if @col_index < col_max
        n = sprintf("%0#{col_max}d", last_id).chars.map(&:to_i)[@col_index]
        digits = sprintf("%0#{col_max}d", self.index).chars.map(&:to_i)
        digits[@col_index] += 1
        digits[@col_index] = 0 if digits[@col_index] > 9
        self.index = digits.join.to_i
      else
        if self.index == start_id
          self.index = last_id
        elsif self.index > last_id
          self.index = last_id
        else
          self.index -= 1
        end
      end
    end
    #--------------------------------------------------------------------------
    # ● カーソルを右に移動
    #--------------------------------------------------------------------------
    def cursor_right(wrap = false)
      self.col_index = (@col_index + 1) % (col_max + 1)
    end
    #--------------------------------------------------------------------------
    # ● カーソルを左に移動
    #--------------------------------------------------------------------------
    def cursor_left(wrap = false)
      self.col_index = (@col_index + col_max) % (col_max + 1)
    end
    #--------------------------------------------------------------------------
    # ● カーソルを 1 ページ後ろに移動
    #--------------------------------------------------------------------------
    def cursor_pagedown
      if self.index == last_id
        index = start_id
      else
        index = self.index + (page_row_max - 1)
        index = last_id if index > last_id
      end
      self.index = index
    end
    #--------------------------------------------------------------------------
    # ● カーソルを 1 ページ前に移動
    #--------------------------------------------------------------------------
    def cursor_pageup
      if self.index == start_id
        index = last_id
      else
        index = self.index - (page_row_max - 1)
        index = start_id if index < start_id
      end
      self.index = index
    end
    #--------------------------------------------------------------------------
    # ● カーソルの更新
    #--------------------------------------------------------------------------
    def update_cursor
      if @col_index < 0
        cursor_rect.empty
      else
        rect = digit_rect(@col_index)
        rect.y = (line_height * row_before) - (line_height / 2)
        cursor_rect.set(rect)
      end
    end
    #--------------------------------------------------------------------------
    # ● カーソルの移動処理
    #--------------------------------------------------------------------------
    def process_cursor_move
      return unless cursor_movable?
      last_index = @index
      last_col_index = @col_index
      process_cursor_button
      if @index != last_index || @col_index != last_col_index
        Sound.play_cursor
      end
    end
    #------------------------------------------------------------------------
    # ● カーソルモードの切り替え
    #------------------------------------------------------------------------
    def cursor_switch
      self.col_index = (@col_index == col_max) ? col_max - 1 : col_max
    end
    #------------------------------------------------------------------------
    # ● 結果
    #------------------------------------------------------------------------
    def result
      return @data[index]
    end
  end
  class Scene_List < Scene_Base
    #------------------------------------------------------------------------
    # ● 開始処理
    #------------------------------------------------------------------------
    def start
      super
      @list_window = Window_List.new(@params)
      set_template_handler(@list_window)
      @list_window.set_handler(:btn_x, method(:on_btn_x))
      @list_window.set_handler(:btn_y, method(:on_btn_y))
      adjust_all_windows
    end
    #------------------------------------------------------------------------
    # ● 決定
    #------------------------------------------------------------------------
    def on_ok
      self.result = @list_window.index
      return_scene
    end
    #------------------------------------------------------------------------
    # ● 決定 (コマンド)
    #------------------------------------------------------------------------
    def on_command
      call_command(@list_window.index, @list_window.result)
      @list_window.activate
    end
    #------------------------------------------------------------------------
    # ● X ボタン (カーソルリセット)
    #------------------------------------------------------------------------
    def on_btn_x
      @list_window.cursor_switch
    end
    #------------------------------------------------------------------------
    # ● Y ボタン (検索)
    #------------------------------------------------------------------------
    def on_btn_y
      @list_window.instance_eval do
        word = InputBox("検索する文字を入力してください", "検索")
        return if word.empty?
        list = @commands || @data
        serach =
          if word[0] == "^"
            word[0] = ""
            -> x { x && x.start_with?(word)  }
          else
            -> x { x && x.include?(word)  }
          end
        if self.index < last_id
          index = list[self.index..-1].find_index {|s| serach[s] }
          if index
            index = self.index + index
          else
            index = list[0, self.index].find_index {|s| serach[s] }
          end
        else
          index = list.find_index {|s| serach[s] }
        end
        if index
          self.index = index
        else
          msgbox "#{word} が見つかりません"
        end
      end
    end
  end
end
def InputList(params = {}, &block)
  params[:command] = block if block
  CAO::MACRO::Scene_List.run(params)
end
module CAO::MACRO
  class Window_Folder < ::Window_Command
    #------------------------------------------------------------------------
    # ● オブジェクト初期化
    #------------------------------------------------------------------------
    def initialize
      super(0, 0)
      activate
    end
    #------------------------------------------------------------------------
    # ● ウィンドウ幅の取得
    #------------------------------------------------------------------------
    def window_width
      Graphics.width
    end
    #------------------------------------------------------------------------
    # ● ウィンドウ高さの取得
    #------------------------------------------------------------------------
    def window_height
      fitting_height(4)
    end
    #------------------------------------------------------------------------
    # ● 桁数の取得
    #------------------------------------------------------------------------
    def col_max
      return 2
    end
    #------------------------------------------------------------------------
    # ● コマンドリストの作成
    #------------------------------------------------------------------------
    def make_command_list
      add_command(File.basename(DirEx.pwd), :root)
      DirEx.glob("#{DIRECTORY}/*", dir: true) do |path|
        name = File.basename(path).split(' ', 2)[-1]
        add_command(name, path) if name != '_'
      end
    end
  end
end
module CAO::MACRO
  class Window_File < ::Window_Command
    #------------------------------------------------------------------------
    # ● 公開インスタンス変数
    #------------------------------------------------------------------------
    attr_accessor :pwd                      # 選択中フォルダパス
    #------------------------------------------------------------------------
    # ● オブジェクト初期化
    #------------------------------------------------------------------------
    def initialize
      super(0, fitting_height(4))
      unselect
      deactivate
    end
    #------------------------------------------------------------------------
    # ● ウィンドウ幅の取得
    #------------------------------------------------------------------------
    def window_width
      Graphics.width
    end
    #------------------------------------------------------------------------
    # ● ウィンドウ高さの取得
    #------------------------------------------------------------------------
    def window_height
      Graphics.height - fitting_height(4)
    end
    #------------------------------------------------------------------------
    # ● 桁数の取得
    #------------------------------------------------------------------------
    def col_max
      return 2
    end
    #------------------------------------------------------------------------
    # ● コマンドリストの作成
    #------------------------------------------------------------------------
    def make_command_list
      case self.pwd
      when nil
        # Do Nothing
      when :root
        add_commands("./Macro/*.rb", "_")
        add_commands("#{DIRECTORY}/_/#{File.basename(DirEx.pwd)}/*.rb", "_")
        add_commands("#{DIRECTORY}/*.rb", "_")
      else
        add_commands("#{self.pwd}/*.rb")
      end
    end
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def add_commands(pattern, skip_name = "")
      DirEx.glob(pattern) do |path|
        name = DirEx.split(path)[-1].split(' ', 2)[-1]
        add_command(File.basename(name, ".rb"), path) if name != skip_name
      end
    end
  end
end
module CAO::MACRO
  class ::Scene_Macro < Scene_Base
    #------------------------------------------------------------------------
    # ● 開始処理
    #------------------------------------------------------------------------
    def start
      super
      @macro_window = Window_File.new
      @macro_window.set_handler(:ok, method(:run_macro))
      @macro_window.set_handler(:cancel, method(:return_window))
      @folder_window = Window_Folder.new
      @folder_window.set_handler(:ok, method(:change_folder))
      @folder_window.set_handler(:cancel, method(:return_scene))
      adjust_all_windows
    end
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def run_macro
      once = RUN_ONCE ^ Input.press?(ATTRIBUTE_KEY)
      result = CAO::MACRO.run(
        @macro_window.current_symbol, @params[:bind] || binding)
      if result != :continue && once
        return_scene
      else
        @macro_window.activate
      end
    end
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def return_window
      @macro_window.unselect
      @macro_window.deactivate
      @macro_window.pwd = nil
      @macro_window.refresh
      @folder_window.activate
    end
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def change_folder
      @folder_window.deactivate
      @macro_window.activate
      @macro_window.pwd = @folder_window.current_symbol
      @macro_window.select(0)
      @macro_window.refresh
    end
  end
end
