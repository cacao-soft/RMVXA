#******************************************************************************
#
#    ＊ 画像保存
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.0.4
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#    ： Bitmap オブジェクトを画像ファイルで保存する機能を追加します。
#
#  --------------------------------------------------------------------------
#   == 使用方法 ==
#
#    ★ Bitmap#save(filename, type, back = nil)
#     ビットマップオブジェクトを保存する
#
#    ★ Graphics.save_screen(filename, type)
#     ゲーム画面を保存する
#
#     filename : 保存ファイル名
#     type     : 保存形式 (:BMP, :PNG, :JPG, :GIF)
#     back     : 背景色 (Color.new(0,0,0), [0,0,0], :white)
#
#    ※ ファイル名の拡張子が省略された場合は、自動で追加します。
#
#
#******************************************************************************


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                  このスクリプトに設定項目はありません。                     #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module GDIP
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  CLSID_BMP     = '557CF400-1A04-11D3-9A73-0000F81EF32E'
  CLSID_JPEG    = '557CF401-1A04-11D3-9A73-0000F81EF32E'
  CLSID_GIF     = '557CF402-1A04-11D3-9A73-0000F81EF32E'
  CLSID_TIFF    = '557CF405-1A04-11D3-9A73-0000F81EF32E'
  CLSID_PNG     = '557CF406-1A04-11D3-9A73-0000F81EF32E'

  CLSID_QUALITY = '1D5BE4B5-FA4A-452D-9CDD-5DB35105E7EB'

  CP_ACP   = 0x0000
  CP_UTF8  = 0xFDE9

  #--------------------------------------------------------------------------
  # ● Win32API
  #--------------------------------------------------------------------------
  @@MultiByteToWideChar =
    Win32API.new('kernel32', 'MultiByteToWideChar', 'iipipi', 'i')

  @@FindWindow =
    Win32API.new('user32', 'FindWindow', 'pp', 'l')
  @@GetDC =
    Win32API.new('user32', 'GetDC', 'i', 'i')
  @@ReleaseDC =
    Win32API.new('user32', 'ReleaseDC', 'ii', 'i')

  @@BitBlt =
    Win32API.new('gdi32', 'BitBlt', 'iiiiiiiii', 'i')
  @@CreateCompatibleDC =
    Win32API.new('gdi32', 'CreateCompatibleDC', 'i', 'i')
  @@CreateCompatibleBitmap =
    Win32API.new('gdi32', 'CreateCompatibleBitmap', 'iii', 'i')
  @@SelectObject =
    Win32API.new('gdi32', 'SelectObject', 'ii', 'i')
  @@DeleteDC =
    Win32API.new('gdi32', 'DeleteDC', 'i', 'i')
  @@DeleteObject =
    Win32API.new('gdi32', 'DeleteObject', 'i', 'i')
  @@StretchDIBits =
    Win32API.new('gdi32', 'StretchDIBits', 'iiiiiiiiippii', 'i')

  @@GdiplusStartup =
    Win32API.new('gdiplus', 'GdiplusStartup', 'ppi', 'i')
  @@GdipCreateBitmapFromScan0 =
    Win32API.new('gdiplus', 'GdipCreateBitmapFromScan0', 'iiiipp', 'i')
  @@GdipCreateBitmapFromHBITMAP =
    Win32API.new('gdiplus', 'GdipCreateBitmapFromHBITMAP', 'iip', 'i')
  @@GdipBitmapConvertFormat =
    Win32API.new('gdiplus', 'GdipBitmapConvertFormat', 'piiipi', 'i') rescue nil
  @@GdipSaveImageToFile =
    Win32API.new('gdiplus', 'GdipSaveImageToFile', 'ippp', 'i')
  @@GdipDisposeImage =
    Win32API.new('gdiplus', 'GdipDisposeImage', 'i', 'i')
  @@GdiplusShutdown =
    Win32API.new('gdiplus', 'GdiplusShutdown', 'p', 'v')

  @@UuidFromString =
    Win32API.new('rpcrt4', 'UuidFromString', 'pp', 'i')

  @@GdipBitmapLockBits =
    Win32API.new('gdiplus', 'GdipBitmapLockBits', 'ipiip', 'i')
  @@GdipBitmapUnlockBits =
    Win32API.new('gdiplus', 'GdipBitmapUnlockBits', 'ip', 'i')

  @@RtlMoveMemory =
    Win32API.new('kernel32', 'RtlMoveMemory', 'pii', 'v')
  @@RtlMoveMemoryI =
    Win32API.new('kernel32', 'RtlMoveMemory', 'ipi', 'v')

  PF_RGB  = 0x00021808
  PF_ARGB = 0x0026200A

  #--------------------------------------------------------------------------
  # ● ウィンドウの情報
  #--------------------------------------------------------------------------
  GAME_TITLE  = load_data("Data/System.rvdata2").game_title.encode('SHIFT_JIS')
  GAME_HANDLE = @@FindWindow.call("RGSS Player", GAME_TITLE)

module_function
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def MultiByteToWideChar(str)
    buffer = [""].pack('Z256')
    @@MultiByteToWideChar.call(CP_UTF8, 0, str, -1, buffer, buffer.size)
    return buffer
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def GetDC(hwnd)
    return @@GetDC.call(hwnd)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def ReleaseDC(hwnd, hdc)
    @@ReleaseDC.call(hwnd, hdc)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def CopyDC(dest, src, width, height)
    @@BitBlt.call(dest, 0, 0, width, height, src, 0, 0, 0xCC0020)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def CreateCompatibleDC(hdc)
    return @@CreateCompatibleDC.call(hdc)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def CreateCompatibleBitmap(hdc, width, height)
    return @@CreateCompatibleBitmap.call(hdc, width, height)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def SelectObject(hdc, obj)
    return @@SelectObject.call(hdc, obj) != 0
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def DeleteDC(hdc)
    @@DeleteObject.call(hdc)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def DeleteObject(obj)
    @@DeleteObject.call(obj)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def GdiplusStartup(token)
    ret = @@GdiplusStartup.call(token, [1, 0, 0, 0].pack("i4"), 0) == 0
    unless ret
      msgbox "GDI+ の初期化に失敗しました。"
    end
    return ret
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def GdipCreateImageFromBitmap(bitmap)
    GC.start
    buffer = Bitmap.new(bitmap.width, bitmap.height)
    rect = Rect.new(0, 0, bitmap.width, 1)
    (bitmap.height/2).times do |i|
      rect.y = bitmap.height - 1 - i
      buffer.blt(0, i, bitmap, rect)
      rect.y = i
      buffer.blt(0, bitmap.height - 1 - i, bitmap, rect)
    end
    bitmap = buffer

    gpbmp = [0].pack("i")
    if @@GdipCreateBitmapFromScan0.call(
      bitmap.width, bitmap.height, 0, PF_ARGB, 0, gpbmp) == 0

      image = gpbmp.unpack("i")[0]
      r = [0, 0, bitmap.width, bitmap.height].pack("i4")
      bd = [0, 0, 0, 0, 0, 0].pack("i6")
      @@GdipBitmapLockBits.call(image, r, 3, PF_ARGB, bd)
      @@GdipBitmapUnlockBits.call(image, bd)
      bd = bd.unpack("i6")
      line_size = (bitmap.width * 32 + 31) / 32 * 4
      data = "\0".force_encoding('ASCII-8BIT') * (line_size * bitmap.height)
      @@RtlMoveMemory.call(data, bitmap.data, data.size)

      info = [
        40, bitmap.width, bitmap.height, (32 & 0xFFFF) | (1 << 16),
        0,0,0,0,0,0
      ].pack("i10")
      wnddc = GetDC(GAME_HANDLE)
      @@StretchDIBits.call(
        wnddc,
        0,bitmap.height,bitmap.width,-bitmap.height,
        0,0,bitmap.width,bitmap.height,
        info, data, 0, 0xCC0020)
      @@BitBlt.call(
        wnddc, 0, bitmap.width, bitmap.width, -bitmap.height,
        wnddc, 0, 0, 0xCC0020)
      ReleaseDC(GAME_HANDLE, wnddc)

      @@RtlMoveMemoryI.call(bd[4], data, line_size * bitmap.height)

      bitmap.dispose
      return image
    else
      return nil
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def GdipCreateImageFromHBITMAP(hbm)
    gpbmp = [0].pack("i")
    if @@GdipCreateBitmapFromHBITMAP.call(hbm, 0, gpbmp) == 0
      return gpbmp.unpack("i")[0]
    else
      return nil
    end
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def GdipSaveImageToFile(image, filename, clsid)
    ret = @@GdipSaveImageToFile.call(image, filename, UuidFromString(clsid), 0)
    msgbox "保存に失敗しました。" if ret != 0
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def GdipImageConvertPixelFormat(image, pixel_format)
    return unless @@GdipBitmapConvertFormat
    @@GdipBitmapConvertFormat.call(image, pixel_format, 0, 0, 0, 0)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def GdipDisposeImage(image)
    @@GdipDisposeImage.call(image)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def GdiplusShutdown(token)
    @@GdiplusShutdown.call(token)
  end
  #--------------------------------------------------------------------------
  # ●
  #--------------------------------------------------------------------------
  def UuidFromString(clsid)
    uuid = [0].pack("i")
    @@UuidFromString.call(clsid, uuid)
    return uuid
  end
end

class Bitmap
  #--------------------------------------------------------------------------
  # ● メモリ転送用の関数
  #--------------------------------------------------------------------------
  RtlMoveMemory_pi = Win32API.new('kernel32', 'RtlMoveMemory', 'pii', 'i')
  RtlMoveMemory_ip = Win32API.new('kernel32', 'RtlMoveMemory', 'ipi', 'i')
  #--------------------------------------------------------------------------
  # ● BITMAPINFOHEADER
  #--------------------------------------------------------------------------
  def info
    dib = [40, self.width, self.height, 1, 32, 0, 0, 0, 0, 0, 0].pack("i3s2i6")
    return [dib].pack("P").unpack("i")[0]
  end
  #--------------------------------------------------------------------------
  # ● BITMAPDATA (RPGTKOOLXP/RGSS Wiki 参考)
  #--------------------------------------------------------------------------
  def data
    buffer = [0].pack('L')
    RtlMoveMemory_pi.call(buffer, object_id * 2 + 16, 4)
    RtlMoveMemory_pi.call(buffer, buffer.unpack("L")[0] + 8, 4)
    RtlMoveMemory_pi.call(buffer, buffer.unpack("L")[0] + 16, 4)
    return buffer.unpack("L")[0]
  end
  #--------------------------------------------------------------------------
  # ● 画像で保存する
  #--------------------------------------------------------------------------
  def save(fn, type, back = nil)
    bitmap = Bitmap.new(self.width, self.height)
    case back
    when Color;       bitmap.fill_rect(self.rect, back)
    when Array;       bitmap.fill_rect(self.rect, Color.new(*back))
    when /^white$/i;  bitmap.fill_rect(self.rect, Color.new(255, 255, 255))
    end
    bitmap.blt(0, 0, self, self.rect)

    case type
    when /^BMP$/i;    clsid, ext = GDIP::CLSID_BMP,   ".bmp"
    when /^PNG$/i;    clsid, ext = GDIP::CLSID_PNG,   ".png"
    when /^JPE?G$/i;  clsid, ext = GDIP::CLSID_JPEG,  ".jpg"
    when /^GIF$/i;    clsid, ext = GDIP::CLSID_GIF,   ".gif"
    else;             raise ""
    end
    fn += ext if File.extname(fn).empty?
    filename = GDIP::MultiByteToWideChar(fn)

    token = [0].pack("i")
    if GDIP::GdiplusStartup(token)
      image = GDIP::GdipCreateImageFromBitmap(bitmap)
      if image
        GDIP::GdipSaveImageToFile(image, filename, clsid)
        GDIP::GdipDisposeImage(image)
      end
      GDIP::GdiplusShutdown(token)
    end

    bitmap.dispose
    GC.start
  end
  #--------------------------------------------------------------------------
  # ● PNG 画像で保存する
  #--------------------------------------------------------------------------
  def save_png(filename, alpha = false)
    save(filename, :PNG, alpha ? nil : :white)
  end
end

module Graphics
  #--------------------------------------------------------------------------
  # ● ゲーム画面を画像で保存する
  #--------------------------------------------------------------------------
  def self.save_screen(fn, type)
    case type
    when /^BMP$/i;    clsid, ext = GDIP::CLSID_BMP,   ".bmp"
    when /^PNG$/i;    clsid, ext = GDIP::CLSID_PNG,   ".png"
    when /^JPE?G$/i;  clsid, ext = GDIP::CLSID_JPEG,  ".jpg"
    when /^GIF$/i;    clsid, ext = GDIP::CLSID_GIF,   ".gif"
    else;             raise ""
    end
    fn += ext if File.extname(fn).empty?
    filename = GDIP::MultiByteToWideChar(fn)

    wnddc = GDIP::GetDC(GDIP::GAME_HANDLE)
    memdc = GDIP::CreateCompatibleDC(wnddc)
    hbm = GDIP::CreateCompatibleBitmap(wnddc, Graphics.width, Graphics.height)
    if GDIP::SelectObject(memdc, hbm)
      GDIP::CopyDC(memdc, wnddc, Graphics.width, Graphics.height)
      token = [0].pack("i")
      if GDIP::GdiplusStartup(token)
        image = GDIP::GdipCreateImageFromHBITMAP(hbm)
        GDIP::GdipImageConvertPixelFormat(image, GDIP::PF_ARGB)
        if image
          GDIP::GdipSaveImageToFile(image, filename, clsid)
          GDIP::GdipDisposeImage(image)
        end
        GDIP::GdiplusShutdown(token)
      end
    end
    GDIP::ReleaseDC(GDIP::GAME_HANDLE, wnddc)
    GDIP::DeleteDC(memdc)
    GDIP::DeleteObject(hbm)
  end
end
