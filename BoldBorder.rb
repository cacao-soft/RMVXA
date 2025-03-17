#******************************************************************************
#
#    ＊ 太縁取り
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.2.0
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#   ： デフォルトより太い縁取りを行います。
#
#  --------------------------------------------------------------------------
#   == 注意事項 ==
#
#    ※ 組み込みクラス Bitmap#draw_text を再定義しています。
#    ※ 文字の描画に、通常の倍ほどの時間が掛かります。
#
#
#******************************************************************************

#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
  module Border

    #--------------------------------------------------------------------------
    # ◇ 太縁取り機能の有無を切り替えるスイッチの番号
    #--------------------------------------------------------------------------
    #     切り替えない場合は、0 としてください。常に ON となります。
    #--------------------------------------------------------------------------
    SW_BOLD_BORDER = 0

    #--------------------------------------------------------------------------
    # ◇ 縁取り色の自動変更機能の有無を切り替えるスイッチの番号
    #--------------------------------------------------------------------------
    #     切り替えない場合は、0 としてください。常に ON となります。
    #     ON の場合は、文字色より暗い色になります。
    #--------------------------------------------------------------------------
    SW_AUTO_COLOR = 0

    #--------------------------------------------------------------------------
    # ◇ 縁取りをさらに太くする
    #--------------------------------------------------------------------------
    OUTLINE_DOUBLE = false

    #--------------------------------------------------------------------------
    # ◇ 縁取りの色の濃さ (0-255)
    #--------------------------------------------------------------------------
    #     0 にすると、元の値を使用し変更しません。
    #--------------------------------------------------------------------------
    OUTLINE_ALPHA = 255

    #--------------------------------------------------------------------------
    # ◇ 位置補正
    #--------------------------------------------------------------------------
    #     [x, y] の配列で設定します。
    #     設定された値だけ描画位置をずらします。
    #     ※ 縁取りを無効にしている場合は適用されません。
    #--------------------------------------------------------------------------
    POSITION = [0, 0]

  end # module Border
  end # module CAO


  #/////////////////////////////////////////////////////////////////////////////#
  #                                                                             #
  #                下記のスクリプトを変更する必要はありません。                 #
  #                                                                             #
  #/////////////////////////////////////////////////////////////////////////////#


  class Font
    #--------------------------------------------------------------------------
    # ● 別名定義
    #--------------------------------------------------------------------------
    alias _cao_border_color color= unless $!
    #--------------------------------------------------------------------------
    # 〇 フォントの色を設定
    #--------------------------------------------------------------------------
    def color=(c)
      _cao_border_color(c)
      if __auto_outcolor?
        self.out_color.red   = self.color.red   / 3
        self.out_color.green = self.color.green / 3
        self.out_color.blue  = self.color.blue  / 3
      end
      if CAO::Border::OUTLINE_ALPHA != 0
        self.out_color.alpha = CAO::Border::OUTLINE_ALPHA
      end
    end
  private
    #--------------------------------------------------------------------------
    # ● 縁取り色を自動変更するか
    #--------------------------------------------------------------------------
    def __auto_outcolor?
      return false unless self.outline
      return true if CAO::Border::SW_AUTO_COLOR == 0
      return $game_switches[CAO::Border::SW_AUTO_COLOR]
    end
  end

  class Bitmap
    #--------------------------------------------------------------------------
    # ● 別名定義
    #--------------------------------------------------------------------------
    alias _cao_border_draw_text draw_text unless $!
    #--------------------------------------------------------------------------
    # 〇 新 draw_text
    #--------------------------------------------------------------------------
    def draw_text(*args)
      if __bold_border?
        __draw_border_text(*__check_arg_draw_text(args))
      else
        _cao_border_draw_text(*__check_arg_draw_text(args))
      end
    end
  private
    #--------------------------------------------------------------------------
    # ● 縁取りを行うか
    #--------------------------------------------------------------------------
    def __bold_border?
      return false unless self.font.outline
      return true if CAO::Border::SW_BOLD_BORDER == 0
      return $game_switches[CAO::Border::SW_BOLD_BORDER]
    end
    #--------------------------------------------------------------------------
    # ● draw_text の引数が正しいかチェック
    #--------------------------------------------------------------------------
    def __check_arg_draw_text(args)
      case args.size
      when 2, 3
        if args[0].kind_of?(Rect)
          r, text, align = args[0], args[1], args[2] || 0
          x, y, width, height = r.x, r.y, r.width, r.height
        else
          msg = "cannot convert #{args[0].class} into Rect"
          raise TypeError, msg, caller(2)
        end
      when 5, 6
        x, y, width, height, text, align = args
        align ||= 0
      else
        msg = "wrong number of argsuments (#{args.size} for 5)"
        raise ArgumentError, msg, caller(2)
      end

      [x, y, width, height, align].each do |value|
        next if value.kind_of?(Numeric)
        msg = "cannot convert #{value.class} into Integer"
        raise TypeError, msg, caller(5)
      end

      unless text.kind_of?(String)
        text = (text.respond_to?(:to_s) ? text.to_s : text.inspect)
      end

      return x, y, width, height, text, align
    end
    #--------------------------------------------------------------------------
    # ● 縁取り文字の描画
    #--------------------------------------------------------------------------
    def __draw_border_text(x, y, width, height, text, align)
      return if width <= 0 || height <= 0

      last_shadow = self.font.shadow
      self.font.shadow = false

      border = Bitmap.new(width, height)
      border.font = self.font.dup
      border.font.color = border.font.out_color
      border.font.outline = CAO::Border::OUTLINE_DOUBLE
      border.font.out_color.set(border.font.color)
      border._cao_border_draw_text(0, 0, width, height, text, align)

      x += CAO::Border::POSITION[0]
      y += CAO::Border::POSITION[1]
      alpha = border.font.color.alpha
      self.blt(x,     y - 2, border, border.rect, alpha)
      self.blt(x,     y + 2, border, border.rect, alpha)
      self.blt(x - 2, y,     border, border.rect, alpha)
      self.blt(x + 2, y,     border, border.rect, alpha)
      self.blt(x - 1, y - 2, border, border.rect, alpha)
      self.blt(x + 1, y - 2, border, border.rect, alpha)
      self.blt(x - 1, y + 2, border, border.rect, alpha)
      self.blt(x + 1, y + 2, border, border.rect, alpha)
      self.blt(x - 2, y - 1, border, border.rect, alpha)
      self.blt(x - 2, y + 1, border, border.rect, alpha)
      self.blt(x + 2, y - 1, border, border.rect, alpha)
      self.blt(x + 2, y + 1, border, border.rect, alpha)

      last_font = self.font.dup
      self.font.outline = CAO::Border::OUTLINE_DOUBLE
      self.font.out_color.set(0, 0, 0, 0)
      _cao_border_draw_text(x, y, width, height, text, align)
      self.font = last_font

      border.dispose

      self.font.shadow = last_shadow
    end
  end
