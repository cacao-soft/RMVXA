#******************************************************************************
#
#    ＊ 太縁取り
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.1.1
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
    #     自動で変更する場合は、文字色より暗い色になります。
    #--------------------------------------------------------------------------
    SW_AUTO_COLOR = 0

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
        last_shadow = self.font.shadow
        self.font.shadow = false
        __draw_border_text(*__check_arg_draw_text(args))
        self.font.shadow = last_shadow
      else
        update_outcolor
        _cao_border_draw_text(*__check_arg_draw_text(args))
      end
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def update_outcolor
      if __auto_outcolor?
        self.font.out_color.red   = self.font.color.red   / 3
        self.font.out_color.green = self.font.color.green / 3
        self.font.out_color.blue  = self.font.color.blue  / 3
      end
      if CAO::Border::OUTLINE_ALPHA != 0
        self.font.out_color.alpha = CAO::Border::OUTLINE_ALPHA
      end
    end

  private
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def __bold_border?
      return false unless self.font.outline
      return true if CAO::Border::SW_BOLD_BORDER == 0
      return $game_switches[CAO::Border::SW_BOLD_BORDER]
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def __auto_outcolor?
      return false unless self.font.outline
      return true if CAO::Border::SW_AUTO_COLOR == 0
      return $game_switches[CAO::Border::SW_AUTO_COLOR]
    end
    #--------------------------------------------------------------------------
    # ●
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

      border = Bitmap.new(width, height)
      border.font = self.font.dup
      if __auto_outcolor?
        border.font.color.red /= 3
        border.font.color.green /= 3
        border.font.color.blue /= 3
      else
        border.font.color = border.font.out_color
      end
      border.font.out_color.set(0, 0, 0, 0)
      border._cao_border_draw_text(0, 0, width, height, text, align)

      x += CAO::Border::POSITION[0]
      y += CAO::Border::POSITION[1]
      if CAO::Border::OUTLINE_ALPHA == 0
        alpha = Font.default_out_color.alpha
      else
        alpha = CAO::Border::OUTLINE_ALPHA
      end
      self.blt(x, y - 2, border, border.rect, alpha)
      self.blt(x, y + 2, border, border.rect, alpha)
      self.blt(x - 2, y, border, border.rect, alpha)
      self.blt(x + 2, y, border, border.rect, alpha)
      self.blt(x - 1, y - 2, border, border.rect, alpha)
      self.blt(x + 1, y - 2, border, border.rect, alpha)
      self.blt(x - 1, y + 2, border, border.rect, alpha)
      self.blt(x + 1, y + 2, border, border.rect, alpha)
      self.blt(x - 2, y - 1, border, border.rect, alpha)
      self.blt(x - 2, y + 1, border, border.rect, alpha)
      self.blt(x + 2, y - 1, border, border.rect, alpha)
      self.blt(x + 2, y + 1, border, border.rect, alpha)

      last_out_color = self.font.out_color.dup
      self.font.out_color.set(0, 0, 0, 0)
      _cao_border_draw_text(x, y, width, height, text, align)
      self.font.out_color = last_out_color

      border.dispose
    end
  end
