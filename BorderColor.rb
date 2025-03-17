#******************************************************************************
#
#    ＊ 文字色変更縁色化
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.0.0
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#   ： 縁取りを太くし、文字色の変更で縁取りの色を変更するようにします。
#
#  --------------------------------------------------------------------------
#   == 注意事項 ==
#
#    ※ 組み込みクラス Bitmap#draw_text を再定義しています。
#
#
#******************************************************************************

#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
  module Border

    #--------------------------------------------------------------------------
    # ◇ フォントの色を設定
    #--------------------------------------------------------------------------
    FONT_COLOR = [255, 255, 255]

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
      if self.font.outline
        __draw_border_text(*__check_arg_draw_text(args))
      else
        _cao_border_draw_text(*__check_arg_draw_text(args))
      end
    end
  private
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

      original_font = self.font
      self.font = original_font.dup
      self.font.shadow = false
      self.font.out_color.set(0, 0, 0, 0)

      canvas = Bitmap.new(width + 8, height + 8)
      canvas.font = original_font.dup
      canvas.font.shadow = false
      canvas.font.color.set(*CAO::Border::FONT_COLOR, 255)

      border = Bitmap.new(width + 8, height + 8)
      border.font = original_font.dup
      c1 = border.font.color
      c2 = CAO::Border::FONT_COLOR
      if c1.red == c2[0] && c1.green == c2[1] && c1.blue == c2[2]
        border.font.color.set(255 - c2[0], 255 - c2[1], 255 - c2[2])
      end
      border.font.color.alpha = 255
      border.font.out_color.alpha = 0
      border.font.shadow = false
      border._cao_border_draw_text(4, 4, width, height, text, align)

      xx = CAO::Border::POSITION[0]
      yy = CAO::Border::POSITION[1]
      canvas.blt(xx,     yy - 2, border, border.rect)
      canvas.blt(xx,     yy + 2, border, border.rect)
      canvas.blt(xx - 2, yy,     border, border.rect)
      canvas.blt(xx + 2, yy,     border, border.rect)
      canvas.blt(xx - 1, yy - 2, border, border.rect)
      canvas.blt(xx + 1, yy - 2, border, border.rect)
      canvas.blt(xx - 1, yy + 2, border, border.rect)
      canvas.blt(xx + 1, yy + 2, border, border.rect)
      canvas.blt(xx - 2, yy - 1, border, border.rect)
      canvas.blt(xx - 2, yy + 1, border, border.rect)
      canvas.blt(xx + 2, yy - 1, border, border.rect)
      canvas.blt(xx + 2, yy + 1, border, border.rect)
      canvas._cao_border_draw_text(xx + 4, yy + 4, width, height, text, align)

      self.blt(x - 4, y - 4, canvas, canvas.rect, original_font.color.alpha)

      self.font = original_font

      border.dispose
      canvas.dispose
    end
  end
