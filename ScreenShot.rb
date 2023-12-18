#******************************************************************************
#
#    ＊ スクリーンショット
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.1.0
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ：  https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#    ： 現在のゲーム画面を画像保存します。
#
#  --------------------------------------------------------------------------
#   == 注意事項 ==
#
#    ※ このスクリプトの実行には、『PNG 保存』のスクリプトが必要です。
#    ※ 画像の保存中は、ゲームが停止します。
#
#  --------------------------------------------------------------------------
#   == 使用方法 ==
#
#    ★ 撮影する
#     PrintScreen(PrtScn) キー を押してください。
#     押すボタンは設定から変更可能です。
#
#
#******************************************************************************


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
module SS
  #--------------------------------------------------------------------------
  # ◇ 保存名
  #--------------------------------------------------------------------------
  SAVE_NAME = "ScreenShot/%Y%m%d%H%M%S.png"
  #--------------------------------------------------------------------------
  # ◇ ロゴ追加
  #--------------------------------------------------------------------------
  FILE_LOGO = ""
  #--------------------------------------------------------------------------
  # ◇ 撮影時の効果音
  #--------------------------------------------------------------------------
  FILE_SOUND = RPG::SE.new("Key", 100, 150)
  #--------------------------------------------------------------------------
  # ◇ 撮影ボタン (nil(PrtScr), :F5 :F6 :F7 :F8 :F9(Debug))
  #--------------------------------------------------------------------------
  KEY = nil
end # module SS
end # module CAO


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module CAO::SS
  #--------------------------------------------------------------------------
  # ● Win32API
  #--------------------------------------------------------------------------
  GetAsyncKeyState = Win32API.new('user32', 'GetAsyncKeyState', 'i', 'i')
  #--------------------------------------------------------------------------
  # ● スクリーンショットボタン
  #--------------------------------------------------------------------------
  def self.trigger_snapshot?
    if KEY
      Input.trigger?(KEY)
    else
      GetAsyncKeyState.call(0x2C) & 1 == 1
    end
  end
  #--------------------------------------------------------------------------
  # ● 保存先フォルダの作成
  #--------------------------------------------------------------------------
  def self.mkdir(path)
    return if FileTest.directory?(path)
    parent = path.split(/[\\\/]/)[0..-2].join('/')
    self.mkdir(parent) unless parent.empty? || FileTest.directory?(parent)
    Dir.mkdir(path)
  end
end

class << Graphics
  #--------------------------------------------------------------------------
  # ● フレーム更新
  #--------------------------------------------------------------------------
  alias _cao_ss_update update
  def update
    _cao_ss_update
    if CAO::SS.trigger_snapshot?
      CAO::SS::FILE_SOUND.play if CAO::SS::FILE_SOUND
      save_screen_shot
    end
  end
  #--------------------------------------------------------------------------
  # ● スクリーンショットの保存
  #--------------------------------------------------------------------------
  def save_screen_shot
    filename = Time.now.strftime(CAO::SS::SAVE_NAME)
    CAO::SS.mkdir(File.dirname(filename))
    bitmap = Graphics.snap_to_bitmap
    unless CAO::SS::FILE_LOGO.empty?
      logo = Cache.system(CAO::SS::FILE_LOGO)
      bitmap.blt(0, 0, logo, logo.rect)
    end
    bitmap.save_png(filename)
    bitmap.dispose
  end
end
