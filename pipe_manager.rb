# lib/pipe_manager.rb
# PipeManager — handles all pipe pairs (spawn, update, draw, collision, score)

require_relative 'constants'

module FlappyBird
  # A single pipe pair (top + bottom)
  Pipe = Struct.new(:x, :gap_top_y, :scored) do
    include Constants

    def gap_bottom_y
      gap_top_y + PIPE_GAP
    end

    # True if bird circle collides with this pipe pair
    def collides_with_bird?(bird)
      bx = bird.x
      by = bird.y
      r  = BIRD_RADIUS

      # Horizontal overlap?
      return false if bx + r < x || bx - r > x + PIPE_WIDTH

      # Top pipe: from 0 to gap_top_y
      return true if by - r < gap_top_y

      # Bottom pipe: from gap_bottom_y to GROUND_Y
      return true if by + r > gap_bottom_y

      false
    end

    # Pipe has scrolled fully off screen left
    def off_screen?
      x + PIPE_WIDTH < 0
    end

    def draw(window)
      cap_h = 20
      cap_w = PIPE_WIDTH + 8
      cap_x = x - 4

      top_h = gap_top_y
      bot_y = gap_bottom_y
      bot_h = GROUND_Y - bot_y

      pipe_col = Gosu::Color.new(PIPE_COLOR)
      dark_col = Gosu::Color.new(PIPE_DARK)
      cap_col  = Gosu::Color.new(PIPE_CAP_COLOR)

      # Top pipe body
      draw_rect(window, x, 0, PIPE_WIDTH, top_h - cap_h, pipe_col, dark_col)
      # Top pipe cap
      window.draw_quad(
        cap_x,            top_h - cap_h, cap_col,
        cap_x + cap_w,    top_h - cap_h, cap_col,
        cap_x + cap_w,    top_h,          dark_col,
        cap_x,            top_h,          dark_col,
        1
      )

      # Bottom pipe body
      draw_rect(window, x, bot_y + cap_h, PIPE_WIDTH, bot_h - cap_h, pipe_col, dark_col)
      # Bottom pipe cap
      window.draw_quad(
        cap_x,         bot_y,          dark_col,
        cap_x + cap_w, bot_y,          dark_col,
        cap_x + cap_w, bot_y + cap_h,   cap_col,
        cap_x,         bot_y + cap_h,   cap_col,
        1
      )
    end

    private

    def draw_rect(window, rx, ry, rw, rh, left_col, right_col)
      return if rh <= 0
      mid = rx + rw / 2
      window.draw_quad(
        rx,       ry,       left_col,
        mid,      ry,       right_col,
        mid,      ry + rh,  right_col,
        rx,       ry + rh,  left_col,
        1
      )
      window.draw_quad(
        mid,      ry,       right_col,
        rx + rw,  ry,       left_col,
        rx + rw,  ry + rh,  left_col,
        mid,      ry + rh,  right_col,
        1
      )
    end
  end

  # ----------------------------------------------------------------
  class PipeManager
    include Constants

    attr_reader :pipes, :score

    def initialize
      reset
    end

    def reset
      @pipes         = []
      @score         = 0
      @spawn_counter = 0
    end

    def update(bird)
      @spawn_counter += 1
      spawn_pipe if @spawn_counter >= PIPE_SPAWN_INTERVAL

      @pipes.each do |pipe|
        pipe.x -= PIPE_SPEED

        # Score: bird centre crosses pipe right edge
        if !pipe.scored && bird.x > pipe.x + PIPE_WIDTH
          pipe.scored = true
          @score += 1
        end
      end

      # Remove off-screen pipes
      @pipes.reject!(&:off_screen?)

      # Collision check
      @pipes.any? { |pipe| pipe.collides_with_bird?(bird) }
    end

    def draw(window)
      @pipes.each { |p| p.draw(window) }
    end

    private

    def spawn_pipe
      @spawn_counter = 0
      gap_top = rand(PIPE_MIN_TOP..PIPE_MAX_TOP)
      @pipes << Pipe.new(WINDOW_WIDTH.to_f, gap_top, false)
    end
  end
end
