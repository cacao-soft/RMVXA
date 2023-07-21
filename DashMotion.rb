#=============================================================================
#  [RGSS3] Dash Motion - v0.0.1
# ---------------------------------------------------------------------------
#  Copyright (c) 2023 CACAO
#  Released under the MIT License.
#  https://opensource.org/licenses/MIT
# ---------------------------------------------------------------------------
#  [Twitter] https://twitter.com/cacao_soft/
#  [GitHub]  https://github.com/cacao-soft/
#=============================================================================

class Game_Character
  def change_dash_motion?
    false
  end
end

class Game_Player
  def change_dash_motion?
    dash? && (moving? || Input.dir4 > 0)
  end
end

class Game_Follower
  def change_dash_motion?
    $game_player.change_dash_motion?
  end
end

class Sprite_Character
  alias _cao_dash_motion_update update
  def update
    _cao_dash_motion_update
    self.angle = 0
    if @character.change_dash_motion?
      case @character.direction
      when 4
        self.angle = 10
      when 6
        self.angle = -10
      end
    end
  end
end
