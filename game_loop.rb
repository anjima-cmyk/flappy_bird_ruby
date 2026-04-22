# lib/game_loop.rb
# GameLoop — Gosu::Window subclass managing state machine, HUD, overlays

require 'gosu'
require_relative 'constants'
require_relative 'bird'
require_relative 'pipe_manager'

module FlappyBird
  class GameLoop < Gosu::Window
    include Constants

    # Game states
    IDLE    = :idle
    PLAYING = :playing
    DEAD    = :dead

    def initialize
      super(WINDOW_WIDTH, WINDOW_HEIGHT, false)
      self.caption = WINDOW_TITLE

      @bird         = Bird.new
      @pipe_manager = PipeManager.new
      @state        = IDLE

      @best_score   = load_best_score
      @score_popup  = []          # [{text, x, y, alpha, vy}]
      @death_timer  = 0

      # Parallax background layers
      @cloud_offset = 0.0
      @mountain_offset = 0.0
      @clouds    = generate_clouds
      @mountains = generate_mountains

      # Ground scroll
      @ground_scroll = 0.0

      # Fonts
      @font_big   = Gosu::Font.new(64, name: Gosu.default_font_name)
      @font_med   = Gosu::Font.new(36, name: Gosu.default_font_name)
      @font_small = Gosu::Font.new(22, name: Gosu.default_font_name)
    end

    # ----------------------------------------------------------------
    # Input
    # ----------------------------------------------------------------
    def button_down(id)
      if id == Gosu::KB_SPACE || id == Gosu::MS_LEFT
        case @state
        when IDLE
          start_game
        when PLAYING
          @bird.flap
        when DEAD
          restart_game if @death_timer > 30
        end
      end

      close if id == Gosu::KB_ESCAPE
    end

    # ----------------------------------------------------------------
    # Update (called every frame)
    # ----------------------------------------------------------------
    def update
      case @state
      when IDLE
        # Bird bobs gently
        @bird.update  # gravity off, we manually bob
        idle_bob

      when PLAYING
        @bird.update

        # Parallax scroll
        @cloud_offset    = (@cloud_offset    + 0.4) % WINDOW_WIDTH
        @mountain_offset = (@mountain_offset + 0.8) % WINDOW_WIDTH
        @ground_scroll   = (@ground_scroll   + PIPE_SPEED) % 24

        hit = @pipe_manager.update(@bird)

        if hit || @bird.out_of_bounds?
          @bird.die
          @state      = DEAD
          @death_timer = 0
          save_best_score(@pipe_manager.score)
        end

        # Score pop-up
        if @pipe_manager.score > @last_score.to_i
          @last_score = @pipe_manager.score
          @score_popup << { text: '+1', x: BIRD_X + 20, y: @bird.y - 30,
                            alpha: 255, vy: -2.0 }
        end

      when DEAD
        @death_timer += 1
        # Pipe manager freezes; bird falls off if alive (already dead, velocity applied)
      end

      # Update score pop-ups
      @score_popup.each do |p|
        p[:y]    += p[:vy]
        p[:alpha] = [p[:alpha] - 4, 0].max
      end
      @score_popup.reject! { |p| p[:alpha] <= 0 }
    end

    # ----------------------------------------------------------------
    # Draw
    # ----------------------------------------------------------------
    def draw
      draw_background
      draw_ground

      @pipe_manager.draw(self)
      @bird.draw(self)

      draw_score_popups
      draw_hud

      case @state
      when IDLE  then draw_idle_overlay
      when DEAD  then draw_dead_overlay
      end
    end

    # ----------------------------------------------------------------
    private
    # ----------------------------------------------------------------

    def start_game
      @bird.reset
      @pipe_manager.reset
      @last_score = 0
      @score_popup.clear
      @state = PLAYING
    end

    def restart_game
      start_game
    end

    # Gentle hover bob in idle state
    def idle_bob
      t = Gosu.milliseconds / 600.0
      @bird.instance_variable_set(:@y, BIRD_START_Y + Math.sin(t) * 8)
    end

    # ----------------------------------------------------------------
    # Background
    # ----------------------------------------------------------------
    def draw_background
      # Sky gradient: top to bottom
      top_col = Gosu::Color.new(SKY_TOP)
      bot_col = Gosu::Color.new(SKY_BOTTOM)
      draw_quad(0, 0,           top_col,
                WINDOW_WIDTH, 0,           top_col,
                WINDOW_WIDTH, GROUND_Y,    bot_col,
                0, GROUND_Y,    bot_col, 0)

      draw_mountains
      draw_clouds
    end

    def draw_clouds
      @clouds.each do |c|
        ox = (c[:x] - @cloud_offset) % (WINDOW_WIDTH + 200) - 100
        draw_cloud(ox, c[:y], c[:r], c[:alpha])
      end
    end

    def draw_cloud(cx, cy, r, alpha)
      col = Gosu::Color.new((alpha << 24) | 0xFFFFFF)
      offsets = [[0, 0], [r * 0.6, r * 0.2], [-r * 0.6, r * 0.2],
                 [0, r * 0.4], [r * 0.3, -r * 0.1]]
      offsets.each do |ox, oy|
        draw_circle_prim(cx + ox, cy + oy, r * 0.6, col)
      end
    end

    def draw_mountains
      @mountains.each do |m|
        ox = (m[:x] - @mountain_offset) % (WINDOW_WIDTH + 200) - 100
        col = Gosu::Color.new(m[:color])
        draw_triangle(ox, GROUND_Y,      col,
                      ox + m[:w], GROUND_Y, col,
                      ox + m[:w] / 2, GROUND_Y - m[:h], col, 0)
      end
    end

    def draw_ground
      # Scrolling ground pattern
      col1 = Gosu::Color.new(GROUND_COLOR)
      col2 = Gosu::Color.new(GROUND_STRIPE)

      draw_quad(0, GROUND_Y, col1,
                WINDOW_WIDTH, GROUND_Y, col1,
                WINDOW_WIDTH, WINDOW_HEIGHT, col1,
                0, WINDOW_HEIGHT, col1, 1)

      # Stripe lines
      stripe_w = 24
      offset   = @ground_scroll.to_i
      x = -stripe_w + offset
      while x < WINDOW_WIDTH + stripe_w
        draw_quad(x, GROUND_Y, col2,
                  x + stripe_w / 2, GROUND_Y, col2,
                  x + stripe_w / 2 - 8, WINDOW_HEIGHT, col2,
                  x - 8, WINDOW_HEIGHT, col2, 2)
        x += stripe_w * 2
      end

      # Ground top edge line
      edge_col = Gosu::Color.new(0xFF8B7355)
      draw_quad(0, GROUND_Y - 3,     edge_col,
                WINDOW_WIDTH, GROUND_Y - 3, edge_col,
                WINDOW_WIDTH, GROUND_Y + 2, edge_col,
                0, GROUND_Y + 2, edge_col, 2)
    end

    # ----------------------------------------------------------------
    # HUD
    # ----------------------------------------------------------------
    def draw_hud
      score = @pipe_manager.score
      score_str = score.to_s

      # Shadow
      @font_big.draw_text(score_str,
                          WINDOW_WIDTH / 2 - @font_big.text_width(score_str) / 2 + 2,
                          12 + 2, 5,
                          1, 1, Gosu::Color.new(HUD_SHADOW))
      # White text
      @font_big.draw_text(score_str,
                          WINDOW_WIDTH / 2 - @font_big.text_width(score_str) / 2,
                          12, 5,
                          1, 1, Gosu::Color.new(HUD_SCORE_COLOR))
    end

    def draw_score_popups
      @score_popup.each do |p|
        col = Gosu::Color.new((p[:alpha] << 24) | 0xFFFF00)
        @font_small.draw_text(p[:text], p[:x], p[:y], 6, 1, 1, col)
      end
    end

    # ----------------------------------------------------------------
    # Overlays
    # ----------------------------------------------------------------
    def draw_idle_overlay
      draw_panel(WINDOW_WIDTH / 2 - 160, 180, 320, 200)

      title = 'FLAPPY BIRD'
      @font_med.draw_text(title,
                          WINDOW_WIDTH / 2 - @font_med.text_width(title) / 2,
                          200, 10, 1, 1, Gosu::Color::YELLOW)

      hint = 'Press SPACE to Start'
      @font_small.draw_text(hint,
                            WINDOW_WIDTH / 2 - @font_small.text_width(hint) / 2,
                            260, 10, 1, 1, Gosu::Color::WHITE)

      best = "Best: #{@best_score}"
      @font_small.draw_text(best,
                            WINDOW_WIDTH / 2 - @font_small.text_width(best) / 2,
                            300, 10, 1, 1, Gosu::Color.new(0xFFFFDD44))
    end

    def draw_dead_overlay
      draw_panel(WINDOW_WIDTH / 2 - 160, 160, 320, 230)

      over = 'GAME OVER'
      @font_med.draw_text(over,
                          WINDOW_WIDTH / 2 - @font_med.text_width(over) / 2,
                          175, 10, 1, 1, Gosu::Color.new(0xFFFF4444))

      score_txt = "Score: #{@pipe_manager.score}"
      @font_small.draw_text(score_txt,
                            WINDOW_WIDTH / 2 - @font_small.text_width(score_txt) / 2,
                            230, 10, 1, 1, Gosu::Color::WHITE)

      best_txt = "Best:  #{@best_score}"
      @font_small.draw_text(best_txt,
                            WINDOW_WIDTH / 2 - @font_small.text_width(best_txt) / 2,
                            260, 10, 1, 1, Gosu::Color.new(0xFFFFDD44))

      if @death_timer > 30
        restart_txt = 'Press SPACE to Restart'
        @font_small.draw_text(restart_txt,
                              WINDOW_WIDTH / 2 - @font_small.text_width(restart_txt) / 2,
                              310, 10, 1, 1, Gosu::Color.new(0xFFAAFFAA))
      end
    end

    # Semi-transparent rounded panel
    def draw_panel(x, y, w, h)
      col = Gosu::Color.new(0xCC000000)
      border = Gosu::Color.new(0x88FFFFFF)
      draw_quad(x, y, col, x + w, y, col, x + w, y + h, col, x, y + h, col, 9)
      # Border lines
      [[x, y, x + w, y], [x + w, y, x + w, y + h],
       [x + w, y + h, x, y + h], [x, y + h, x, y]].each do |x1, y1, x2, y2|
        draw_quad(x1, y1 - 1, border, x2, y1 - 1, border,
                  x2, y1 + 1, border, x1, y1 + 1, border, 9)
      end
    end

    # ----------------------------------------------------------------
    # Procedural world elements
    # ----------------------------------------------------------------
    def generate_clouds
      (0..7).map do |i|
        { x: i * 140 + rand(80), y: rand(40..160),
          r: rand(25..50), alpha: rand(180..240) }
      end
    end

    def generate_mountains
      cols = [0xFF7EC8A0, 0xFF6AB090, 0xFF5A9880, 0xFF9ABCB0]
      (0..8).map do |i|
        { x: i * 120 + rand(60), w: rand(100..200),
          h: rand(80..180), color: cols.sample }
      end
    end

    # Filled circle primitive
    def draw_circle_prim(cx, cy, r, color, segments = 14)
      step = 2 * Math::PI / segments
      (0...segments).each do |i|
        a1 = i * step
        a2 = (i + 1) * step
        draw_triangle(cx, cy, color,
                      cx + r * Math.cos(a1), cy + r * Math.sin(a1), color,
                      cx + r * Math.cos(a2), cy + r * Math.sin(a2), color, 0)
      end
    end

    # ----------------------------------------------------------------
    # Persistence
    # ----------------------------------------------------------------
    def load_best_score
      return 0 unless File.exist?(BEST_SCORE_FILE)
      File.read(BEST_SCORE_FILE).to_i
    rescue
      0
    end

    def save_best_score(score)
      if score > @best_score
        @best_score = score
        File.write(BEST_SCORE_FILE, score.to_s)
      end
    rescue
      # silently ignore write errors
    end
  end
end
