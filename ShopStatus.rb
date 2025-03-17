#******************************************************************************
#
#    ＊ ＜拡張＞ ショップステータス
#
#  --------------------------------------------------------------------------
#    バージョン ： 1.0.2
#    対      応 ： RPGツクールVX Ace : RGSS3
#    制  作  者 ： ＣＡＣＡＯ
#    配  布  元 ： https://cacaosoft.mars.jp/
#  --------------------------------------------------------------------------
#   == 概    要 ==
#
#   ： ショップ画面で回復量やパラメータの変化量を表示します。
#
#  --------------------------------------------------------------------------
#   == 注意事項 ==
#
#    ※ エイリアスを用いない再定義を多用しています。
#       なるべく上の方に導入してください。
#
#
#******************************************************************************


#==============================================================================
# ◆ 設定項目
#==============================================================================
module CAO
  module ShopStatus
    #--------------------------------------------------------------------------
    # ◇ 効果範囲を表示する
    #--------------------------------------------------------------------------
    SHOW_EFFECT_SCOPE = true
    #--------------------------------------------------------------------------
    # ◇ 戦闘中使用を表示する
    #--------------------------------------------------------------------------
    SHOW_USABLE_OCCASION = true

    #--------------------------------------------------------------------------
    # ◇ ＨＰ・ＭＰ回復量を表示する
    #--------------------------------------------------------------------------
    SHOW_ITEM_EFFECTS = true
    #--------------------------------------------------------------------------
    # ◇ ＴＰ増加量を表示する
    #--------------------------------------------------------------------------
    SHOW_GAIN_TP = true

    #--------------------------------------------------------------------------
    # ◇ ステート変化を表示する
    #--------------------------------------------------------------------------
    SHOW_STATES = true
    #--------------------------------------------------------------------------
    # ◇ 付加ステートも表示する
    #--------------------------------------------------------------------------
    SHOW_ADD_STATES = false
    #--------------------------------------------------------------------------
    # ◇ 解除ステートの上に描画するアイコン
    #--------------------------------------------------------------------------
    ICON_REMOVE_STATES = 141
    #--------------------------------------------------------------------------
    # ◇ 付加ステートの上に描画するアイコン
    #--------------------------------------------------------------------------
    ICON_ADD_STATES = 142

    #--------------------------------------------------------------------------
    # ◇ 装備品時に表示するパラメータ
    #--------------------------------------------------------------------------
    PARAMS = [:mhp, :mmp, :atk, :def, :mat, :mdf, :agi, :luk]
    #--------------------------------------------------------------------------
    # ◇ 装備可能なアクターのみ表示
    #--------------------------------------------------------------------------
    SHOW_EQUIPPABLE_ACTOR = false
    #--------------------------------------------------------------------------
    # ◇ 装備可能なアクターのパラメータのみ表示
    #--------------------------------------------------------------------------
    SHOW_EQUIPPABLE_PARAMS = true
    #--------------------------------------------------------------------------
    # ◇ 装備中マークの設定
    #--------------------------------------------------------------------------
    ICON_EQUIPPED_MARK = ["Ｅ", 14]
    #--------------------------------------------------------------------------
    # ◇ 装備中マークをアクターに重ねる
    #--------------------------------------------------------------------------
    ON_EQUIPPED_MARK = true

    #--------------------------------------------------------------------------
    # ◇ ページ切り替えに方向キーを使用する
    #--------------------------------------------------------------------------
    BUTTON_ARROW = false

    #--------------------------------------------------------------------------
    # ◇ テキスト
    #--------------------------------------------------------------------------
    VOCAB_EFFECT_SCOPE = ["効果範囲", "なし", "単体", "複数", "全体"]
    VOCAB_USABLE_OCCASION =
      ["使用可能時", "常時", "バトル", "メニュー", "使用不可"]
    VOCAB_EFFECT_HP = "ＨＰ回復量"
    VOCAB_EFFECT_MP = "ＭＰ回復量"
    VOCAB_EFFECT_TP = "ＴＰ増加量"
    VOCAB_CHANGE_STATE = "ステート変化"

    VOCAB_RATE_UNIT = "%"
    VOCAB_POINT_UNIT = ""

    VOCAB_PARAMS = {}
    VOCAB_PARAMS[:mhp] = "最大ＨＰ"
    VOCAB_PARAMS[:mmp] = "最大ＭＰ"
    VOCAB_PARAMS[:atk] = "物理攻撃"
    VOCAB_PARAMS[:def] = "物理防御"
    VOCAB_PARAMS[:mat] = "魔法攻撃"
    VOCAB_PARAMS[:mdf] = "魔法防御"
    VOCAB_PARAMS[:agi] = "敏 捷 性"
    VOCAB_PARAMS[:luk] = "　 運"
  end # module ShopStatus
  end # module CAO


  #/////////////////////////////////////////////////////////////////////////////#
  #                                                                             #
  #                下記のスクリプトを変更する必要はありません。                 #
  #                                                                             #
  #/////////////////////////////////////////////////////////////////////////////#


  class Game_Actor
    #--------------------------------------------------------------------------
    # ● 公開インスタンス変数
    #--------------------------------------------------------------------------
    attr_accessor :icon_index               # アイコン インデックス
    #--------------------------------------------------------------------------
    # ● グラフィックの初期化
    #--------------------------------------------------------------------------
    alias _cao_shopstatus_init_graphics init_graphics
    def init_graphics
      _cao_shopstatus_init_graphics
      @icon_index = 0
    end
  end

  class Window_Base
    #--------------------------------------------------------------------------
    # ● 定数 (歩行アイコンの背景色)
    #--------------------------------------------------------------------------
    COLOR_AIB_1 = Color.new(0, 0, 0)          # アイコンの縁の色
    COLOR_AIB_2 = Color.new(255, 255, 255)    # アイコンの背景色
    #--------------------------------------------------------------------------
    # ● 歩行アイコンの描画
    #     enabled : 有効フラグ。false のとき半透明で描画
    #--------------------------------------------------------------------------
    def draw_character_icon(character_name, character_index, x, y, enabled = true)
      self.contents.fill_rect(x, y, 24, 24, COLOR_AIB_1)
      self.contents.fill_rect(x + 1, y + 1, 22, 22, COLOR_AIB_2)
      if character_name
        bitmap = Cache.character(character_name)
        sign = character_name[/^[\!\$]./]
        if sign != nil and sign.include?('$')
          cw = bitmap.width / 3
          ch = bitmap.height / 4
        else
          cw = bitmap.width / 12
          ch = bitmap.height / 8
        end
        n = character_index
        src_rect = Rect.new((n%4*3+1)*cw, (n/4*4)*ch, 20, 20)
        src_rect.x += (cw - src_rect.width) / 2
        src_rect.y += (ch - src_rect.height) / 4
        opacity = (enabled ? 255 : translucent_alpha)
        self.contents.blt(x + 2, y + 2, bitmap, src_rect, opacity)
      end
    end
  end

  class Window_ShopStatus
    include CAO::ShopStatus
    #--------------------------------------------------------------------------
    # ○ リフレッシュ
    #--------------------------------------------------------------------------
    def refresh
      self.contents.clear
      return unless @item
      @param_y = 0        # 項目の描画位置
      draw_possession(4, 0)
      if @item.kind_of?(RPG::Item)
        @item_effects = {}
        @item.effects.each do |e|
          @item_effects[e.code] ||= []
          @item_effects[e.code] << e
        end
        draw_item_info(4, line_height * 1.5)
      elsif @item.kind_of?(RPG::EquipItem)
        draw_equip_info(4, line_height * 1.5 + 8)
      end
    end
    #--------------------------------------------------------------------------
    # ● アイテム情報の描画
    #--------------------------------------------------------------------------
    def draw_item_info(x, y)
      @param_y = y
      draw_item_scope(x, @param_y)
      draw_item_occasion(x, @param_y)
      @param_y += (line_height / 2) if SHOW_EFFECT_SCOPE || SHOW_USABLE_OCCASION
      draw_item_effects(x, @param_y)
      draw_item_states(x, @param_y)
    end
    #--------------------------------------------------------------------------
    # ● 効果範囲の描画
    #--------------------------------------------------------------------------
    def draw_item_scope(x, y)
      return unless SHOW_EFFECT_SCOPE
      dr = Rect.new(x, y, contents_width - 4 - x, line_height)
      change_color(system_color)
      draw_text(dr, VOCAB_EFFECT_SCOPE[0])
      change_color(normal_color)
      case @item.scope
      when 0
        draw_text(dr, VOCAB_EFFECT_SCOPE[1], 2)
      when 1,3,7,9,11
        draw_text(dr, VOCAB_EFFECT_SCOPE[2], 2)
      when 4,5,6
        draw_text(dr, VOCAB_EFFECT_SCOPE[3], 2)
      when 2,8,10
        draw_text(dr, VOCAB_EFFECT_SCOPE[4], 2)
      else
        raise "must not happen"
      end
      @param_y += line_height
    end
    #--------------------------------------------------------------------------
    # ● 使用可能時の描画
    #--------------------------------------------------------------------------
    def draw_item_occasion(x, y)
      return unless SHOW_USABLE_OCCASION
      dr = Rect.new(x, y, contents_width - 4 - x, line_height)
      change_color(system_color)
      draw_text(dr, VOCAB_USABLE_OCCASION[0])
      change_color(normal_color)
      draw_text(dr, VOCAB_USABLE_OCCASION[@item.occasion + 1], 2)
      @param_y += line_height
    end
    #--------------------------------------------------------------------------
    # ● ＨＰ・ＭＰ・ＴＰの回復量の描画
    #--------------------------------------------------------------------------
    def draw_item_effects(x, y)
      return unless SHOW_ITEM_EFFECTS
      ehp = @item_effects[Game_Battler::EFFECT_RECOVER_HP]
      emp = @item_effects[Game_Battler::EFFECT_RECOVER_MP]

      dr = Rect.new(x, y, contents_width - 4 - x, line_height)
      change_color(system_color)
      draw_text(dr, VOCAB_EFFECT_HP)
      dr.y += line_height
      draw_text(dr, VOCAB_EFFECT_MP)

      dr.y = y
      change_color(normal_color)
      draw_text(dr, text_recovery_amount(ehp), 2)
      dr.y += line_height
      draw_text(dr, text_recovery_amount(emp), 2)

      if SHOW_GAIN_TP
        etp = @item_effects[Game_Battler::EFFECT_GAIN_TP]
        dr.y = y + line_height * 2
        change_color(system_color)
        draw_text(dr, VOCAB_EFFECT_TP)
        change_color(normal_color)
        text = "#{etp ? etp[0].value1.to_i : 0}#{VOCAB_RATE_UNIT}"
        draw_text(dr, text, 2)
      end
      @param_y = dr.y + line_height * 1.5
    end
    #--------------------------------------------------------------------------
    # ● ＨＰ・ＭＰ回復量をテキストで取得
    #--------------------------------------------------------------------------
    def text_recovery_amount(effects)
      if effects
        value1 = (effects[0].value1.to_f * 100).to_i
        value2 = effects[0].value2.to_i
      else
        value1 = 0
        value2 = 0
      end
      return "#{value2}#{VOCAB_POINT_UNIT}" if value1 == 0
      return "#{value1}#{VOCAB_RATE_UNIT}" if value2 == 0
      return "#{value1}#{VOCAB_RATE_UNIT} + #{value2}#{VOCAB_POINT_UNIT}"
    end
    #--------------------------------------------------------------------------
    # ● ステートの描画
    #--------------------------------------------------------------------------
    def draw_item_states(x, y)
      return unless SHOW_STATES

      change_color(system_color)
      draw_text(x, y, contents_width - 4 - x, line_height, VOCAB_CHANGE_STATE)
      x += (contents_width - 4 - x) % 24
      y += line_height
      erss = @item_effects[Game_Battler::EFFECT_REMOVE_STATE] || []
      draw_states_icon(x, y, erss, 0, ICON_REMOVE_STATES)
      eass = @item_effects[Game_Battler::EFFECT_ADD_STATE] || []
      draw_states_icon(x, y, eass, erss.size, ICON_ADD_STATES) if SHOW_ADD_STATES
      unless !erss.empty? || (SHOW_ADD_STATES && !eass.empty?)
        change_color(normal_color)
        draw_text(x, y, contents_width - 4 - x, line_height, "なし")
      end
      icon_line_max = (contents_width - 4 - x) / 24   # １行に表示できる数
      @param_y = y + line_height / 2
      @param_y += ((erss.size + eass.size) / icon_line_max + 1) * line_height
    end
    #--------------------------------------------------------------------------
    # ● ステートアイコンの描画
    #     super_icon_index : 重ねるアイコンの番号
    #--------------------------------------------------------------------------
    def draw_states_icon(x, y, effects, index, super_icon_index)
      icon_line_max = (contents_width - 4 - x) / 24
      effects.each do |e|
        next if e.data_id == 0
        draw_state_icon(
          x + (index % icon_line_max) * 24,
          y + (index / icon_line_max) * line_height,
          $data_states[e.data_id].icon_index, super_icon_index)
        index += 1
      end
    end
    #--------------------------------------------------------------------------
    # ● ステートアイコンの描画
    #     state_icon_index : ステートアイコンの番号
    #     super_icon_index : 重ねるアイコンの番号
    #--------------------------------------------------------------------------
    def draw_state_icon(x, y, state_icon_index, super_icon_index)
      draw_icon(state_icon_index, x, y)
      case super_icon_index
      when nil
        return
      when String
        bitmap = Cache.system(super_icon_index)
        self.contents.blt(x, y, bitmap, bitmap.rect)
      else
        draw_icon(super_icon_index, x, y)
      end
    end
    #--------------------------------------------------------------------------
    # ● 能力強化/弱体化の描画
    #--------------------------------------------------------------------------
    def draw_item_buff(x, y)
      # 未実装
    end
    #--------------------------------------------------------------------------
    # ● 能力強化/弱体化の描画 (複数)
    #--------------------------------------------------------------------------
    def draw_item_buffs(x, y)
      # 未実装
    end
    #--------------------------------------------------------------------------
    # ● 成長パラメータの描画
    #--------------------------------------------------------------------------
    def draw_item_grows(x, y)
      # 未実装
    end
  end

  class Window_ShopStatus
    #--------------------------------------------------------------------------
    # ● 定数
    #--------------------------------------------------------------------------
    ACTOR_WIDTH = 36                        # 各アクターの横幅
    PARAM_WIDTH_MAX = 96                    # パラメータ名の最大横幅
    #--------------------------------------------------------------------------
    # ● 定数（ＩＤへの変換用）
    #--------------------------------------------------------------------------
    PARAM_ID = [:mhp, :mmp, :atk, :def, :mat, :mdf, :agi, :luk, :hit]
    #--------------------------------------------------------------------------
    # ● 装備可能なアクターの配列
    #--------------------------------------------------------------------------
    def equippable_members
      members = $game_party.members
      if SHOW_EQUIPPABLE_ACTOR
        members.select! {|actor| equippable?(actor, @item) }
      end
      return members
    end
    #--------------------------------------------------------------------------
    # ○ 装備情報を描画するアクターの配列
    #--------------------------------------------------------------------------
    def status_members
      return equippable_members[@page_index * page_size, page_size]
    end
    #--------------------------------------------------------------------------
    # ○ アイテムの設定
    #--------------------------------------------------------------------------
    def item=(item)
      @page_index = 0 if SHOW_EQUIPPABLE_ACTOR
      @item = item
      refresh
    end
    #--------------------------------------------------------------------------
    # ○ 一度に表示できるアクターの人数
    #--------------------------------------------------------------------------
    def page_size
      [4, (contents_width - PARAM_WIDTH_MAX) / ACTOR_WIDTH].max
    end
    #--------------------------------------------------------------------------
    # ○ 最大ページ数の取得
    #--------------------------------------------------------------------------
    def page_max
      return (equippable_members.size + page_size - 1) / page_size
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def actor_icon_margin
      return (ACTOR_WIDTH - 24) / 2
    end
    #--------------------------------------------------------------------------
    # ● パラメータ名の横幅
    #--------------------------------------------------------------------------
    def param_width
      return [PARAM_WIDTH_MAX, contents_width - page_size * ACTOR_WIDTH].min
    end
    #--------------------------------------------------------------------------
    # ● 装備可能判定
    #--------------------------------------------------------------------------
    def equippable?(actor, item)
      return false unless @item.is_a?(RPG::EquipItem)
      set_equips(actor)
      return false if include_feature?(actor, :fix)
      return false if include_feature?(actor, :seal)
      return include_feature?(actor, :wtype) if @item.is_a?(RPG::Weapon)
      return include_feature?(actor, :atype) if @item.is_a?(RPG::Armor)
      return false
    end
    #--------------------------------------------------------------------------
    # ● 特徴オブジェクトの配列取得
    #--------------------------------------------------------------------------
    def features(actor, code)
      features = (actor.feature_objects - actor.equips) + @equips.compact
      features = features.map(&:features).flatten.uniq
      features.select {|ft| ft.code == code }.map {|ft| ft.data_id }.uniq
    end
    #--------------------------------------------------------------------------
    # ●
    #--------------------------------------------------------------------------
    def include_feature?(actor, code)
      klass = Game_BattlerBase
      case code
      when :fix
        features(actor, klass::FEATURE_EQUIP_FIX).include?(@item.etype_id)
      when :seal
        features(actor, klass::FEATURE_EQUIP_SEAL).include?(@item.etype_id)
      when :wtype
        features(actor, klass::FEATURE_EQUIP_WTYPE).include?(@item.wtype_id)
      when :atype
        features(actor, klass::FEATURE_EQUIP_ATYPE).include?(@item.atype_id)
      else
        raise "not must happen"
      end
    end
    #--------------------------------------------------------------------------
    # ● 装備するために外す必要のある装備を除外した配列を作成
    #--------------------------------------------------------------------------
    def set_equips(actor)
      @equips = actor.equips
      # @item を封印する装備、@item が封印する装備を外す
      @equips.map! do |item|
        result = nil
        if item
          result = item
          item.features.each do |ft|
            next if ft.code != Game_BattlerBase::FEATURE_EQUIP_SEAL
            next if ft.data_id != @item.etype_id
            result = nil
          end
          @item.features.each do |ft|
            next if ft.code != Game_BattlerBase::FEATURE_EQUIP_SEAL
            next if ft.data_id != item.etype_id
            result = nil
          end
        end
        result
      end
      # @item の部位の装備を外す
      index = @equips.index(current_equipped_item(actor, @item.etype_id))
      @equips[index] = nil if index
    end
    #--------------------------------------------------------------------------
    # ○ 装備情報の描画
    #--------------------------------------------------------------------------
    def draw_equip_info(x, y)
      icon_y = y
      param_y = y + line_height * 1.5
      unless ON_EQUIPPED_MARK
        icon_y += line_height
        param_y += line_height
      end
      draw_parameters_name(x, param_y)
      x += param_width
      status_members.each_with_index do |actor, i|
        enabled = SHOW_EQUIPPABLE_ACTOR || equippable?(actor, @item)
        draw_actor_icon(x + actor_icon_margin, y, actor, enabled)
        draw_actor_equipped_mark(x, icon_y, actor, enabled)
        draw_actor_equip_info(x, param_y, actor, enabled)
        x += ACTOR_WIDTH
      end
    end
    #--------------------------------------------------------------------------
    # ● パラメータ名の描画
    #--------------------------------------------------------------------------
    def draw_parameters_name(x, y)
      width = param_width
      change_color(system_color)
      PARAMS.each_with_index do |param, i|
        draw_text(x, y, width, line_height, VOCAB_PARAMS[param])
        y += line_height
      end
    end
    #--------------------------------------------------------------------------
    # ● アクターアイコンの描画
    #--------------------------------------------------------------------------
    def draw_actor_icon(x, y, actor, enabled)
      if actor.icon_index > 0
        bitmap = Cache.system("ActorIconSet")
        rect = Rect.new(actor.icon_index%16*24, actor.icon_index/16*24, 24, 24)
        self.contents.blt(x, y, bitmap, rect, enabled ? 255 : translucent_alpha)
      else
        draw_character_icon(
          actor.character_name, actor.character_index, x, y, enabled)
      end
    end
    #--------------------------------------------------------------------------
    # ● 装備中マークの描画
    #--------------------------------------------------------------------------
    def draw_actor_equipped_mark(x, y, actor, enabled)
      return unless actor.equips.include?(@item)
      case ICON_EQUIPPED_MARK
      when nil
        return
      when String
        x += actor_icon_margin
        bitmap = Cache.system(ICON_EQUIPPED_MARK)
        self.contents.blt(x, y, bitmap, bitmap.rect)
      when Integer
        x += actor_icon_margin
        draw_icon(ICON_EQUIPPED_MARK, x, y)
      when Array
        change_color(text_color(ICON_EQUIPPED_MARK[1]))
        if ON_EQUIPPED_MARK
          self.contents.font.size = 16
          draw_text(x, y + 12, ACTOR_WIDTH, 16, ICON_EQUIPPED_MARK[0], 2)
          self.contents.font.size = Font.default_size
        else
          draw_text(x, y + 4, ACTOR_WIDTH, line_height, ICON_EQUIPPED_MARK[0], 1)
        end
      end
    end
    #--------------------------------------------------------------------------
    # ○ アクターの装備情報の描画
    #--------------------------------------------------------------------------
    def draw_actor_equip_info(x, y, actor, enabled)
      if !SHOW_EQUIPPABLE_PARAMS || enabled
        draw_actor_param_change(
          x, y, actor, current_equipped_item(actor, @item.etype_id))
      end
    end
    #--------------------------------------------------------------------------
    # ○ アクターの能力値変化の描画
    #--------------------------------------------------------------------------
    def draw_actor_param_change(x, y, actor, item1, enabled = true)
      self.contents.font.size = 18
      rect = Rect.new(x, y, ACTOR_WIDTH, line_height)
      if enabled
        PARAMS.each_with_index do |param,i|
          param_id = PARAM_ID.index(param)
          rect.y = y + line_height * i
          change = @item.params[param_id]
          @equips.each {|item| change += item.params[param_id] if item }
          actor.equips.each {|item| change -= item.params[param_id] if item }
          change_color(param_change_color(change))
          draw_text(rect, (change.zero? ? "-" : sprintf("%+d", change)), 1)
        end
      else
        change_color(normal_color, false)
        PARAMS.size.times do |i|
          rect.y = y + line_height * i
          draw_text(rect, "-", 1)
        end
      end
      self.contents.font.size = Font.default_size
    end
    #--------------------------------------------------------------------------
    # ○ ページの更新
    #--------------------------------------------------------------------------
    alias _cao_shopstatus_update_page update_page
    def update_page
      return if @item && !@item.is_a?(RPG::EquipItem)
      if BUTTON_ARROW
        return if !visible || page_max <= 1
        last_page = @page_index
        @page_index -= 1 if Input.trigger?(:LEFT)
        @page_index += 1 if Input.trigger?(:RIGHT)
        if @page_index != last_page
          @page_index %= page_max
          refresh
        end
      else
        _cao_shopstatus_update_page
      end
    end
  end
