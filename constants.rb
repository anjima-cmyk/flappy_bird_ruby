# lib/constants.rb
# All game constants — tweak these to tune feel

module FlappyBird
  module Constants
    # Window
    WINDOW_WIDTH  = 480
    WINDOW_HEIGHT = 640
    WINDOW_TITLE  = 'Flappy Bird'
    TARGET_FPS    = 60

    # Physics
    GRAVITY        = 0.5    # pixels/frame² — downward acceleration
    FLAP_FORCE     = -9.0   # pixels/frame  — upward impulse on flap
    TERMINAL_VEL   = 12.0   # max downward velocity (pixels/frame)
    MAX_UP_VEL     = -12.0  # cap upward velocity

    # Bird
    BIRD_X         = 80     # fixed horizontal position
    BIRD_RADIUS    = 17     # collision circle radius
    BIRD_START_Y   = WINDOW_HEIGHT / 2

    # Rotation (degrees, tied to velocity)
    ROT_UP_ANGLE   = -25.0  # nose-up max angle
    ROT_DOWN_ANGLE =  90.0  # nose-down max angle
    ROT_SPEED      =   4.0  # degrees per frame toward target

    # Wing animation
    FLAP_FRAME_DURATION = 6  # frames per wing position

    # Pipes
    PIPE_WIDTH        = 70
    PIPE_GAP          = 160   # vertical gap between top and bottom pipe
    PIPE_SPEED        = 3.0   # pixels/frame scrolling left
    PIPE_SPAWN_INTERVAL = 90  # frames between spawns
    PIPE_MIN_TOP      = 60    # minimum top pipe bottom-y
    PIPE_MAX_TOP      = WINDOW_HEIGHT - 200  # maximum top pipe bottom-y

    # Ground
    GROUND_Y      = WINDOW_HEIGHT - 80
    GROUND_HEIGHT = 80

    # Score file
    BEST_SCORE_FILE = File.join(Dir.home, '.flappy_bird_best')

    # Colors (Gosu::Color.argb)
    # Sky gradient stops
    SKY_TOP    = 0xFF4EC0CA
    SKY_BOTTOM = 0xFF87CEEB

    # Ground colors
    GROUND_COLOR  = 0xFFDEB887
    GROUND_STRIPE = 0xFFD2A679

    PIPE_COLOR     = 0xFF6AB04C
    PIPE_DARK      = 0xFF4A8A2C
    PIPE_CAP_COLOR = 0xFF5A9A3C

    # HUD
    HUD_SCORE_COLOR = 0xFFFFFFFF
    HUD_SHADOW      = 0xFF333333
  end
end
