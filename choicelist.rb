#******************************************************************************
#
#    ＊ ＜拡張＞ 選択肢の表示
#
#  --------------------------------------------------------------------------
#    バージョン ： 0.0.1
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： http://cacaosoft.webcrow.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#   ： メッセージウィンドウが表示されていなければ選択肢を中央に表示
#   ： 項目名、決定時処理、選択中処理をスクリプトで設定
#
#  --------------------------------------------------------------------------
#   == 使用方法 ==
#
#    ★ 選択肢の項目を指定
#     選択肢１に CHOICES_PROC の識別子を入力します。
#    例）＃アクター
#
#    ★ 選択肢の決定と更新を設定
#     選択肢１に項目指定の後に ;[CHOICES_PROCの識別子] を追記します。
#     項目の決定時処理とカーソル位置更新時処理は , で区切ります。
#     片方しか設定しない場合は [決定] もしくは [,更新] のようにします。
#    例）＃アクター; [＆項目名,＆更新]
#
#    ★ オプションの設定
#     選択肢１の末尾に追記します。通常の選択肢表示でも使用できます。
#
#     ○ ウィンドウの表示位置
#      選択肢１に ;center もしくは ;中央 を追記すると 中央表示
#      選択肢１に ;left もしくは ;左 を追記すると 左寄せ表示
#
#     ○ 項目の２列表示
#      選択肢１に ;2col もしくは ;２列 を追記する。
#
#
#******************************************************************************


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
module CLEX
  #--------------------------------------------------------------------------
  # ◇ 選択肢の処理
  #--------------------------------------------------------------------------
  CHOICES_PROC = {}   # nil と "" 禁止
  
  # 項目名
  CHOICES_PROC["＃パーティ"] = -> { $game_party.members.map!(&:name) }
  CHOICES_PROC["＃アクター"] = -> { $data_actors.compact.map!(&:name) }
  CHOICES_PROC["＃道具"] = -> { $data_items.compact.map!(&:name) }
  CHOICES_PROC["＃武器"] = -> { $data_weapons.compact.map!(&:name) }
  CHOICES_PROC["＃防具"] = -> { $data_armors.compact.map!(&:name) }
  CHOICES_PROC["＃アイテム"] =
    -> { [*$data_items, *$data_weapons, *$data_armors].compact.map!(&:name) }
  CHOICES_PROC["three"] = -> { %w[キャラＡ キャラＢ キャラＣ] }
  
  # 決定
  CHOICES_PROC["default_decide"] = -> x { $game_variables[8] = x }
  CHOICES_PROC["＆項目名"] =
    -> x { $game_variables[8] = $game_message.choices[x] }
  
  # 選択更新
  CHOICES_PROC["＆更新"] = -> x {
    $game_map.screen.pictures.each do |pic|
      next if pic.number < 4
      break if 6 < pic.number
      pic.instance_variable_set(:@opacity,pic.number == x + 4 ? 255 : 0)
    end
  }
end # module CLEX
end # module CAO


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class Game_Message
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :choice_update      # 選択肢 選択中処理
  attr_accessor :choice_options     # 選択肢 オプション
  #--------------------------------------------------------------------------
  # ● クリア
  #--------------------------------------------------------------------------
  alias _cao_choice_clear clear
  def clear
    _cao_choice_clear
    @choice_update = nil
    @choice_options = {}
  end
end
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 選択肢のセットアップ
  #--------------------------------------------------------------------------
  def setup_choices(params)
    commands, cancel_type = params[0].dup, params[1]
    key, *opts = commands[0].split(";").map!(&:strip)
    cccp = CAO::CLEX::CHOICES_PROC
    $game_message.choice_options =
      opts.each_with_object({}) {|x,r| r[x] = !x.empty?  }
    if cccp.has_key?(key)
      $game_message.choices.replace(cccp[key].call)
      cancel_type = params[1] == 5 ? $game_message.choices.size + 1 : 0
      $game_message.choice_cancel_type = cancel_type
      decide,selection =
        opts[0] && opts[0][/^\[(.+?)\]$/,1].tap {|s| break s.split(",") if s }
      $game_message.choice_update = cccp[selection]
      choice_decide = cccp[decide] || cccp["default_decide"]
      $game_message.choice_proc = Proc.new do |n|
        if n == cancel_type - 1
          @branch[@indent] = 4  # キャンセル
        else
          @branch[@indent] = 0  # 決定
          choice_decide.call(n)
        end
      end
    else
      commands[0] = commands[0].split(";")[0]  # オプション部分を削除
      commands.each {|s| $game_message.choices.push(s) }
      $game_message.choice_cancel_type = cancel_type
      $game_message.choice_proc = Proc.new {|n| @branch[@indent] = n }
    end
  end
end
class Window_ChoiceList < Window_Command
  #--------------------------------------------------------------------------
  # ● 入力処理の開始
  #--------------------------------------------------------------------------
  def start
    clear_command_list
    make_command_list
    update_placement
    create_contents
    refresh
    select(0)
    open
    activate
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ位置の更新
  #--------------------------------------------------------------------------
  def update_placement
    self.width = window_width
    self.height = window_height
    if @message_window.open?
      case window_position
      when 0  # 左
        self.x = 0
      when 1  # 中央
        self.x = (Graphics.width - width) / 2
      else    # 右
        self.x = Graphics.width - width
      end
      if @message_window.y >= Graphics.height / 2
        self.y = @message_window.y - height
      else
        self.y = @message_window.y + @message_window.height
      end
    else
      self.x = (Graphics.width - width) / 2
      self.y = (Graphics.height - height) / 2
    end
    self.y = 0 if y < 0
  end
  #--------------------------------------------------------------------------
  # ● リフレッシュ
  #--------------------------------------------------------------------------
  def refresh
    contents.clear
    draw_all_items
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ位置
  #--------------------------------------------------------------------------
  def window_position
    gmco = $game_message.choice_options
    return 0 if gmco["left"] || gmco["左"]
    return 1 if gmco["center"] || gmco["中央"]
    return 2
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ幅の取得
  #--------------------------------------------------------------------------
  def window_width
    padding = spacing * (col_max - 1) + standard_padding * 2
    return [(max_choice_width) * col_max + padding, Graphics.width].min
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ高さの取得
  #--------------------------------------------------------------------------
  def window_height
    [
      fitting_height(row_max),
      if @message_window.open?
        [
          @message_window.y,
          Graphics.height - @message_window.y - @message_window.height
        ].max
      else
        Graphics.height
      end
    ].min
  end
  #--------------------------------------------------------------------------
  # ● ウィンドウ内容の高さを計算
  #--------------------------------------------------------------------------
  def contents_height
    row_max * item_height
  end
  #--------------------------------------------------------------------------
  # ● 桁数の取得
  #--------------------------------------------------------------------------
  def col_max
    gmco = $game_message.choice_options
    return 2 if gmco["2col"] || gmco["２列"]
    return 1
  end
  #--------------------------------------------------------------------------
  # ● 横に項目が並ぶときの空白の幅を取得
  #--------------------------------------------------------------------------
  def spacing
    return standard_padding
  end
  #--------------------------------------------------------------------------
  # ● 選択肢の最大幅を取得
  #--------------------------------------------------------------------------
  def max_choice_width
    str = $game_message.choices.max_by {|s|
      s.each_char.inject(0) {|r,c| r + (c.bytesize == 1 ? 1 : 2) }
    }
    return [str && (text_size(str).width + 12) || 0, 96].max
  end
  #--------------------------------------------------------------------------
  # ● カーソルの更新
  #--------------------------------------------------------------------------
  def update_cursor
    super
    $game_message.choice_update === index
  end
end
