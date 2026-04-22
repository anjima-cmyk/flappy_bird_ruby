#!/usr/bin/env ruby
# Flappy Bird - Main Entry Point
# Run: ruby main.rb

require 'gosu'
require_relative 'lib/constants'
require_relative 'lib/bird'
require_relative 'lib/pipe_manager'
require_relative 'lib/game_loop'

window = FlappyBird::GameLoop.new
window.show
