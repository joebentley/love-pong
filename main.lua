

-- global objects
player_paddle = {}
enemy_paddle = {}

paddle = {}

ball = {}

invisible_ball = {}

player_score = 0
enemy_score = 0

pause = false
pause_counter = 0

-- reset all positions
function reset_everything()
  player_paddle.x = 40
  player_paddle.y = (love.graphics.getHeight() - paddle.height) / 2

  enemy_paddle.x = love.graphics.getWidth() - paddle.width - 40
  enemy_paddle.y = (love.graphics.getHeight() - paddle.height) / 2


  ball.x = (love.graphics.getWidth() - ball.width) / 2
  ball.y = (love.graphics.getHeight() - ball.height) / 2
  
  ball.velocity = {}
  ball.velocity.x = 0
  ball.velocity.y = 0



  -- start ball in random direction, towards player
  local angle = love.math.random() * math.pi/6 + math.pi/8
  local facing = math.random(0, 1)

  if facing == 1 then
    angle = -angle
  end

  ball.velocity.x = -math.cos(angle) * ball.speed
  ball.velocity.y = math.sin(angle) * ball.speed

  -- hang for one second
  pause = true
  pause_counter = 30
end


function love.load()
  paddle.image = love.graphics.newImage("gfx/paddle.png")
  paddle.scale = 8
  
  paddle.width = 4 * paddle.scale
  paddle.height = 12 * paddle.scale

  paddle.speed = 500

  
  ball.image = love.graphics.newImage("gfx/ball.png")
  ball.scale = 8
  
  ball.width = 2 * ball.scale
  ball.height = ball.width

  ball.speed = 500
  

  reset_everything()


  -- an invisible ball will be spawned when the player hits the real ball,
  -- the enemy will follow that, faster ball
  -- https://gamedev.stackexchange.com/questions/57352/imperfect-pong-ai
   
  invisible_ball.x = 0
  invisible_ball.y = 0

  invisible_ball.velocity = {}
  invisible_ball.velocity.x = 0
  invisible_ball.velocity.y = 0


  font = love.graphics.newImageFont("gfx/fontwhite.png", "0123456789") 
  font:setFilter("nearest", "nearest")

  love.graphics.setFont(font)

  tink = love.audio.newSource("sfx/tink.wav")
  point = love.audio.newSource("sfx/point.wav")
  enemy_point = love.audio.newSource("sfx/enemy_point.wav")
end


function love.draw()
  -- draw player
  love.graphics.draw(paddle.image, 
      player_paddle.x, player_paddle.y, 0, paddle.scale)

  -- draw enemy
  love.graphics.draw(paddle.image, 
      enemy_paddle.x, enemy_paddle.y, 0, paddle.scale)
  
  -- draw ball
  love.graphics.draw(ball.image, 
      ball.x, ball.y, 0, ball.scale)

  -- draw scoreboard
  love.graphics.print(player_score, 20, 20, 0, 20)
  love.graphics.print(enemy_score, love.graphics.getWidth() - 100, 20, 0, 20)
end


function love.update(dt)

  -- hang if game pause true (used for pause after reset)
  if pause == true then
    pause_counter = pause_counter - 1
    
    if pause_counter == 0 then
      pause = false
    end

    return 0 -- exit function
  end

  if love.keyboard.isDown("up") then
    player_paddle.y = player_paddle.y - (paddle.speed * dt)
  end

  if love.keyboard.isDown("down") then
    player_paddle.y = player_paddle.y + (paddle.speed * dt)
  end

  if _reset == false and love.keyboard.isDown("r") then
    reset_everything()

    _reset = true
  end

  -- stop key repeating
  if not love.keyboard.isDown("r") then
    _reset = false
  end


  -- player and enemy boundaries
  if player_paddle.y < 0 then
    player_paddle.y = 0
  end

  if player_paddle.y + paddle.height > love.graphics.getHeight() then
    player_paddle.y = love.graphics.getHeight() - paddle.height
  end

  if enemy_paddle.y < 0 then
    enemy_paddle.y = 0
  end

  if enemy_paddle.y + paddle.height > love.graphics.getHeight() then
    enemy_paddle.y = love.graphics.getHeight() - paddle.height
  end



  -- ball movement
  ball.x = ball.x + (ball.velocity.x * dt) 
  ball.y = ball.y + (ball.velocity.y * dt) 


  invisible_ball.x = invisible_ball.x + (invisible_ball.velocity.x * dt)
  invisible_ball.y = invisible_ball.y + (invisible_ball.velocity.y * dt)
  
  -- ball collision
  
  -- hitting right side of player paddle
  if ball.y > player_paddle.y and
    ball.y < player_paddle.y + paddle.height and
    ball.x < player_paddle.x + paddle.width then
 
    ball.x = player_paddle.x + paddle.width

    -- reflect ball
    ball.velocity.x = -ball.velocity.x

    -- allow player to add spin to ball
    if love.keyboard.isDown("up") then
      ball.velocity.y = ball.velocity.y - 100
    end

    if love.keyboard.isDown("down") then
      ball.velocity.y = ball.velocity.y + 100
    end

    -- play tink sound
    love.audio.play(tink)

    -- spawn invisible ball that the enemy will follow
    invisible_ball.x = ball.x
    invisible_ball.y = ball.y
    invisible_ball.velocity.x = ball.velocity.x * 1.4
    invisible_ball.velocity.y = ball.velocity.y * 1.4
  end

  -- hitting left side of enemy paddle
  if ball.y > enemy_paddle.y and
    ball.y < enemy_paddle.y + paddle.height and
    ball.x + ball.width > enemy_paddle.x then
    
    ball.x = enemy_paddle.x - ball.width

    ball.velocity.x = -ball.velocity.x

    -- kill invisible ball velocity
    invisible_ball.velocity.x = 0
    invisible_ball.velocity.y = 0
 
    -- play tink sound
    love.audio.play(tink)
  end

  -- ball hitting ceiling or floor
  if ball.y < 0 or (ball.y + ball.height) > love.graphics.getHeight() then
    ball.velocity.y = -ball.velocity.y
    
    love.audio.play(tink)
  end

  -- invisible ball hitting ceiling or floor
  if invisible_ball.y < 0 or (invisible_ball.y + ball.height) > love.graphics.getHeight() then
    invisible_ball.velocity.y = -invisible_ball.velocity.y
  end


  -- enemy ai, only follow invisible ball if it's to the left of enemy
  if invisible_ball.x + ball.width < enemy_paddle.x then
    if invisible_ball.y < enemy_paddle.y + (paddle.height / 2) then
      enemy_paddle.y = enemy_paddle.y - (paddle.speed * dt)
    end

    if invisible_ball.y > enemy_paddle.y + (paddle.height / 2) then
      enemy_paddle.y = enemy_paddle.y + (paddle.speed * dt)
    end
  end


  if ball.x <= 0 then
    enemy_score = enemy_score + 1
    love.audio.play(enemy_point)

    reset_everything()
  end

  if ball.x + ball.width >= love.graphics.getWidth() then
    player_score = player_score + 1
    love.audio.play(point)

    reset_everything()
  end

end


