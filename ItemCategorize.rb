#******************************************************************************
#
#    ＊ アイテム分類の細分化
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.0.3
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#   ： アイテム画面での分類を細かく設定できるようにします。
#
#
#******************************************************************************


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
  module CategorizeItem

    #--------------------------------------------------------------------------
    # ◇ カテゴリの設定
    #--------------------------------------------------------------------------
    COMMANDS = [:item, :equip, :key_item]

    #--------------------------------------------------------------------------
    # ◇ カテゴリ名の設定
    #--------------------------------------------------------------------------
    VOCAB_COMMANDS = {}
    VOCAB_COMMANDS[:item]     = [260, "アイテム"]
    VOCAB_COMMANDS[:equip]    = [433, "装備品"]
    VOCAB_COMMANDS[:key_item] = [495, "イベント"]
    VOCAB_COMMANDS[:weapon]   = "武器"
    VOCAB_COMMANDS[:armor]    = "防具"
    VOCAB_COMMANDS[:etype1]   = "盾"
    VOCAB_COMMANDS[:etype2]   = "頭"
    VOCAB_COMMANDS[:etype3]   = "身体"
    VOCAB_COMMANDS[:etype4]   = "装飾"

    #--------------------------------------------------------------------------
    # ◇ キーワードカテゴリ以外でキーワードアイテムを含める
    #--------------------------------------------------------------------------
    INCLUDE_KEYWORD = true

    #--------------------------------------------------------------------------
    # ◇ カーソルの可視状態
    #--------------------------------------------------------------------------
    VISIBLE_CURSOR = true

  end # module CategorizeItem
  end # module CAO


  #/////////////////////////////////////////////////////////////////////////////#
  #                                                                             #
  #                下記のスクリプトを変更する必要はありません。                 #
  #                                                                             #
  #/////////////////////////////////////////////////////////////////////////////#


  module CAO::CategorizeItem
    KEYWORD_PREFIX = "<"
    KEYWORD_SUFFIX = ">"
    KEYWORDS = COMMANDS.select {|k| k.is_a?(String) }
                       .map    {|k| KEYWORD_PREFIX + k + KEYWORD_SUFFIX }
  end

  class Window_ItemCategory
    #--------------------------------------------------------------------------
    # ○ 桁数の取得
    #--------------------------------------------------------------------------
    def col_max
      return CAO::CategorizeItem::COMMANDS.size
    end
    #--------------------------------------------------------------------------
    # ○ コマンドリストの作成
    #--------------------------------------------------------------------------
    def make_command_list
      CAO::CategorizeItem::COMMANDS.each do |symbol|
        add_command(CAO::CategorizeItem::VOCAB_COMMANDS[symbol], symbol)
      end
    end
    #--------------------------------------------------------------------------
    # ○ 項目の描画
    #--------------------------------------------------------------------------
    def draw_item(index)
      rect = item_rect_for_text(index)
      param = command_name(index)
      if param.is_a?(Array) && param[1].is_a?(String)
        ww = (rect.width - self.contents.text_size(param[1]).width - 24)
        ww =  [0, ww - (self.contents.font.outline ? 3 : 1)].max
        rect.x += ww / 2
        draw_icon(param[0], rect.x, rect.y)
        rect.x += 24
        rect.width -= ww + 24
        change_color(normal_color)
        draw_text(rect, param[1])
      elsif param.is_a?(String)
        change_color(normal_color)
        draw_text(rect, param, alignment)
      else
        rect.x += (rect.width - 24) / 2
        if param.is_a?(Array)
          icon_index = param[(param[1] && @index == index) ? 1 : 0]
        else
          icon_index = param
        end
        draw_icon(icon_index, rect.x, rect.y)
      end
    end
    #--------------------------------------------------------------------------
    # ○ カーソル位置の設定
    #--------------------------------------------------------------------------
    def index=(index)
      last_index = @index
      super
      refresh if @index != last_index
    end
    #--------------------------------------------------------------------------
    # ○ カーソルの更新
    #--------------------------------------------------------------------------
    def update_cursor
      super
      self.cursor_rect.empty unless CAO::CategorizeItem::VISIBLE_CURSOR
    end
  end

  class Window_ItemList
    #--------------------------------------------------------------------------
    # ● 正規表現
    #--------------------------------------------------------------------------
    REGEXP_ETYPE = /etype(\d+)/
    REGEXP_WTYPE = /wtype(\d+)/
    REGEXP_ATYPE = /atype(\d+)/
    #--------------------------------------------------------------------------
    # ○ アイテムをリストに含めるかどうか
    #--------------------------------------------------------------------------
    def include?(item)
      return item != nil if @category == :all
      return false unless include_keyword?(item) unless @category.is_a?(String)
      case @category
      when String
        prefix = CAO::CategorizeItem::KEYWORD_PREFIX
        suffix = CAO::CategorizeItem::KEYWORD_SUFFIX
        return item && item.note.include?("#{prefix}#{@category}#{suffix}")
      when :all
        return item != nil
      when :all_item
        return item.is_a?(RPG::Item)
      when :item
        return item.is_a?(RPG::Item) && !item.key_item?
      when :equip
        return item.is_a?(RPG::EquipItem)
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
    # ● アイテムにキーワードアイテムを含めるか
    #--------------------------------------------------------------------------
    def include_keyword?(item)
      return true  if CAO::CategorizeItem::INCLUDE_KEYWORD
      return !(item && keyword_item?(item))
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def keyword_item?(item)
      return CAO::CategorizeItem::KEYWORDS.any? {|k| item.note.include?(k) }
    end
  end
