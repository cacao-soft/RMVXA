#******************************************************************************
#
#    ＊ ＜拡張＞ アイテム選択の処理
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.2.3
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#   ： キーアイテム以外のものも選べるようにします。
#   ： ヘルプウィンドウを表示する機能を追加します。
#
#  --------------------------------------------------------------------------
#   == 注意事項 ==
#
#    ※ 変数には、ＩＤではなくアイテムのデータが代入されます。
#    ※ 選択しなかった場合は 0 が代入されます。
#
#  --------------------------------------------------------------------------
#   == 使用方法 ==
#
#     以下のスクリプトを実行後、「アイテムの選択」を実行してください。
#
#    ★ 選択アイテムの設定する
#     $game_message.item_choice_category にキーワードを代入してください。
#     :all      .. すべての所持品
#     :all_item .. すべてのアイテム
#     :item     .. キーアイテム以外のアイテム
#     :weapon   .. すべての武器
#     :armor    .. すべての防具
#     :equip    .. 武器と防具
#     :sell     .. キーアイテム以外で価格が０でないもの
#     "keyword" .. メモ欄に <keyword> と書かれているもの
#
#    ★ ショップアイテムから選択する
#     $game_message.item_choice_from_goods = true
#     このスクリプトを実行後、ショップの処理でアイテムを設定してください。
#
#    ★ 所持数を非表示にする
#     $game_message.item_choice_hide_number = true
#
#    ★ キャンセルを無効にする
#     $game_message.item_choice_cancel_disabled = true
#
#    ★ 未所持アイテムも表示する
#     $game_message.item_choice_show_nothing = true
#
#    ※ 上記４つの設定は、アイテム選択の処理後に初期化されます。
#
#    ★ アイテム選択ウィンドウの行数を変更する
#     $game_message.item_choice_line = 行数
#
#    ★ ヘルプウィンドウの行数を変更する
#     $game_message.item_choice_help_line = 行数
#     ※ 0 のときは、ヘルプウィンドウが非表示になります。
#
#    ★ カテゴリのアイテム所持数を取得する
#     $game_party.item_count(category)
#     category は、$game_message.item_choice_category と同じものです。
#
#
#******************************************************************************


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
  module ItemChoice

    #--------------------------------------------------------------------------
    # ◇ 種類によるＩＤの増加値
    #--------------------------------------------------------------------------
    PLUS_ID = 0
    #--------------------------------------------------------------------------
    # ◇ 行数の設定 (初期値)
    #--------------------------------------------------------------------------
    ITEM_LINE = 4       # アイテム選択ウィンドウ
    HELP_LINE = 0       # ヘルプウィンドウ ( 0 のとき非表示)
    #--------------------------------------------------------------------------
    # ◇ 表示位置の設定
    #--------------------------------------------------------------------------
    POS_TOP = false

  end # module ItemChoice
  end # module CAO


  #/////////////////////////////////////////////////////////////////////////////#
  #                                                                             #
  #                下記のスクリプトを変更する必要はありません。                 #
  #                                                                             #
  #/////////////////////////////////////////////////////////////////////////////#


  class CAO::Dummy_ItemList < Window_ItemList
    #--------------------------------------------------------------------------
    # ● メソッド定義の取り消し
    #--------------------------------------------------------------------------
    # undef_method *self.superclass.instance_methods(false)
    # def include?(item); super; end
    #--------------------------------------------------------------------------
    # ● オブジェクト初期化
    #--------------------------------------------------------------------------
    def initialize
      @category = :none
    end
    #--------------------------------------------------------------------------
    # ● カテゴリのアイテム所持数を取得
    #--------------------------------------------------------------------------
    def count(category)
      @category = category
      return $game_party.all_items.count {|item| include?(item) }
    end
  end

  class Game_Party
    #--------------------------------------------------------------------------
    # ● カテゴリのアイテム所持数を取得
    #--------------------------------------------------------------------------
    def item_count(category)
      return CAO::Dummy_ItemList.new.count(category)
    end
  end

  class Game_Message
    #--------------------------------------------------------------------------
    # ● 公開インスタンス変数
    #--------------------------------------------------------------------------
    attr_accessor :item_choice_category         # アイテム選択 カテゴリ
    attr_accessor :item_choice_from_goods       # アイテム選択 商品から選択
    attr_accessor :item_choice_goods            # アイテム選択 選択アイテム
    attr_accessor :item_choice_hide_number      # アイテム選択 所持数非表示
    attr_accessor :item_choice_cancel_disabled  # アイテム選択 キャンセル無効
    attr_accessor :item_choice_show_nothing     # アイテム選択 未所持でも表示
    attr_accessor :item_choice_line             # アイテム選択 行数
    attr_accessor :item_choice_help_line        # アイテム選択 ヘルプの行数
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def clear_item_choice
      @item_choice_category = :key_item
      @item_choice_from_goods = false
      @item_choice_goods = []
      @item_choice_hide_number = false
      @item_choice_cancel_disabled = false
      @item_choice_show_nothing = false
    end
  end

  class Game_Interpreter
    #--------------------------------------------------------------------------
    # ○ ショップの処理
    #--------------------------------------------------------------------------
    alias _cao_itemchoice_command_302 command_302
    def command_302
      if $game_message.item_choice_from_goods
        goods = [@params]
        while next_event_code == 605
          @index += 1
          goods.push(@list[@index].parameters)
        end
        $game_message.item_choice_goods = []
        goods.each do |param|
          case param[0]
          when 0; item = $data_items[param[1]]
          when 1; item = $data_weapons[param[1]]
          when 2; item = $data_armors[param[1]]
          end
          $game_message.item_choice_goods.push(item) if item
        end
      else
        _cao_itemchoice_command_302
      end
    end
  end

  class Window_ItemList
    #--------------------------------------------------------------------------
    # ○ アイテムをリストに含めるかどうか
    #--------------------------------------------------------------------------
    alias _cao_itemchoice_include? include?
    def include?(item)
      case @category
      when String
        return item && item.note.include?("<#{@category}>")
      when :all
        return item != nil
      when :all_item
        return item.kind_of?(RPG::Item)
      when :equip
        return item.kind_of?(RPG::Weapon) || item.kind_of?(RPG::Armor)
      when :sell
        return false if item == nil
        return false if item.respond_to?(:key_item?) && item.key_item?
        return false if item.price == 0
        return true
      else
        return _cao_itemchoice_include?(item)
      end
    end
  end

  class Window_KeyItem
    #--------------------------------------------------------------------------
    # ◎ オブジェクト解放
    #--------------------------------------------------------------------------
    def dispose
      @help_window.dispose if @help_window
      super
    end
    #--------------------------------------------------------------------------
    # ◎ ウィンドウを開く
    #--------------------------------------------------------------------------
    def open
      @help_window.open if @help_window
      super
    end
    #--------------------------------------------------------------------------
    # ◎ ウィンドウを閉じる
    #--------------------------------------------------------------------------
    def close
      @help_window.close if @help_window
      super
    end
    #--------------------------------------------------------------------------
    # ◎ アイテムリストの作成
    #--------------------------------------------------------------------------
    alias _cao_itemchoice_make_item_list make_item_list unless $!
    def make_item_list
      if $game_message.item_choice_show_nothing
        if $game_message.item_choice_from_goods
          @data = $game_message.item_choice_goods
        else
          items = $data_items + $data_weapons + $data_armors
          @data = items.select {|item| include?(item) }
        end
      else
        if $game_message.item_choice_from_goods
          @data = $game_party.all_items & $game_message.item_choice_goods
        else
          # super
          _cao_itemchoice_make_item_list
        end
      end
      create_help_window
    end
    #--------------------------------------------------------------------------
    # ● ヘルプウィンドウの作成
    #--------------------------------------------------------------------------
    def create_help_window
      $game_message.item_choice_line ||= CAO::ItemChoice::ITEM_LINE
      $game_message.item_choice_help_line ||= CAO::ItemChoice::HELP_LINE
      @help_window.dispose if @help_window
      if $game_message.item_choice_help_line != 0
        self.help_window = Window_Help.new($game_message.item_choice_help_line)
        @help_window.openness = 0
        @help_window.open
      end
      self.height = fitting_height($game_message.item_choice_line)
      update_placement
    end
    #--------------------------------------------------------------------------
    # ○ アイテムを許可状態で表示するかどうか
    #--------------------------------------------------------------------------
    def enable?(item)
      return true
    end
    #--------------------------------------------------------------------------
    # ○ 決定時の処理
    #--------------------------------------------------------------------------
    def on_ok
      if CAO::ItemChoice::PLUS_ID > 0
        case self.item
        when nil
          result = 0
        when RPG::Weapon
          result = self.item.id + CAO::ItemChoice::PLUS_ID
        when RPG::Armor
          result = self.item.id + CAO::ItemChoice::PLUS_ID * 2
        else
          result = self.item.id
        end
      else
        result = self.item
      end
      $game_variables[$game_message.item_choice_variable_id] = result
      close
    end
    #--------------------------------------------------------------------------
    # ○ キャンセル処理の有効状態を取得
    #--------------------------------------------------------------------------
    def cancel_enabled?
      return false
    end
    #--------------------------------------------------------------------------
    # ◎ フレーム更新
    #--------------------------------------------------------------------------
    alias _cao_itemchoice_update update unless $!
    def update
      # super
      _cao_itemchoice_update
      @help_window.update if @help_window
      if open? && self.active && Input.trigger?(:B)
        Input.update
        if $game_message.item_choice_cancel_disabled
          Sound.play_buzzer
        else
          Sound.play_cancel
          deactivate
          on_cancel
        end
      end
    end
    #--------------------------------------------------------------------------
    # ○ ウィンドウ位置の更新
    #--------------------------------------------------------------------------
    def update_placement
      if $game_message.item_choice_help_line == 0
        help_height = 0
      else
        help_height = @help_window.height
      end
      if CAO::ItemChoice::POS_TOP
        if @message_window.close?
          self.y = help_height
        elsif self.height + help_height < @message_window.y
          self.y = help_height
        else
          self.y = @message_window.y + @message_window.height + help_height
        end
      else
        mbh = Graphics.height - (@message_window.y + @message_window.height)
        if @message_window.close?
          self.y = Graphics.height - self.height
        elsif self.height + help_height < mbh
          self.y = Graphics.height - self.height
        else
          self.y = @message_window.y - self.height
        end
      end
      if $game_message.item_choice_help_line != 0
        @help_window.y = self.y - @help_window.height
      end
    end
    #--------------------------------------------------------------------------
    # ◎ アイテムの個数を描画
    #--------------------------------------------------------------------------
    alias _cao_itemchoice_draw_item_number draw_item_number unless $!
    def draw_item_number(rect, item)
      return if $game_message.item_choice_hide_number
      _cao_itemchoice_draw_item_number(rect, item)
    end
  end

  class Window_Message
    #--------------------------------------------------------------------------
    # ○ アイテムの選択処理
    #--------------------------------------------------------------------------
    def input_item
      @item_window.start
      @item_window.category = ($game_message.item_choice_category || :key_item)
      Fiber.yield while @item_window.active
      $game_message.clear_item_choice
    end
  end
