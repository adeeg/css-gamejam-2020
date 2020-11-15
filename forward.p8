pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

-- consts
const_screen_size = 128
const_debug       = true
const_menu_start  = 0
const_menu_game   = 1
const_menu_end    = 2

-- game
-- 0 = start, 1 = game, 2 = end
menu        = 0
playing     = false
floor_level = 10 * 6.5

-- camera stuff
cam_x = 0.0
cam_y = 0.0

-- map stuff
spikes = {{10*8, 2*8, true}, {15*8, 2*8, true}}

-- player loc
ply_x       = 50.0
ply_y       = 60.0
ply_force_y = 0.0
ply_health  = 5

-- drawing frames
tot_frames      = 0
frame_ply_legs  = 0
frames_ply_legs = {0, 1, 2, 1, 0, 3, 4, 3}
-- frames_ply_legs = {}
-- frames_ply_legs[0] = 0
-- frames_ply_legs[1] = 1
-- frames_ply_legs[2] = 2

-- ranges between 0 -> 1
-- -1.0 = full left
-- 0.0 = equilibrium
-- 1.0 = full right
tilt      = 0.0
tilt_eq   = 0.0
tilt_min  = -1.0
tilt_max  = 1.0
tilt_tick = 0.001

function update_tilt()
  -- get squared distance for change,
  -- i.e. tilt more when ur further out
  tilt_d = (abs(tilt_eq - tilt) ^ 2) / 20

  if tilt > tilt_eq then
    -- tilt right more if we are already tilting
    tilt   = min(tilt + tilt_d, tilt_max)
  elseif tilt < tilt_eq then
    -- tilt left more if we are already tilting
    tilt   = max(tilt - tilt_d, tilt_min)
  else
    -- don't change our tilt if we're in equilibrium
  end
end

function update_spikes()
  for s in all (spikes) do
    if s[3] and (ply_x + 20 >= s[1]) then
      -- make fall
      s[2] += 2
      s[1] += (rnd(2) - 1) * 2
      if s[2] > const_screen_size then
        s[3] = false
      end

      -- check collision w/ player's head
      -- if point_within(ply_x, ply_y, ply_x + 10, ply_y - 10, s[1], s[2]) then
      --   health -= 1
      -- end
      --rect(s[1]+3, s[2], s[1] + 12, s[2] + 15)
      --if rect_within_ply_head(s[1]+3, s[2], 12, 15) then
      if rect_within_ply_head(s[1]+3, s[2], 12, 15) then
        ply_health -= 1
        s[3] = false
      end
    end
  end
end

-- checks if a, b is within x1->x2, y1->y2
function point_within(x1, y1, x2, y2, a, b)
  return (x1 < a and a < x2) and (y1 < b and b < y2)
end

function rect_within(x1, y1, w1, h1, a1, b1, w2, h2)
  return (x1 < (a1 + w2)) and ((x1 + w1) > a1)
     and (y1 < (b1 + h2)) and ((y1 + h1) > b1)
end

function rect_within_ply_head(a1, b1, w2, h2)
  local head_x = ply_x + (tilt * 16)
  local x1 = head_x+4 - (tilt * 3)
  local y1 = ply_y - 9
  local w1 = 12 - (tilt * 2)
  --local h1 = -17
  local h1 = -10

  --rect(head_x+4 - (tilt * 3), ply_y - 9, head_x + 12 - (tilt * 2), ply_y - 17)

  return rect_within(x1, y1, w1, h1, a1, b1, w2, h2)
end

-- gets perct. point of interpolate between x, y
function interpolate(x, y, perct)
  return (x - y) * perct
end

function _init()
end

function _update()
  -- input
  if (btn(0)) tilt -= 0.05
  if (btn(1)) tilt += 0.05
  if (btn(2)) ply_force_y += 0.5
  if (btnp(4)) then
    playing = not playing
    menu = const_menu_game
  end

  -- camera
  if (playing) then
    cam_x += 1.0
    ply_x += 1.0
  end

  -- physics
  if (ply_y < floor_level) ply_y += 1
  if (ply_force_y > 0) then
    ply_y -= 2
    ply_force_y -= 0.1
  end
  update_tilt()
  update_spikes()

  -- game end condition
  if ply_health <= 0 then
    menu = 2
  end
end

function draw_char()
  -- draw bottom half of character
  spr(33 + frames_ply_legs[1 + frame_ply_legs] * 2, ply_x, ply_y, 2, 2)
  if (tot_frames % 3 == 0) then
    frame_ply_legs = (frame_ply_legs + 1) % 8
  end
  -- draw top half of character
  for i=0,16 do
    -- print(':'..(ply_x+i), 20, 50+i*8)
    tline(ply_x + i + (tilt * 16), ply_y - 16,
          ply_x + i, ply_y + 16 - 16,
          0.125 * i, 12.0,
          0.0, 0.125)
  end
end

function draw_particle_explosion(x, y, wx, wy, col)
  for i=x,(x+wx) do
    for j=y,(y+wy) do
      if (rnd(5) <= 1) pset(i, j, col)
    end
  end
end

function draw_spikes()
  -- draw player head bounding box
  --local head_x = ply_x + (tilt * 16)
  --rect(head_x+4 - (tilt * 3), ply_y - 9, head_x + 12 - (tilt * 2), ply_y - 17)

  for s in all (spikes) do
    if s[3] then
      spr(72, s[1], s[2], 2, 2)
      -- gotta love magic numbers
      if s[2] > (2 * 8) then
        draw_particle_explosion(s[1]+1, s[2]-1, 14, 2, 6)
      end
      --rect(s[1]+3, s[2], s[1] + 12, s[2] + 15)
    end
  end
end

function draw_gui()
  gui_sec_y = 95
  rectfill(0, gui_sec_y, const_screen_size, const_screen_size, 0)
  line(0, gui_sec_y, const_screen_size, gui_sec_y, 7)

  -- tiltometer gui
  gui_tilt_x = const_screen_size/2
  gui_tilt_y = 116
  gui_tilt_size = 7
  --circ(gui_tilt_x, gui_tilt_y - 15, 16)
  local p2_x = interpolate(0, gui_tilt_size, tilt)
  line(gui_tilt_x, gui_tilt_y, gui_tilt_x - p2_x, gui_tilt_y - gui_tilt_size * 2, 8)
  circ(gui_tilt_x, gui_tilt_y - gui_tilt_size, gui_tilt_size + 3, 7)
  line(gui_tilt_x-6, gui_tilt_y+1, gui_tilt_x + 6, gui_tilt_y+1, 7)
  line(gui_tilt_x-3, gui_tilt_y+2, gui_tilt_x + 3, gui_tilt_y+2, 7)
  print('tiltometer', gui_tilt_x - 18, gui_tilt_y + 7, 7)

  -- health
  spr(14, 10, gui_sec_y + 8, 2, 2)
  print(''..ply_health, 27, gui_sec_y + 13, 7)
  print('health', 8, gui_tilt_y + 7, 7)
end

wind_lines   = {}
wind_lines_n = 10
function draw_wind()
  for i=1,wind_lines_n do
    local wind_l = wind_lines[i]
    if wind_l == nil then
      -- init wind line
      wind_lines[i] = {rnd(const_screen_size), rnd(const_screen_size),
                        rnd(5), 0}
    else
      -- update wind line
      local wind_x = wind_l[1]
      local wind_y = wind_l[2]
      local wind_w = wind_l[3]
      local wind_t = wind_l[4]

      -- increase time
      wind_lines[i][4] += 1
      wind_lines[i][1] -= 2
      wind_lines[i][3] -= 1

      line(wind_x, wind_y, wind_x + wind_w, wind_y, 7)

      if wind_w <= 0 then
        -- reset/free wind line
        --wind_lines[i] = {0, 0, 0, 0}
        wind_lines[i] = {rnd(const_screen_size), rnd(const_screen_size),
                        rnd(40), 0}
      end
    end
  end
end

function _draw()
  if menu == const_menu_game then
    cls()

    draw_wind()
    camera(cam_x, cam_y)

    map(0, 0, 0, 0, 100, 100)

    draw_char()
    draw_spikes()

    camera()

    -- gui section
    draw_gui()

    -- debug prints
    if debug then
      print('tilt: '..tilt, 0, 0, 7)
    end

    tot_frames += 1
  elseif menu == const_menu_start then
    cls()
    rectfill(77, 76, 30, 56, 8)
    print('stretch', 40, 64, 7)
  elseif menu == const_menu_end then
    cls()
    rectfill(77, 76, 30, 56, 8)
    print('lose', 40, 64, 7)
  end
end

__gfx__
00000000000000444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000424ee40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007770007770000
000000000000061ee710000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000078887078887000
0000000000000eeeeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000788778788888700
0000000000000eee0ee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000787888888888700
00000000000002eeee20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000787788888888700
000000000000048ee840000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000787888888808700
0000000000028882e888200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000788888888808700
0000000002e888882888822000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000078878888087000
000000002ee88888888882ee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007888880870000
000000002ee88888888882ee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000788888700000
00000000eee8888888888eee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000078087000000
00000000eee8888888888eee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007870000000
00000000eee2888888882eee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000
000000002ee22882222822ee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000eee7766666777eee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000e2e1111111111e2ee2e1111111111e20e2e1111111111000e2e1111111111e2ee001111111111e2e0000000000000000000000000000000000000000
00000000e2e1111111111e20e2e1111111111000e2e11111111110000201111111111e200001111111111e200000000000000000000000000000000000000000
00000000020111176111100002011117611110000201111761111000000111176111100000011117611110000000000000000000000000000000000000000000
00000000000776600667700000077660066770000007766006677000000776600667700000077760066770000000000000000000000000000000000000000000
000000000002ee000022e0000002ee000022e0000002ee000022e0000002ee000022e0000002ee000022e0000000000000000000000000000000000000000000
00000000000eee00002ee000000eee00002ee000000eee00002ee000000eee00002ee000000eee00002ee0000000000000000000000000000000000000000000
00000000002eeee002eeee00002eeee002eeee00002eeee000eee000002eeee002eeee00002eeee002eeee000000000000000000000000000000000000000000
00000000002eee2002eee200002eee2002eee200002eee20002eee00002eee2002eee200002eee2002eee2000000000000000000000000000000000000000000
bbbbbbbb000ee20000ee2000000ee20000ee2000000ee20000eee200000ee20000ee2000000ee20000ee20000000000000000000000000000000000000000000
bbbbbbbb0002ee00002ee0000002ee00022ee0000002ee555eee22000002ee00002ee00055e2ee00002ee0000000000000000000000000000000000000000000
bbbbbbbb00022e000022200000022e005522000000022e544eeee20000452e0000222000545ee000002220000000000000000000000000000000000000000000
bbbbbbbb000545000045500000054505445000000005455545222000054450000045500054600000004550000000000000000000000000000000000000000000
bbbbbbbb000545000044500000054505544450000005450546500000054445500044500056000000004450000000000000000000000000000000000000000000
bbbbbbbb000445560044556000044556044650000004455655600000005446500044556055000000004455600000000000000000000000000000000000000000
bbbbbbbb000444650054465000044465005460000004446500000000000555000054465000000000005446500000000000000000000000000000000000000000
bbbbbbbb000555550055555000055555000000000005555500000000000000000055555000000000005555500000000000000000000000000000000000000000
13666561136566630001003033001300000000009000000000000000000011100000d565d6550000000700000000000000000000000000000000000000000000
36ddd5d636dd5d560001001030101000000000008000000011111110000000000000d56dd5dd0000007670000000000000000000000000000000000000000000
365d5d5635d5d5d600010130300110000000000989000000111111111111100000006d6dd5d50000006760000000000000000000000000000000000000000000
35d5d5d6165d5d65000311b03001300000090009a0000000000011100000011100006d6dd6d50000000500000000000000000000000000000000000000000000
365d5d6636d565d600001310003b000000009098a9000000000000000000111100005d65d6550000000400000000000000000000000000000000000000000000
16565656365656550000b010130300000009004a9a0a0000000001111110000000005d55d6500000000400000000000000000000000000000000000000000000
33656663136665630000b0101b033000000000a45a00000000011111111111100000055556d00000000400000000000000000000000000000000000000000000
311113311311133100003033110b30000000005445000000000000000000000000000d565dd00000000500000000000000000000000000000000000000000000
653136665631365600000100100030000000004545000000000000111111100000000d565d000000000400000000000000000000000000000000000000000000
d5636dd5d56365d50000010010031000000000044400000000111111111111100000006d5d000000000500000000000000000000000000000000000000000000
56615d5d5d636d5d0000030b10030000000000645600000000000000000000000000006d5d000000000600000000000000000000000000000000000000000000
d55165d5d56165d50000030311130000000000066000000011000001111000000000006d50000000007070000000000000000000000000000000000000000000
56d36d5d56636d5d00000300b1300000000000054000000000111000000000000000000d60000000000600000000000000000000000000000000000000000000
656355d5656365d500000b0033000000000000055000000011111100011111110000000500000000007070000000000000000000000000000000000000000000
563136666631366600000b0030000000000000000000000000111000000000000000000600000000000000000000000000000000000000000000000000000000
331313333311313300000000b0000000000000000000000000000000011100000000000600000000000000000000000000000000000000000000000000000000
__map__
4041404140414041404140414041404140414041404140414041404140414041404140414040414041404140414041404140414041404140414041404140414041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051505150515051505150515051505150515051505150515051505150515051505150515050515051505150515051505150515051505150515051505150515051000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
574600000000004243ce00000000000046000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
560000000000005253ce00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000005c62635cce644647ce4445000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000004647005c5c5c5c7500ce57475455000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005657560000000000004656cecece000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000072737475ce0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000004600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000565747000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140414041404140414041404140414041404140414041404140414041404140414041404140414041404140414041404140414041505141404140414041404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5150515051505150515051505150515051505150515051505150515051505150515051505150515051505150515051505150515051404151505150515051505100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1112000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2122000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
