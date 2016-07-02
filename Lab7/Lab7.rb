require 'chunky_png'
require 'pry'

def max a, b
  return a > b ? a : b
end

def min a, b
  return a < b ? a : b
end

def cos phi
  Math.cos phi
end

def sin phi
  Math.sin phi
end

def multmatr matr1, matr2
  n = matr1.length
  for i in (0...n)
    matr1[i] = mult matr1[i], matr2
  end
  return matr1
end

def mult vec, matr
  n = vec.length
  newvec = Array.new(n, 0)
  for i in (0...n)
    newvec[i] = (0...n).inject(0) { |memo, j| memo += vec[j] * matr[j][i] }
  end
  return newvec
end

def kx 
  (@x1-@x0).to_f/(@xmax-@xmin)
end

def ky
  (@y1-@y0).to_f/(@ymax-@ymin)
end

def k
  [kx(), ky()].min
end

def trans_x x
  (@x0 + k*(x - @xmin)).floor
end

def trans_y y
  (@y1 - k*(y - @ymin)).floor
end

def btrans_x x
  (x + k * @xmin - @x0)/k
end

def btrans_y y
  (y - k * @ymin - @y1)/k
end

def init_max_min points
  @x0 = 0
  @y0 = 0
  @x1 = @img.width
  @y1 = @img.height    
  @xmin = @ymin = 10**10
  @xmax = @ymax = -10**10
  @pointpairs.each do |key, arr|
    @xmax = arr[0] > @xmax ? arr[0] : @xmax
    @xmin = arr[0] < @xmin ? arr[0] : @xmin
    @ymax = arr[1] > @ymax ? arr[1] : @ymax
    @ymin = arr[1] < @ymin ? arr[1] : @ymin
  end
  @xmin -= 1
  @ymin -= 1
  @xmax += 1
  @ymax += 1
end

def cleartmp path
  new_path = path[0..path.rindex('/')] 
  list = Dir.entries new_path
  list.each do |flname|
    File.delete(new_path + flname) if /new.\png/ =~ flname
  end
end

def open_file file_loc
  @pointpairs = {}
  @verticles = []
  File.open file_loc do |file|
    n = file.gets.to_i
    n.times {|i| @pointpairs[i] = file.gets.split.map {|item| item.to_f}}
    n = file.gets.to_i
    n.times {|pair| @verticles << file.gets.split.map {|item| item.to_i}}
  end
  #@x0 = 0
  #@y0 = 0
  #@x1 = @img.width
  #@y1 = @img.height    
  #debug @path
  #debug(@pointpairs.inspect)
  #debug(@verticles.inspect)
  #draw img, file_loc
end

def intersection p11, p12, p21, p22
  x1, x2, x3, x4, y1, y2, y3, y4 = p11[0], p12[0], p21[0], p22[0], p11[1], p12[1], p21[1], p22[1]
  if ((x4-x3)*(y1-y3)-(y4-y3)*(x1-x3)) == 0 && ((y4-y3)*(x2-x1)-(x4-x3)*(y2-y1)) == 0 then return :equal end
  if ((y4-y3)*(x2-x1)-(x4-x3)*(y2-y1)) == 0 then return :parallel end
  ua = ((x4-x3)*(y1-y3)-(y4-y3)*(x1-x3)).to_f/((y4-y3)*(x2-x1)-(x4-x3)*(y2-y1))
  ub = ((x2-x1)*(y1-y3)-(y2-y1)*(x1-x3)).to_f/((y4-y3)*(x2-x1)-(x4-x3)*(y2-y1))
  if (0 < ua && ua <= 1) && (0 < ub && ub <= 1)
    x = x1 + ua*(x2-x1)
    y = y1 + ua*(y2-y1)
    return [x, y]
  else
    return :nocross
  end
end

def drawpolygon points, new_img, color, color_nodes
    p1 = points.first[1]
    points.each do |key, pair|
      if pair == points.first[1] then next end
      p2 = pair
      x1 = p1[0]
      y1 = p1[1]
      x2 = p2[0]
      y2 = p2[1]
      x1, y1, x2, y2 = trans_x(x1), trans_y(y1), trans_x(x2), trans_y(y2)
      #debug("#{x1} #{y1} #{x2} #{y2}")
      new_img.line x1, y1, x2, y2, color
      new_img.circle(x1, y1, 2, color_nodes, color_nodes)
      new_img.circle(x2, y2, 2, color_nodes, color_nodes)
      p1 = pair 
    end
    begin #connect first and last points
      p2 = points.first[1]
      x1 = p1[0]
      y1 = p1[1]
      x2 = p2[0]
      y2 = p2[1]
      x1, y1, x2, y2 = trans_x(x1), trans_y(y1), trans_x(x2), trans_y(y2)
      #debug("#{x1} #{y1} #{x2} #{y2}")
      new_img.line x1, y1, x2, y2, color
    end
end


def inside? p1, p2
  a = 0b0000
  b = 0b0000
  if p1[0] < @lx then a |= 0b1000 end
  if p1[0] > @rx then a |= 0b0100 end
  if p1[1] < @by then a |= 0b0010 end
  if p1[1] > @uy then a |= 0b0001 end

  if p2[0] < @lx then b |= 0b1000 end
  if p2[0] > @rx then b |= 0b0100 end
  if p2[1] < @by then b |= 0b0010 end
  if p2[1] > @uy then b |= 0b0001 end
  
  val1 = a & b
  val2 = a | b
  if val1 == val2 then 
    if val1 == 0b0000 && val2 == 0b0000 then return true 
    else return false
    end
  end
  return nil
end

def point_inside p
  return @lx <= p[0] && p[0] <= @rx && @by <= p[1] && p[1] <= @uy
end

def going_inside index, p1, p2
  case index
  when 0
    p1[0] <= @lx && @lx <= p2[0]
  when 1
    p1[1] >= @uy && @uy >= p2[1]
  when 2
    p1[0] >= @rx && @rx >= p2[0]
  when 3
    p1[1] <= @by && @by <= p2[1]
  end
end

def visiblepart 
  #@lx, @rx, @by, @uy = 1.5, 3.4, -0.5, 2.45
  l = [[@lx, -1000, @lx, 1000], [-1000, @uy, 1000, @uy], [@rx, 1000, @rx, -1000], [1000, @by, -1000, @by]]
  reserve = @pointpairs.values.dup
  #binding.pry
  l.each.with_index do |bounds, index|
    p1 = reserve.first
    @newpoints = []
    reserve << reserve.first
    reserve.each.with_index do |pair, index_1|
      if index_1 == 0 then next end
      p2 = pair
      visibility = case index
                   when 0 
                     if max(p1[0], p2[0]) >= @lx && min(p1[0], p2[0]) >= @lx then :fully
                     elsif max(p1[0], p2[0]) >= @lx then :partial
                     else :no
                     end
                   when 1
                     if max(p1[1], p2[1]) <= @uy && min(p1[1], p2[1]) <= @uy then :fully
                     elsif min(p1[1], p2[1]) <= @uy then :partial
                     else :no
                     end
                   when 2
                     if max(p1[0], p2[0]) <= @rx && min(p1[0], p2[0]) <= @rx then :fully
                     elsif min(p1[0], p2[0]) <= @rx then :partial
                     else :no
                     end
                   when 3
                     if max(p1[1], p2[1]) >= @by && min(p1[1], p2[1]) >= @by then :fully
                     elsif max(p1[1], p2[1]) >= @by then :partial
                     else :no
                     end
                   end
      if visibility == :fully then @newpoints << pair
      elsif visibility == :partial
        result = intersection p1, p2, bounds[0..1], bounds[2..3]
        if result == :equal then @newpoints << pair
        elsif result.class == Array then 
          @newpoints << result
          unless @lx <= p1[0] && p1[0] <= @rx && @by <= p1[1] && p1[1] <= @uy || result == p2 || !(@lx <= p2[0] && p2[0] <= @rx && @by <= p2[1] && p2[1] <= @uy) then
            @newpoints << pair
          else
            if going_inside(index, p1, p2) then @newpoints << pair end
            #if intersection(p1, p2, result, p2) == :equal && going_inside(index, p1, p2) then @newpoints << pair end
          end
        end
      end
      #if (res = inside?(p1, p2)) == nil then
      #  #binding.pry
      #  result = intersection p1, p2, bounds[0..1], bounds[2..3]
      #  if result == :equal then @newpoints << pair
      #  elsif result.class == Array then @newpoints << result
      #  end
      #elsif res == true then @newpoints << pair end
      p1 = pair
    end
    reserve = @newpoints.dup
  end
  reserve
end

#open_file "/Users/abelnormand/Desktop/Graphics/polygon.txt"
#binding.pry
#visiblepart

Shoes.app :width => 800, :height => 500, :title => "Lab7" do
  @lx, @rx, @uy, @by = 0.0, 3.0, 3.0, 1.0
  flow :width => "100%" do
    @img = image '.', :width => 400, :height => 400
    stack :width => "50%" do
      @load_button = button "LOAD"
      flow :width => "100%" do
        inscription "Lx:"
        @lx_edit = edit_line :width => 50, :text => @lx.to_s
        inscription "Rx:"
        @rx_edit = edit_line :width => 50, :text => @rx.to_s
        inscription "Uy:"
        @uy_edit = edit_line :width => 50, :text => @uy.to_s
        inscription "By:"
        @by_edit = edit_line :width => 50, :text => @by.to_s
      end
      @apply_button = button "Apply window"
    end
  end
  def draw img, file_loc
      @path = file_loc[0..file_loc.rindex('/')] + Time.new.getutc.to_i.to_s + 'new.png'
      new_img = ChunkyPNG::Image.new(img.width, img.height, ChunkyPNG::Color::WHITE)
      init_max_min @pointpairs
      #debug(@pointpairs.inspect)
      #debug(@verticles.inspect)
      drawpolygon @pointpairs, new_img, ChunkyPNG::Color::BLACK, ChunkyPNG::Color::rgb(0, 0, 0)
      p1 = trans_x @lx
      p2 = trans_y @by
      p3 = trans_x @rx
      p4 = trans_y @uy
      new_img.polygon [[p1, p2], [p1, p4], [p3, p4], [p3, p2]], ChunkyPNG::Color.rgb(128, 255, 0)
      vis = visiblepart.map! {|pair| [trans_x(pair[0]), trans_y(pair[1])]}
      debug "polygon - #{vis.inspect}"
      new_img.polygon vis, ChunkyPNG::Color.rgb(128, 255, 0), ChunkyPNG::Color.rgb(128, 255, 0)
      debug @path
      new_img.save @path
      return @path
  end
  def applywindow
    @lx = @lx_edit.text.to_f
    @rx = @rx_edit.text.to_f
    @uy = @uy_edit.text.to_f
    @by = @by_edit.text.to_f
    debug "CHANGED - #{[@lx, @rx, @by, @uy]}"
  end
  @load_button.click do
    @file_loc = ask_open_file
    open_file @file_loc
    @img.path = draw @img, @file_loc
    cleartmp @file_loc
  end
  @apply_button.click do
    applywindow
    @img.path = draw @img, @file_loc
    cleartmp @file_loc
  end
end
