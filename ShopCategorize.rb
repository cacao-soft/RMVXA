#******************************************************************************
#
#    ＊ ショップアイテム分類
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.0.2
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#   ： ショップ画面で商品を分類して表示します。
#
#  --------------------------------------------------------------------------
#   == 使用方法 ==
#
#    ★ 購入時のカテゴリを変更する
#     $game_system.shop_buy_category の配列を変更してください。
#
#    ★ 売却時のカテゴリを変更する
#     $game_system.shop_sell_category の配列を変更してください。
#
#    ※ 設定する配列は、「初期カテゴリの設定」と同じ設定方法です。
#
#
#******************************************************************************


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
  module CategorizeShop

    #--------------------------------------------------------------------------
    # ◇ 初期カテゴリの設定
    #--------------------------------------------------------------------------
    COMMANDS = [:item, :weapon, :etype1, :etype2, :etype3, :etype4]

    #--------------------------------------------------------------------------
    # ◇ 売却価格の値引率 (1 ＝ 100%)
    #--------------------------------------------------------------------------
    CUT_RATE = 0.5

    #--------------------------------------------------------------------------
    # ◇ アイコン画像の設定
    #--------------------------------------------------------------------------
    IMAGE_ICONS = {}
    #--------------------------------------------------------------------------
    # ◇ カーソルの可視状態
    #--------------------------------------------------------------------------
    VISIBLE_CURSOR = true

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
    FILE_BACKIMAGE_NAME = nil
    #--------------------------------------------------------------------------
    # ◇ ウィンドウの可視状態
    #--------------------------------------------------------------------------
    VISIBLE_BACKWINDOW = true

    #--------------------------------------------------------------------------
    # ◇ カテゴリ名の設定
    #--------------------------------------------------------------------------
    VOCAB_COMMANDS = {}
    VOCAB_COMMANDS[:item]     = "道具"
    VOCAB_COMMANDS[:weapon]   = "武器"
    VOCAB_COMMANDS[:armor]    = "防具"
    VOCAB_COMMANDS[:key_item] = "宝物"

    VOCAB_COMMANDS[:etype0]    = "武器"
    VOCAB_COMMANDS[:etype1]    = "盾"
    VOCAB_COMMANDS[:etype2]    = "頭"
    VOCAB_COMMANDS[:etype3]    = "身体"
    VOCAB_COMMANDS[:etype4]    = "装飾"

  end # module CategorizeShop
  end # module CAO


  #/////////////////////////////////////////////////////////////////////////////#
  #                                                                             #
  #                下記のスクリプトを変更する必要はありません。                 #
  #                                                                             #
  #/////////////////////////////////////////////////////////////////////////////#


  class Game_System
    #--------------------------------------------------------------------------
    # ● 公開インスタンス変数
    #--------------------------------------------------------------------------
    attr_accessor :shop_buy_category        # 購入時のカテゴリ
    attr_accessor :shop_sell_category       # 売却時のカテゴリ
    #--------------------------------------------------------------------------
    # ○ オブジェクト初期化
    #--------------------------------------------------------------------------
    alias _cao_shopcategorize_initialize initialize
    def initialize
      _cao_shopcategorize_initialize
      @shop_buy_category = []
      @shop_sell_category = []
    end
  end

  module ShopItemList
    #--------------------------------------------------------------------------
    # ● 正規表現
    #--------------------------------------------------------------------------
    REGEXP_ETYPE = /etype(\d+)/
    REGEXP_WTYPE = /(?:wtype|weapon)(\d+)/
    REGEXP_ATYPE = /(?:atype|armor)(\d+)/
    #--------------------------------------------------------------------------
    # ● 選択項目の有効状態を取得
    #--------------------------------------------------------------------------
    def current_item_enabled?
      enable?(@data[index])
    end
    #--------------------------------------------------------------------------
    # ● カテゴリの設定
    #--------------------------------------------------------------------------
    def category=(category)
      return if @category == category
      @category = category
      refresh
      self.oy = 0
      self.index = 0
      if @status_window
        @status_window.item = self.item
        @status_window.refresh
      end
    end
    #--------------------------------------------------------------------------
    # ● アイテムをリストに含めるかどうか
    #--------------------------------------------------------------------------
    def include?(item)
      case @category
      when String
        return item && item.note.include?("<#{@category}>")
      when :item
        return item.is_a?(RPG::Item) && !item.key_item?
      when :weapon
        return item.is_a?(RPG::Weapon)
      when :armor
        return item.is_a?(RPG::Armor)
      when :key_item
        return item.is_a?(RPG::Item) && item.key_item?
      else
        case @category.to_s
        when REGEXP_ETYPE
          return item.is_a?(RPG::EquipItem) && item.etype_id == $1.to_i
        when REGEXP_WTYPE
          return item.is_a?(RPG::Weapon) && item.wtype_id == $1.to_i
        when REGEXP_ATYPE
          return item.is_a?(RPG::Armor) && item.atype_id == $1.to_i
        end
      end
      return false
    end
    #--------------------------------------------------------------------------
    # ● ステータスウィンドウの設定
    #--------------------------------------------------------------------------
    def status_window=(status_window)
      @status_window = status_window
      call_update_help
    end
    #--------------------------------------------------------------------------
    # ● ヘルプテキスト更新
    #--------------------------------------------------------------------------
    def update_help
      @help_window.set_item(item) if @help_window
      @status_window.item = item if @status_window
    end
  end

  class Window_ShopBuy
    include ShopItemList
    #--------------------------------------------------------------------------
    # ○ オブジェクト初期化
    #--------------------------------------------------------------------------
    def initialize(x, y, height, shop_goods)
      super(x, y, window_width, height)
      @shop_goods = shop_goods
      @money = 0
    end
    #--------------------------------------------------------------------------
    # ○ アイテムリストの作成
    #--------------------------------------------------------------------------
    def make_item_list
      @data = []
      @price = {}
      @shop_goods.each do |goods|
        case goods[0]
        when 0;  item = $data_items[goods[1]]
        when 1;  item = $data_weapons[goods[1]]
        when 2;  item = $data_armors[goods[1]]
        end
        if item && include?(item)
          @data.push(item)
          @price[item] = goods[2] == 0 ? item.price : goods[3]
        end
      end
    end
  end

  class Window_ShopSell
    include ShopItemList
    #--------------------------------------------------------------------------
    # ● 桁数の取得
    #--------------------------------------------------------------------------
    def col_max
      return 1
    end
    #--------------------------------------------------------------------------
    # ● 項目の描画
    #--------------------------------------------------------------------------
    def draw_item(index)
      item = @data[index]
      rect = item_rect(index)
      draw_item_name(item, rect.x, rect.y, enable?(item))
      rect.width -= 4
      draw_text(rect, price(item), 2)
    end
    #--------------------------------------------------------------------------
    # ● 商品の値段を取得
    #--------------------------------------------------------------------------
    def price(item)
      return Integer(item.price * CAO::CategorizeShop::CUT_RATE)
    end
  end

  #~ class Window
  #~   alias _init_window initialize
  #~ end

  class Window_ShopItemCategory < Window_ItemCategory
    include CAO::CategorizeShop
    #--------------------------------------------------------------------------
    # ● オブジェクト初期化
    #--------------------------------------------------------------------------
    def initialize
      clear_command_list
      _init_window(0, 0, window_width, window_height)
      self.windowskin = Cache.system("Window")
      update_padding
      @opening = @closing = false
      @handler = {}
      @index = -1
      deactivate
    end
    #--------------------------------------------------------------------------
    # ● Window オブジェクト初期化
    #--------------------------------------------------------------------------
    def _init_window(x, y, width, height)
      Window.instance_method(:initialize).bind(self).call(x, y, width, height)
    end
    private :_init_window
    #--------------------------------------------------------------------------
    # ○ ウィンドウ幅の取得
    #--------------------------------------------------------------------------
    def window_width
      return 304
    end
    #--------------------------------------------------------------------------
    # ○ 横に項目が並ぶときの空白の幅を取得
    #--------------------------------------------------------------------------
    def spacing
      return 4
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def commands
      case @item_window
      when Window_ShopBuy
        result = $game_system.shop_buy_category
      when Window_ShopSell
        result = $game_system.shop_sell_category
      else
        raise "must not happen"
      end
      return result.empty? ? COMMANDS : result
    end
    #--------------------------------------------------------------------------
    # ○ 桁数の取得
    #--------------------------------------------------------------------------
    def col_max
      return commands.size
    end
    #--------------------------------------------------------------------------
    # ○ フレーム更新
    #--------------------------------------------------------------------------
    def update
      last_index = @index
      super
      @item_window.category = current_symbol if @item_window
      refresh if @index != last_index
    end
    #--------------------------------------------------------------------------
    # ○ コマンドリストの作成
    #--------------------------------------------------------------------------
    def make_command_list
      self.commands.each {|item| add_command(VOCAB_COMMANDS[item], item) }
    end
    #--------------------------------------------------------------------------
    # ○ カーソルの更新
    #--------------------------------------------------------------------------
    def update_cursor
      if @index < 0 || !VISIBLE_CURSOR
        self.cursor_rect.empty
      else
        ensure_cursor_visible
        cursor_rect.set(item_rect(@index))
      end
    end

    #--------------------------------------------------------------------------
    # ○ アイコンの描画
    #     enabled : 有効フラグ。false のとき半透明で描画
    #--------------------------------------------------------------------------
    def draw_icon(params, x, y, enabled = true)
      if params.kind_of?(Array)
        bitmap = Cache.system(params[0])
        icon_index = params[1]
      else
        bitmap = Cache.system("Iconset")
        icon_index = params
      end
      rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
      self.contents.blt(x, y, bitmap, rect, enabled ? 255 : translucent_alpha)
    end
    #--------------------------------------------------------------------------
    # ○ 項目の描画
    #--------------------------------------------------------------------------
    def draw_item(index)
      rect = item_rect_for_text(index)
      icon_info = IMAGE_ICONS[@list[index][:symbol]]
      if icon_info
        rect.x += (rect.width - 24) / 2
        rect.y += (rect.height - 24) / 2
        if icon_info.kind_of?(String)
          icon_index = icon_info[(self.index == index) ? 2 : 1] || icon_info[1]
          draw_icon([icon_info[0], icon_index], rect.x, rect.y)
        else
          icon_index = icon_info[(self.index == index) ? 1 : 0] || icon_info[0]
          draw_icon(icon_index, rect.x, rect.y)
        end
      else
        change_color(normal_color, command_enabled?(index))
        draw_text(rect, command_name(index), alignment)
      end
    end
    #--------------------------------------------------------------------------
    # ○ 決定処理の有効状態を取得
    #--------------------------------------------------------------------------
    def ok_enabled?
      return false
    end
  end

  class Scene_Shop
    include CAO::CategorizeShop
    #--------------------------------------------------------------------------
    # ○ 開始処理
    #--------------------------------------------------------------------------
    def start
      super
      create_help_window
      create_gold_window
      create_command_window
      create_dummy_window
      create_category_window
      create_number_window
      create_status_window
      create_buy_window
      create_sell_window
      hide_all_backwindows unless VISIBLE_BACKWINDOW
    end
    #--------------------------------------------------------------------------
    # ○ 背景の作成
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
    # ○ 背景の解放
    #--------------------------------------------------------------------------
    def dispose_background
      super
      @backimage_sprite.dispose if @backimage_sprite
      @foreground_sprite.dispose if @foreground_sprite
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
    # ○ カテゴリウィンドウの作成
    #--------------------------------------------------------------------------
    def create_category_window
      @category_window = Window_ShopItemCategory.new
      @category_window.viewport = @viewport
      @category_window.help_window = @help_window
      @category_window.y = @dummy_window.y
      @category_window.hide.deactivate
    end
    #--------------------------------------------------------------------------
    # ○ 個数入力ウィンドウの作成
    #--------------------------------------------------------------------------
    def create_number_window
      wy = @dummy_window.y + @category_window.height
      wh = @dummy_window.height - @category_window.height
      @number_window = Window_ShopNumber.new(0, wy, wh)
      @number_window.viewport = @viewport
      @number_window.hide
      @number_window.set_handler(:ok,     method(:on_number_ok))
      @number_window.set_handler(:cancel, method(:on_number_cancel))
    end
    #--------------------------------------------------------------------------
    # ○ 購入ウィンドウの作成
    #--------------------------------------------------------------------------
    def create_buy_window
      wy = @number_window.y
      wh = @number_window.height
      @buy_window = Window_ShopBuy.new(0, wy, wh, @goods)
      @buy_window.viewport = @viewport
      @buy_window.help_window = @help_window
      @buy_window.status_window = @status_window
      @buy_window.hide
      @buy_window.set_handler(:ok,     method(:on_buy_ok))
      @buy_window.set_handler(:cancel, method(:on_buy_cancel))
    end
    #--------------------------------------------------------------------------
    # ○ 売却ウィンドウの作成
    #--------------------------------------------------------------------------
    def create_sell_window
      wy = @number_window.y
      wh = @number_window.height
      @sell_window = Window_ShopSell.new(0, wy, @number_window.width, wh)
      @sell_window.viewport = @viewport
      @sell_window.help_window = @help_window
      @sell_window.status_window = @status_window
      @sell_window.hide
      @sell_window.set_handler(:ok,     method(:on_sell_ok))
      @sell_window.set_handler(:cancel, method(:on_sell_cancel))
    end
    #--------------------------------------------------------------------------
    # ○ 購入ウィンドウのアクティブ化
    #--------------------------------------------------------------------------
    def activate_buy_window
      @category_window.refresh
      @category_window.show.activate
      @buy_window.money = money
      @buy_window.show.activate
      @status_window.show
    end
    #--------------------------------------------------------------------------
    # ○ 売却ウィンドウのアクティブ化
    #--------------------------------------------------------------------------
    def activate_sell_window
      @category_window.refresh
      @category_window.show.activate
      @sell_window.show.refresh
      @sell_window.show.activate
      @status_window.show
    end
    #--------------------------------------------------------------------------
    # ○ コマンド［購入する］
    #--------------------------------------------------------------------------
    def command_buy
      @category_window.item_window = @buy_window
      @dummy_window.hide
      @category_window.select(0)
      @buy_window.select(0)
      activate_buy_window
    end
    #--------------------------------------------------------------------------
    # ○ コマンド［売却する］
    #--------------------------------------------------------------------------
    def command_sell
      @category_window.item_window = @sell_window
      @dummy_window.hide
      @category_window.select(0)
      @sell_window.select(0)
      activate_sell_window
    end
    #--------------------------------------------------------------------------
    # ○ 購入［決定］
    #--------------------------------------------------------------------------
    def on_buy_ok
      @item = @buy_window.item
      @category_window.deactivate
      @buy_window.hide
      @number_window.set(@item, max_buy, buying_price, currency_unit)
      @number_window.show.activate
    end
    #--------------------------------------------------------------------------
    # ○ 購入［キャンセル］
    #--------------------------------------------------------------------------
    def on_buy_cancel
      @command_window.activate
      @dummy_window.show
      @category_window.hide.deactivate
      @buy_window.hide
      @status_window.hide
      @status_window.item = nil
      @help_window.clear
    end
    #--------------------------------------------------------------------------
    # ○ 売却［決定］
    #--------------------------------------------------------------------------
    def on_sell_ok
      @item = @sell_window.item
      @category_window.deactivate
      @sell_window.hide
      @number_window.set(@item, max_sell, selling_price, currency_unit)
      @number_window.show.activate
    end
    #--------------------------------------------------------------------------
    # ○ 売却［キャンセル］
    #--------------------------------------------------------------------------
    def on_sell_cancel
      @command_window.activate
      @dummy_window.show
      @category_window.hide.deactivate
      @sell_window.hide
      @status_window.hide
      @status_window.item = nil
      @help_window.clear
    end
    #--------------------------------------------------------------------------
    # ○ 売値の取得
    #--------------------------------------------------------------------------
    def selling_price
      @sell_window.price(@item)
    end
  end
