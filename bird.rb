# lib/bird.rb
# Bird — physics, drawing, collision

require_relative 'constants'

module FlappyBird
  class Bird
    include Constants

    attr_reader :x, :y, :velocity, :alive, :angle

    def initialize
      reset
    end

    def reset
      @x        = BIRD_X
      @y        = BIRD_START_Y.to_f
      @velocity = 0.0
      @alive    = true
      @angle    = 0.0
      @flap_frame      = 0   # animation frame counter
      @wing_state      = 0   # 0=mid, 1=up, 2=down
      @just_flapped    = false
    end

    # Called once per game frame
    def update
      return unless @alive

      # Physics
      @velocity += GRAVITY
      @velocity  = TERMINAL_VEL if @velocity > TERMINAL_VEL
      @velocity  = MAX_UP_VEL   if @velocity < MAX_UP_VEL
      @y        += @velocity

      # Rotation: smoothly interpolate toward target angle
      target = target_angle
      diff   = target - @angle
      @angle += diff * 0.15

      # Wing animation
      @flap_frame += 1
      if @flap_frame >= FLAP_FRAME_DURATION
        @flap_frame = 0
        @wing_state = (@wing_state + 1) % 3
      end

      @just_flapped = false
    end

    # Apply upward impulse
    def flap
      return unless @alive
      @velocity     = FLAP_FORCE
      @just_flapped = true
      @wing_state   = 1  # snap wings up
      @flap_frame   = 0
    end

    # Returns true if bird is out of bounds (ground / ceiling)
    def out_of_bounds?
      @y + BIRD_RADIUS >= GROUND_Y || @y - BIRD_RADIUS <= 0
    end

    def die
      @alive = false
    end

    # Draw the bird using Gosu primitives (no image assets needed)
    def draw(window)
      cx = @x
      cy = @y

      # Rotate around bird centre
      rad  = @angle * Math::PI / 180.0
      cos_ = Math.cos(rad)
      sin_ = Math.sin(rad)

      # Helper: rotate a local point and offset to world space
      rotate = ->(lx, ly) { [cx + lx * cos_ - ly * sin_, cy + lx * sin_ + ly * cos_] }

      # Body — yellow circle approximated with filled polygon
      draw_circle(window, cx, cy, BIRD_RADIUS, Gosu::Color.new(0xFFFFC300), @angle)

      # Eye white
      ex, ey = rotate.call(7, -5)
      draw_circle(window, ex, ey, 6, Gosu::Color.new(0xFFFFFFFF), 0)

      # Eye pupil
      px, py = rotate.call(9, -5)
      draw_circle(window, px, py, 3, Gosu::Color.new(0xFF222222), 0)

      # Beak
      bx1, by1 = rotate.call(BIRD_RADIUS - 2, -3)
      bx2, by2 = rotate.call(BIRD_RADIUS + 8, 0)
      bx3, by3 = rotate.call(BIRD_RADIUS - 2, 4)
      window.draw_triangle(bx1, by1, Gosu::Color::ORANGE,
                           bx2, by2, Gosu::Color::ORANGE,
                           bx3, by3, Gosu::Color::ORANGE, 2)

      # Wing
      draw_wing(window, cx, cy, cos_, sin_)
    end

    private

    def target_angle
      # Nose-up when going fast up, nose-down when falling
      if @velocity < 0
        t = @velocity / MAX_UP_VEL   # 0..1
        ROT_UP_ANGLE * t
      else
        t = @velocity / TERMINAL_VEL # 0..1
        ROT_DOWN_ANGLE * t
      end
    end

    def draw_wing(window, cx, cy, cos_, sin_)
      rotate = ->(lx, ly) { [cx + lx * cos_ - ly * sin_, cy + lx * sin_ + ly * cos_] }

      # Wing states: 0=mid, 1=up, 2=down
      offsets = case @wing_state
                when 0 then [[-4, 4], [-12, 2], [-12, 10], [-4, 12]]   # mid
                when 1 then [[-4, 2], [-12, -8], [-14, 0],  [-4, 8]]   # up
                when 2 then [[-4, 6], [-10, 12], [-12, 18], [-4, 14]]  # down
                end

      pts = offsets.map { |lx, ly| rotate.call(lx, ly) }
      col = Gosu::Color.new(0xFFFF9900)

      # Draw as two triangles
      window.draw_triangle(*pts[0], col, *pts[1], col, *pts[2], col, 2)
      window.draw_triangle(*pts[0], col, *pts[2], col, *pts[3], col, 2)
    end

    # Draw a filled circle using triangles from centre
    def draw_circle(window, cx, cy, r, color, _angle_deg, segments = 16)
      step = 2 * Math::PI / segments
      (0...segments).each do |i|
        a1 = i * step
        a2 = (i + 1) * step
        window.draw_triangle(
          cx, cy, color,
          cx + r * Math.cos(a1), cy + r * Math.sin(a1), color,
          cx + r * Math.cos(a2), cy + r * Math.sin(a2), color,
          1
        )
      end
    end
  end
end
