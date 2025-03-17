#
#   * アイテム合成のデータ設定
#
#
#   ※ アイテム合成スクリプト本体より下に導入してください。
#   ※ 増減させるアイテムの設定で同じアイテムは重複できません。
#   ※ データの出力は、テストプレイ時のみ行います。
#   ※ データの出力後、このスクリプトは不要です。
#


# レシピの設定
ITEMMAKE_RECIPES = [
  # アイコン, 名前, 価格, [減らすアイテム], [増やすアイテム], 説明

  # [1] 調合
  [192, "ハイポーション",   0, ["I1:3"],    ["I2:1"], 1002],
  [192, "フルポーションＡ", 0, ["I1:10"],   ["I3:1"], 1003],
  [192, "フルポーションＢ", 0, ["I2:3"],    ["I3:1"], 1003],
  [197, "エリクサー",       0, ["I3","I4"], ["I8:1"], 1008],
  [194, "ディスペルハーブ", 0, ["I5"],      ["I7:3"], 1007],

  # [6] 鍛冶屋
  [147, "ロングソード", 300,  ["W19:2"],     ["W20"], 2020],
  [147, "ファルシオン", 1000, ["W20:2"],     ["W21"], 2021],
  [149, "クロスボウ",   1000, ["W13","W55"], ["W33"], 2033],

  # [9] 交換
  [168, "普段着",         0, ["A1"],  ["I1"],
    "普段着をポーションをと交換します。"],
  [162, "バンダナ",       0, ["A6"],  ["I1"],
    "バンダナをポーションと交換します。"],
  [179, "幸運のお守り",   0, ["A55"], ["I16:5"],
    "幸運のお守りをラックアップと交換します。"],
  [179, "光のタリスマン", 0, ["A60"], ["I11","I12","I13","I14","I15","I16"],
    "光のタリスマンをいろいろと交換します。"],

  # [13] セット販売
  [192, "回復セット", 350, [], ["I1:2","I4","I6"],
    "ポーション、マジックウォーター、アンチドーテのセット"],
  [164, "勇者セット", 500, [], ["W19","A46","A21","I1:3","I6:2"],
    "初めての勇者セットです。\n駆け出しの勇者さんにおすすめです。"],

  # [15] 合成 (増やすアイテム, 価格, [減らすアイテム])
  ["I2",  10, ["I1:3"]],
  [100203, 0, ["I1:5", "I2:2"]],
]


ITEMMAKE_BOOKS = [
  # アイコン, 名前, [リスト], [減数,増数], [減名,増名], [背景,前景], "効果音"
  [230, "すべて", Array(1..16), [],    [], [], "Shop"],
  [279, "調　合", [1,2,3,4,5],  [2,2], [], [], :nosct],
  [284, "鍛冶屋", [6,7,8,2],      [],    [], [], :price, :qty],
  [495, "交　換", [9,10,11,12], [1,6], ["渡すアイテム","受け取るアイテム"]],
  [270, "セット", [13,14],      [0,5], ["","セット内容"], [], [], :price],
]


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


# レシピデータの出力
def save_item_make_recipe_data
  result = [nil]
  ITEMMAKE_RECIPES.each do |data|
    recipe = RPG::ItemMake::Recipe.new
    recipe.id = result.size
    if data.size == 3
      item = RPG::ItemMake::Item.new(data[0]).object
      recipe.icon_index = item.icon_index
      recipe.name = item.name
      recipe.price = data[1].to_i
      recipe.minus_items = data[2].map {|s| RPG::ItemMake::Item.new(s) }
      recipe.plus_items = [RPG::ItemMake::Item.new(data[0])]
      recipe.description = item.description
    else
      recipe.icon_index = data[0]
      recipe.name = data[1]
      recipe.price = data[2].to_i
      recipe.minus_items = data[3].map {|s| RPG::ItemMake::Item.new(s) }
      recipe.plus_items = data[4].map {|s| RPG::ItemMake::Item.new(s) }
      recipe.description = data[5]
    end
    result << recipe
  end
  save_data(result, "Data/#{CAO::ItemMake::FILE_RECIPE}")
end

# レシピブックデータの出力
def save_item_make_book_data
  result = [nil]
  ITEMMAKE_BOOKS.each do |data|
    book = RPG::ItemMake::Book.new
    book.id = result.size
    book.icon_index = data[0]
    book.name = data[1]
    book.list = data[2]
    if data[3].is_a?(Array)
      book.minus_number = data[3][0] if data[3][0]
      book.plus_number = data[3][1] if data[3][1]
    end
    if data[4].is_a?(Array)
      book.minus_name = data[4][0]
      book.plus_name = data[4][1]
    end
    if data[5].is_a?(Array)
      book.background_name = data[5][0]
      book.foreground_name = data[5][1]
    end
    case data[6]
    when String
      book.make_se.name   = data[6]
      book.make_se.volume = 80
      book.make_se.pitch  = 100
    when Array
      book.make_se.name   = data[6][0] || ""
      book.make_se.volume = data[6][1] || 80
      book.make_se.pitch  = data[6][2] || 100
    end

    book.display_price = data.include?(:price)
    book.visible_window = !data.include?(:nownd)
    book.visible_secret = !data.include?(:nosct)
    book.specify_quantity = data.include?(:qty)
    result << book
  end
  save_data(result, "Data/#{CAO::ItemMake::FILE_BOOK}")
end

def chack_item_make_data
  data = [] << $data_items << $data_weapons << $data_armors
  books = load_data("Data/#{CAO::ItemMake::FILE_BOOK}")
  recipes = load_data("Data/#{CAO::ItemMake::FILE_RECIPE}")

  (1...books.size).each do |book_id|
    books[book_id].list.each do |recipe_id|
      unless recipes[recipe_id]
        msgbox "ブック #{book_id} 番\n#{recipe_id} 番のレシピが見つかりません。"
        next
      end
      imitems = recipes[recipe_id].plus_items | recipes[recipe_id].minus_items
      imitems.each do |im|
        item = data[im.class_id][im.item_id]
        unless item
          msgbox "レシピ #{recipe_id} 番\n#{im.item_id} 番の" +
                 "#{["アイテム","武器","防具"][im.class_id]}が見つかりません。"
          next
        end
      end
    end
  end
end

if $TEST
  $data_items   = load_data("Data/Items.rvdata2")
  $data_weapons = load_data("Data/Weapons.rvdata2")
  $data_armors  = load_data("Data/Armors.rvdata2")

  save_item_make_recipe_data
  save_item_make_book_data
  chack_item_make_data
end
