#******************************************************************************
#
#    ＊ 初期化ファイルの操作
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.0.1
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#    ： ini ファイルに設定された値を取得・設定する機能を追加します。
#
#  --------------------------------------------------------------------------
#   == 使用方法 ==
#
#    ★ IniFile.read(filename, section, key, default)
#     ファイル、セクション、キーを指定して、設定されている値を取得します。
#       filename : 読み込む ini ファイル名
#       section  : セクション名
#       key      : キー名
#       default  : 値が存在しない場合のデフォルト値 (省略時："")
#
#    ★ IniFile.write(filename, section, key, string)
#     ファイル、セクション、キーを指定して、値を書き込みます。
#       filename : 書き込む ini ファイル名
#       section  : セクション名
#       key      : キー名
#       string   : 設定する値 (数値の場合は、文字列に変換します。)
#
#
#    ★ IniFile.new(filename)
#     空の初期化ファイルのオブジェクトを作成します。
#       filename : ini ファイル名
#
#    ★ IniFile#load
#     初期化ファイルの読み込みを行います。
#     読み込みに成功すると取得した内容をハッシュで返します。
#     失敗した場合は、nil を返します。
#
#    ★ IniFile#save
#     初期化ファイルに現在の設定を書き込みます。
#     ファイルの文字コードは Shift-JIS 形式で作成されます。
#
#    ★ IniFile#[セクション名][キー名]
#     現在の設定への参照です。
#     代入を行えば設定されている値を変更できます。
#     変更した値をファイルに保存するには、IniFile#save を使用します。
#
#
#    ※ INI ファイルの文字コードは Shift_JIS のみ対応しています。
#    ※ セクション名とキー名は、必ず文字列で指定してください。
#    ※ 読み込まれた値は、自動で数値に変換されます。
#       0123  : 先頭が 0 の値は、8進数として読み込まれます。
#       0x123 : 先頭が 0x の値は、16進数として読み込まれます。
#       1234  : 数字は数値として読み込まれます。
#       0.123 : 数字の間に . が１つある値は、小数(Float)として読み込まれます。
#    ※ ファイル名は、自動で絶対パスに変換されます。
#       拡張子が付いていない場合は、.ini が追加されます。
#    ※ クラスメソッドでは、大文字・小文字を区別しませんが、
#       インスタンスメソッドでは、区別されます。
#
#
#******************************************************************************


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                  このスクリプトに設定項目はありません。                     #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


# Win32API の読み込み
class IniFile
  # INI ファイルの内容を数値で取得
  GetPrivateProfileInt =
    Win32API.new('kernel32','GetPrivateProfileIntA','ppip','i')
  # INI ファイルの内容を文字列で取得
  GetPrivateProfileString =
    Win32API.new('kernel32','GetPrivateProfileStringA','pppplp','l')
  # セクション内のキーと値を取得
  GetPrivateProfileSection =
    Win32API.new('kernel32','GetPrivateProfileSectionA','pplp','l')
  # 全セクション名の取得
  GetPrivateProfileSectionNames =
    Win32API.new('kernel32','GetPrivateProfileSectionNamesA','plp','l')

  # INI ファイルの内容の書き込み
  WritePrivateProfileString =
    Win32API.new('kernel32','WritePrivateProfileStringA','pppp','i')
  # セクションの書き込み
  WritePrivateProfileSection =
    Win32API.new('kernel32','WritePrivateProfileSectionA','ppp','i')
end

class Encoding
  "".encode("Shift_JIS")
  BINARY = Encoding.find("ASCII-8BIT")
  SJIS   = Encoding.find("Shift_JIS")
  UTF8   = Encoding.find("UTF-8")
end

# クラスメソッドの定義
class IniFile
  #--------------------------------------------------------------------------
  # ● ファイル名から絶対パスを取得
  #--------------------------------------------------------------------------
  def self.expand_path(filename)
    filename = [filename.encode('Shift_JIS')].pack('a260').delete("\0")
    filename += ".ini" if File.extname(filename).empty?
    return File.expand_path(filename).encode('UTF-8', 'Shift_JIS')
  end
  #--------------------------------------------------------------------------
  # ● 文字コードを変換
  #--------------------------------------------------------------------------
  def self.kconv(kcode, *strings)
    case kcode
    when :SJIS
      strings.map! {|str| str.encode('Shift_JIS', 'UTF-8') }
    when :UTF8
      strings.map! {|str| str.encode('UTF-8', 'Shift_JIS') }
    else
      raise "kcode is :SJIS or :UTF8"
    end
    return strings[0] if strings.size == 1
    return strings
  end
  #--------------------------------------------------------------------------
  # ● 数値に変換
  #--------------------------------------------------------------------------
  def self.vconv(value)
    return value.oct  if /^0\d+$/     === value   #  8進数
    return value.hex  if /^0x\d+$/    === value   # 16進数
    return value.to_i if /^\d+$/      === value   # 10進数
    return value.to_f if /^\d+\.\d+$/ === value   # 小数
    return value                                  # 文字
  end
  #--------------------------------------------------------------------------
  # ● INIファイルの内容を読み込む
  #--------------------------------------------------------------------------
  def self.read(filename, section, key, default = "")
    section, key, default, filename =
      IniFile.kconv(:SJIS, section, key, default.to_s, expand_path(filename))
    buf = [""].pack('a256')
    GetPrivateProfileString.call(
      section, key, default, buf, buf.size, filename)
    return vconv(IniFile.kconv(:UTF8, buf.gsub(/\0+$/, "")))
  end
  #--------------------------------------------------------------------------
  # ● INIファイルの内容を書き込む
  #--------------------------------------------------------------------------
  def self.write(filename, section, key, value)
    section, key, value, filename =
      IniFile.kconv(:SJIS, section, key, value.to_s, expand_path(filename))
    return WritePrivateProfileString.call(section, key, value, filename) != 0
  end
end

# インスタンスメソッドの定義
class IniFile
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_reader   :filename               # ファイル名
  attr_reader   :filepath               # ファイルパス
  attr_reader   :data                   # データ ({ section: { key: data }})
  #--------------------------------------------------------------------------
  # ● オブジェクトの初期化
  #--------------------------------------------------------------------------
  def initialize(filename)
    @filename = File.basename(filename, ".*")
    @filepath = IniFile.expand_path(@filename)
    @data = {}
  end
  #--------------------------------------------------------------------------
  # ● クリア
  #--------------------------------------------------------------------------
  def clear
    @data.clear
  end
  #--------------------------------------------------------------------------
  # ● 全内容を読み込む
  #--------------------------------------------------------------------------
  def load
    filepath = IniFile.kconv(:SJIS, @filepath)
    buf = [""].pack('a32768')
    sz = GetPrivateProfileSectionNames.call(buf, buf.size, filepath)
    return nil if sz == 0

    sections = IniFile.kconv(:UTF8, buf.gsub(/\0+$/, "")).split("\0")
    sections.each do |section|
      @data[section] ||= {}
      buf = [""].pack('a32768')
      GetPrivateProfileSection.call(section, buf, buf.size, filepath)
      data = IniFile.kconv(:UTF8, buf.gsub(/\0+$/, "")).split("\0")
      data.each do |str|
        key, value = *str.split("=")
        @data[section][key] = IniFile.vconv(value)
      end
    end
    return self
  end
  #--------------------------------------------------------------------------
  # ● 現在の設定を書き込む
  #--------------------------------------------------------------------------
  def save
    @data.each do |section,data|
      data.each {|key,value| IniFile.write(@filepath, section, key, value) }
    end
    return self
  end
  #--------------------------------------------------------------------------
  # ● 内容の取得
  #     IniFile#[セクション名][キー名] で内容を取得・設定可能
  #--------------------------------------------------------------------------
  def [](section)
    unless section.is_a?(String)
      raise TypeError, "can't convert #{section.class} into String", caller
    end
    @data[section] ||= {}
    return @data[section]
  end
  #--------------------------------------------------------------------------
  # ● デバッグ文字
  #--------------------------------------------------------------------------
  def inspect
    str = "ファイルパス :\n    `#{@filepath}'\n\n"
    @data.each do |section,data|
      str.concat("[#{section}]\n")
      data.each {|key,value| str.concat("    #{key}=#{value.inspect}\n") }
    end
    return str
  end
end
