#******************************************************************************
#
#    ＊ 共有マクロ
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.0.0
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： http://cacaosoft.webcrow.jp/
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
    # ●
    #------------------------------------------------------------------------
    def run(path, bind=nil)
      script = File.read(path)
      eval(script, BINDING(script[/\A#!(.+)/,1])||bind, File.basename(path))
    end
    private
    #------------------------------------------------------------------------
    # ●
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
        Scene_Macro.new.run
      end
    end
  end
end # if $TEST
module CAO::MACRO::Selectable
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def move_center
    help_height = @help_window && @help_window.height || 0
    self.x = (Graphics.width  - self.width)  / 2
    self.y = (Graphics.height - help_height - self.height) / 2 - help_height
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def reject_parameter_keys
    [:init, :bind, :proc]
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def define_properties(params)
    list = params.reject {|k,v| reject_parameter_keys.include?(k) }
    list.each do |method_name, value|
      define_parameter(method_name, value)
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def define_parameter(method_name, value)
    case value
    when nil
      # Do Nothing
    when Proc, Method
      define_singleton_method(method_name, value)
    else
      define_singleton_method(method_name) { value }
    end
  end
end
class CAO::MACRO::Scene_Base
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
  # ●
  #--------------------------------------------------------------------------
  def scene
    @params[:bind].eval("self")
  end
  #--------------------------------------------------------------------------
  # ● 呼び出し元のシーンへ戻る
  #--------------------------------------------------------------------------
  def return_scene
    @return_scene = true
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def call_proc(value)
    instance_exec(value, &@params[:proc]) if @params[:proc]
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def set_template_handler(window)
    if @params[:proc]
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
    # call_proc(value)
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
    def reject_parameter_keys
      super + [:commands, :index]
    end
    #------------------------------------------------------------------------
    # ● 表示行数の取得
    #------------------------------------------------------------------------
    def visible_line_number
      num = (Graphics.height - standard_padding * 2) / line_height
      num = item_max / col_max if item_max / col_max < num
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
      call_proc(@command_window.result)
      @command_window.activate
    end
  end
end
def InputCommand(params, &block)
  params[:proc] = block if block
  CAO::MACRO::Scene_Command.new.run(params)
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
      select(item_max - 1)
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
    def reject_parameter_keys
      super + [:number]
    end
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def number=(value)
      @number = value.abs
      @number = @default_number if nonzero && @number.zero?
      @negative = value < 0
      refresh
      call_update_help
    end
    #------------------------------------------------------------------------
    # ● カーソル位置の設定
    #------------------------------------------------------------------------
    def index=(index)
      @index = index
      update_cursor
    end
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def digits
      sprintf("%0#{item_max}d", number).chars.map(&:to_i)
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
      draw_text(item_rect_for_text(index), digits[index], 1)
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
    # ● カーソルを下に移動
    #------------------------------------------------------------------------
    def cursor_down(wrap = false)
      d = digits
      d[index] = (d[index] + 9) % 10
      @number = d.join.to_i
      @number = 9 if nonzero && @number.zero?
      redraw_item(index)
      Sound.play_cursor
      call_update_help
    end
    #------------------------------------------------------------------------
    # ● カーソルを上に移動
    #------------------------------------------------------------------------
    def cursor_up(wrap = false)
      d = digits
      d[index] = (d[index] + 1) % 10
      @number = d.join.to_i
      @number = 1 if nonzero && @number.zero?
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
      if signedness && @negative
        -@number
      else
        @number
      end
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
    #------------------------------------------------------------------------
    # ●
    #------------------------------------------------------------------------
    def on_command
      call_proc([@number_window.index, @number_window.result])
      return_scene
    end
  end
end
def InputNumber(params = {}, &block)
  params[:proc] = block if block
  CAO::MACRO::Scene_Number.new.run(params)
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
