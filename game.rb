#!/usr/bin/env ruby -w
require 'rubygems'
require 'gosu'
include Gosu

class Floor
  attr_accessor :x, :y, :width, :height, :color

  def initialize(window, x, y, width, height, color)
    @x = x
    @y = y
    @width = width
    @height = height
    @color = color
    @window = window
	@count = 0
  end

  def draw
    #draw_quad(x1, y1, c1, x2, y2, c2, x3, y3, c3, x4, y4, c4, z = 0, mode = :default)
    # points are in clockwise order
    @window.draw_quad @x, @y, @color, @x + @width, @y, @color, @x + @width, @y + @height, @color, @x, @y + @height, @color
  end
end


class Game < Window
  def initialize
    super(1233, 480, false)
    self.caption = "Chrome Dinosaur Game"
	@game = true # is the game still going?
	# trash is sprites we don't want to use
    @trash, @trash1, @walker1, @walker2, @jump = *Image.load_tiles(self, "walkers.png", 58, 68, false)
	# bird motions
	@bird1, @bird2 = *Image.load_tiles(self, "birds.png", 58, 68, false)
	#crouch motions
	@crouch1, @crouch2 = *Image.load_tiles(self, "crouchers.png", 65, 68, false)
	##########################################
	#cacti, Dec variables are to move them across the screen, only using two cacti overall
	# heights are used to detect collisions
	@smallCacti = Image.new("smallCacti.png")
	@sDec = 1233
	@bigCacti = Image.new("bigCacti.png")
	@bDec = 1233 + rand(500..1233)
	@bigCactHeight = 283
	@smallCactHeight = 293
	##########################################
	# bX and bY are bird positions, X position is based on cacti, subject to change, y 
	# is within range to hit our player, curBird is the sprite currently used
	@bX = @sDec + @bDec
	@bY = rand(190..305)
	@curBird = @bird1
	##########################################
	# x and y are our positions, vy handles the jumping
    @x, @y = 60, 250
    @vy = -20
	##########################################
    @cur_image = @walker1 # our characters current sprite
	##########################################
	# y values are y values on screen, dec values are x values that get decremented, and 
	# images are pulling from sprites
	@cloud1 = Image.new("cloud.png", false)
	@c1Dec = rand(0..1233)
	@c1Y = rand(0..225)
	@cloud2 = Image.new("cloud.png", false)
	@c2Dec = @c1Dec + rand(0..1233)
	@c2Y = rand(0..225)
	@cloud3 = Image.new("cloud.png", false)
	@c3Dec = @c2Dec + @c1Dec + rand(0..1233)
	@c3Y = rand(0..225)
    @floor = Image.new("floor.png", false)
	@dec = 1233
	##########################################
	# current score and create font objects for our text
	@score = 0
	@scoreText = Font.new(self, Gosu::default_font_name, 20)
	@scoreTextEnd = Font.new(self, Gosu::default_font_name, 100)
	@escape = Font.new(self, Gosu::default_font_name, 30) # if game is over
	@scoreOut = "Score: " # base string for score outputting
	#########################################
	# key is saying what position the character is in based on key press, standing/ jumping or crouched
	# counter handles when to increase speed, and speedup is our incrementor of speed
	@key = 0
	@counter = 0
	@speedUp = 0
	########################################
	# intro check says we need to display intro, intro is our text to output
	@introCheck = 0
	@intro = "Press 'w' to jump or stand up and 's' to crouch!"
  end

  def update
  # do we need the intro text? 
	if @introCheck == 0
	#display it for 200 iterations
		if @counter == 200
			@introCheck = 1
			@counter = 0
		elsif @counter >= 170 # display go right before game starts
			@intro = "Go!"
		end
		@counter += 1
	else
	#################################################################
	# hit detection for small cactus, big cactus, and birds. if we hit any of them game = false
		if (@sDec <= 60 and @sDec >= -65) and @y >= @smallCactHeight
			@game = false
		end
		if (@bDec <= 60 and @bDec >= -90) and @y >= @bigCactHeight
			@game = false
		end
		# birds have to handle crouch, standing, and jumping
		if (@bX <= 60 and @bX >= 0)
			if (@key ==0 and @y >= @bY and @y <= @bY + 57) or (@key ==1 and @y >= @bY and @y + 30 <= @bY + 60) # we are below the and above the bottom
				@game = false
			end
		end
	#################################################################	
		if @game == true
			# every 1000 iterations we need to increase the speed
			if @counter == 1000
				@speedUp += 1
				@counter = 0
			end
			@counter += 1
			
			##########################################################
			# move our enemies, clouds, and floor, towards our character to simulate motion
			@dec -= 7 + @speedUp
			@c1Dec -= 1
			@bDec -= 7 + @speedUp
			@sDec -= 7 + @speedUp
			@c2Dec -= 1
			@c3Dec -= 1
			@bX -= 7 + @speedUp
			##########################################################
			# if we have moved an item off the page then respawn it on the end of the window
			# big cactus
			if @bDec <= -150 then
				@bDec = 1233 + rand(0..1233) + @sDec
			end
			# small cactus
			if @sDec <= -100 then
				@sDec = rand(500..1233) + @bDec
				if @sDec < 1233
					@sDec = @sDec + (1233 - @sDec) + @bX
				end
			end
			# cloud 1
			if @c1Dec <= -100 then
				@c1Dec = 1233 + rand(0..225)
				@c1Y = rand(0..225)
			end
			# bird
			if @bX <= -60 then
				@bX = @sDec + @bDec
				@bY = rand(190..305)
			end
			# cloud 2
			if @c2Dec <= -100 then
				@c2Dec = 1233 + rand(0..225)
				@c2Y = rand(0..225)
			end
			# cloud 3
			if @c3Dec <= -100 then
				@c3Dec = 1233 + rand(0..225)
				@c3Y = rand(0..225)
			end
			# floor
			if @dec <= 0 then
				@dec = 1233
			end
			######################################################
			# if key = 0 then we last pressed 'w' or nothing has been pressed yet, so make character
			# standing and walking otherwise 's' was pressed and we need to display crouching
			if @key == 0
				@cur_image = (milliseconds / 175 % 2 == 0) ? @walker1 : @walker2
			else 
				@cur_image = (milliseconds / 175 % 2 == 0) ? @crouch1 : @crouch2
			end
			# make the bird flap its wings
			@curBird = (milliseconds / 175 % 2 == 0) ? @bird1 : @bird2
			######################################################
			# increment the score each iteration and update the scoreOut string
			@score += 1
			@scoreOut = "Score: " + @score.to_s
			#####################################################
			# if vy is less than 0 we are currently jumping, so display jumping sprite
			if (@vy < 0)
			  @cur_image = @jump
			end
			####################################################
			# Acceleration/gravity
			# By adding 1 each frame, and (ideally) adding vy to y, the player's
			# jumping curve will be the parabole we want it to be.
			@vy += 1
			# Vertical movement
			if @vy > 0 && @y < 300 then
			  @vy.times { @y += 1 }
			end
			if @vy <= 0 then
			  (-@vy).times {@y -= 1}
			end
			####################################################
		end
	end
  end

  def draw
  ############################################
  # draw all of our characters and sprites
	@floor.draw(@dec,308,0)
	@floor.draw(@dec - 1233,308,0)
	@cloud1.draw(@c1Dec, @c1Y, 0)
	@cloud2.draw(@c2Dec, @c2Y, 0)
	@cloud2.draw(@c3Dec, @c3Y, 0)
	@smallCacti.draw(@sDec, 308, 0)
	@bigCacti.draw(@bDec, 308, 0)
	@cur_image.draw(@x - 25, @y, 0, 1, 1.0)
	@curBird.draw(@bX, @bY, 0, 1, 1.0)
	#########################################
	# if the game is going put the score in top right corner, otherwise game is over and display
	# it in largely in the screen with instructions
	if @game == true
		@scoreText.draw(@scoreOut, 1125, 0, 1, 1.0, 1.0, Gosu::Color::WHITE)
	else
		@scoreTextEnd.draw(@scoreOut, 400, 150, 1, 1.0, 1.0, Gosu::Color::WHITE)
		@escape.draw("Press 'Esc' to quit or 'r' to restart!", 415, 240, 1, 1.0, 1.0, Gosu::Color::WHITE)
	end
	########################################
	# if we need to display the intro and "Go!"
	if @introCheck == 0 
		if @counter >= 170
			@escape.draw(@intro, 615, 240, 1, 1.0, 1.0, Gosu::Color::WHITE)
		else
			@escape.draw(@intro, 375, 240, 1, 1.0, 1.0, Gosu::Color::WHITE)
		end
	end
    
  end

  def button_down(id)
  ##################################
  # if we press 'w' then we need to either stand up or jump, but only if we are on the ground
    if id == KbW && @y == 313
		if @key == 1
			@key = 0
		else 
			@vy = -20
		end
    end
	###############################
	# if 'Esc' is pressed we need to close out of the game
    if id == KbEscape then close end
	###############################
	# if we press 'r' then we need to restart the game
	if id == KbR 
		initialize()
	end
	###############################
	# if we press 's' then we need to crouch, but only do so if on or very close to the ground
	if id == KbS and @y >= 310
		@key = 1
	end
  end
end

Game.new.show
