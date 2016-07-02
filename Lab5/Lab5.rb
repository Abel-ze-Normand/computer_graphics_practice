require 'chunky_png'
require 'Matrix'
require 'tty'
require 'pry'
FRONT_PROJ = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 0], [0, 0, 0, 1]]
LEFT_PROJ = [[0, 0, 0, 0], [0, 1, 0, 0], [-1, 0, 0, 0], [0, 0, 0, 1]]
BOTTOM_PROJ = [[1, 0, 0, 0], [0, 0, 0, 0], [0, -1, 0, 0], [0, 0, 0, 1]]
def cos phi
  Math.cos phi
end
def sin phi
  Math.sin phi
end
def cos_d x
  Math.cos(x * Math::PI / 180.0)
end
def sin_d x
  Math.sin(x * Math::PI / 180.0)
end
sin_teta = 1/Math.sqrt(3)
cos_teta = Math.sqrt(2.0/3)
sin_phi = Math.sqrt(1.0/2)
cos_phi = Math.sqrt(1 - sin_phi**2)
ISOM_PROJ = [[cos_phi, sin_phi * sin_teta, 0 , 1],
             [0, cos_teta, sin_teta, 1],
             [sin_phi, -cos_phi * sin_teta, 0, 1],
             [0, 0, 0, 1]]
def new_matr arr
  m = Matrix[]
  arr.each {|a| m = Matrix.rows(m.to_a << a)}
  return m
end
def atan x
  x.nan? ? 0 : Math.atan(x)
end
def acos x
  x.nan? ? Math::PI/2 : Math.acos(x)
end
def asin x
  x.nan? ? Math::PI/2 : Math.asin(x)
end
def backtrans x, y, matr
  m = new_matr(matr).inverse
  coords = [x, y, z, 1]
  coords = mult coords, m.to_a
  return coords[0]/coords[3], coords[1]/coords[3], coords[2]/coords[3]
end
def cleartmp path
  new_path = path[0..path.rindex('/')] 
  list = Dir.entries new_path
  list.each do |flname|
    File.delete(new_path + flname) if /new.\png/ =~ flname
  end
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
def printmatr matr
  str = ""
  matr.each do |arr|
    temp = "|"
    arr.each do |item|
      temp += "#{item.round(4)}|"
    end
    str += temp + "\n"
  end
  str
end

class Figure
  attr_accessor :verticles, :orig_points, :current_points, :xmin, :xmax, :ymin, :ymax, :y1, :x0, :x1, :new_img_path, :img
  I = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
  def initialize filelocation, image
    @points = {}
    @verticles = {}
    @orig_points = {}
    openfile filelocation
    @current_points = @orig_points
    @img = image
    @x0 = 0
    @y0 = 0
    @x1 = @img.width
    @y1 = @img.height    
  end

  def openfile filelocation
    @new_img_path = filelocation
    File.open(filelocation) do |file|
      n = file.gets.to_i
      n.times {|i| @orig_points[i+1] = file.gets.split.map {|num| num.to_f} << 1.0}
      n = file.gets.to_i
      n.times {|i| @verticles[i+1] = file.gets.split.map {|num| num.to_i}}
    end
  end

  def normalize points
    new_points = {}
    points.each do |key, triple|
      div = triple.last
      new_points[key] = triple.map {|i| i.to_f/div}
    end
    new_points
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
    @xmin = @ymin = 10**10
    @xmax = @ymax = -10**10
    points.each do |key, arr|
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

  def traverse t_matr
    new_points = {}
    @current_points.each {|key, triple| new_points[key] = mult triple, t_matr}
    @current_points = normalize new_points
  end

  def draw t_matr, vert
    @new_img_path = @new_img_path[0..@new_img_path.rindex('/')] + Time.new.getutc.to_i.to_s + 'new.png'
    new_img = ChunkyPNG::Image.new(@img.width, @img.height, ChunkyPNG::Color::WHITE)
    traverse t_matr
    points = projection ISOM_PROJ
    init_max_min points
    @verticles.each do |key, nums|
      x1 = points[nums[0]][0]
      y1 = points[nums[0]][1]
      x2 = points[nums[1]][0]
      y2 = points[nums[1]][1]
      x1, x2, y1, y2 = trans_x(x1), trans_x(x2), trans_y(y1), trans_y(y2)
      new_img.line(x1, y1, x2, y2, ChunkyPNG::Color.rgb(255, 0, 0))
      new_img.circle(x1, y1, 2, ChunkyPNG::Color.rgb(255, 0, 0), ChunkyPNG::Color.rgb(255, 0, 0))
      new_img.circle(x2, y2, 2, ChunkyPNG::Color.rgb(255, 0, 0), ChunkyPNG::Color.rgb(255, 0, 0))
    end
    unless vert.nil? then
      x1 = points[@verticles[vert][0]][0]
      y1 = points[@verticles[vert][0]][1]
      x2 = points[@verticles[vert][1]][0]
      y2 = points[@verticles[vert][1]][1]
      x1, x2, y1, y2 = trans_x(x1), trans_x(x2), trans_y(y1), trans_y(y2)
      new_img.line(x1, y1, x2, y2, ChunkyPNG::Color.rgb(0, 255, 0))
      new_img.circle(x1, y1, 2, ChunkyPNG::Color.rgb(0, 255, 0), ChunkyPNG::Color.rgb(0, 255, 0))
      new_img.circle(x2, y2, 2, ChunkyPNG::Color.rgb(0, 255, 0), ChunkyPNG::Color.rgb(0, 255, 0))
    end
    new_img.save @new_img_path
    return @new_img_path
  end

  def projection t_matr
    new_points = {}
    @current_points.each do |key, triple| 
      new_points[key] = mult(triple, t_matr)
    end
    new_points
  end

  def original
    @current_points = @orig_points
  end

  def draw_projection proj, vert
    t_matr = case proj
             when :front
               FRONT_PROJ
             when :left
               LEFT_PROJ
             when :bottom
               BOTTOM_PROJ
             end
    @new_img_path = @new_img_path[0..@new_img_path.rindex('/')] + Time.new.getutc.to_i.to_s + proj.to_s + 'new.png'
    new_img = ChunkyPNG::Image.new(@img.width, @img.height, ChunkyPNG::Color::WHITE)
    points = projection t_matr
    init_max_min points
    @verticles.each do |key, nums|
      x1 = points[nums[0]][0]
      y1 = points[nums[0]][1]
      x2 = points[nums[1]][0]
      y2 = points[nums[1]][1]
      x1, x2, y1, y2 = trans_x(x1), trans_x(x2), trans_y(y1), trans_y(y2)
      new_img.line(x1, y1, x2, y2, ChunkyPNG::Color.rgb(255, 0, 0))
      new_img.circle(x1, y1, 2, ChunkyPNG::Color.rgb(255, 0, 0), ChunkyPNG::Color.rgb(255, 0, 0))
      new_img.circle(x2, y2, 2, ChunkyPNG::Color.rgb(255, 0, 0), ChunkyPNG::Color.rgb(255, 0, 0))
    end
    unless vert.nil? then
      x1 = points[@verticles[vert][0]][0]
      y1 = points[@verticles[vert][0]][1]
      x2 = points[@verticles[vert][1]][0]
      y2 = points[@verticles[vert][1]][1]
      x1, x2, y1, y2 = trans_x(x1), trans_x(x2), trans_y(y1), trans_y(y2)
      new_img.line(x1, y1, x2, y2, ChunkyPNG::Color.rgb(0, 255, 0))
      new_img.circle(x1, y1, 2, ChunkyPNG::Color.rgb(0, 255, 0), ChunkyPNG::Color.rgb(0, 255, 0))
      new_img.circle(x2, y2, 2, ChunkyPNG::Color.rgb(0, 255, 0), ChunkyPNG::Color.rgb(0, 255, 0))
    end
    new_img.save @new_img_path
    return @new_img_path
  end
end
def redraw t_matr
  @fig.draw t_matr
  @fig.draw_projection :bottom
  @fig.draw_projection :left
  @fig.draw_projection :front
end

#main_img = ChunkyPNG::Image.new(300, 300, ChunkyPNG::Color::WHITE)
#@file_location = Dir.pwd + "/cube.fig"
#@fig = Figure.new @file_location, main_img
#redraw Figure::I


Shoes.app :title => "LAB5", :width =>1100, :height=>700, :resize=>false do
  background gray
  @m00 = 0
  @m01 = 0
  @m02 = 0
  @m03 = 0
  @m10 = 0
  @m11 = 0
  @m12 = 0
  @m13 = 0
  @m20 = 0
  @m21 = 0
  @m22 = 0
  @m23 = 0
  @m30 = 0
  @m31 = 0
  @m32 = 0
  @m33 = 0
  @cust_matr_btn = nil
  flow :margin => 20 do
    stack :width => "30%", :margin => 5 do
      inscription "IMAGE"
      @img = image "./", :margin => 10
      inscription "BOTTOM PROJECTION"
      @bot_img = image "./", :margin => 10
    end
    stack :width => "30%", :margin => 5 do
      inscription "LEFT PROJECTION"
      @left_img = image "./", :margin => 10
      inscription "FRONT PROJECTION"
      @front_img = image "./", :margin => 10
    end
    stack :width => "30%", :margin_left => 40 do
      @btn1 = button "LOAD"
      @btn_original = button "ORIGINAL"
      flow do
        @btn2 = button "SHIFT BY OP"
        @val2 = edit_line :margin_left => 5, :width => 50, :text => 0
      end
      flow do
        @btn3 = button "SCALE BY OP"
        @val3 = edit_line :margin_left => 5, :width => 50, :text => 0
      end
      @btn4 = button "MIRROR AROUND VERTICLE"
      flow do
        @btn5 = button "ROTATE AROUND OP"
        @val5 = edit_line :margin_left => 5, :width => 50, :text => 0
        inscription "degrees"
      end
      flow do
        inscription "P coords:"
        @px_edit = edit_line :margin_right => 5, :width => 50, :text => 0
        @py_edit = edit_line :margin_left => 5, :margin_right => 5, :width => 50, :text => 0
        @pz_edit = edit_line :margin_left => 5, :width => 50, :text => 0
      end
      flow do 
        inscription "Verticle num:"
        @vert_list = list_box
      end
      flow do
        @reverse = check
        inscription "REVERSE"
      end
      @matrix = edit_box
      flow :margin => 5 do
        @m00 = edit_line :width => 50, :margin => 5, :text => "1"
        @m01 = edit_line :width => 50, :margin => 5, :text => "0"
        @m02 = edit_line :width => 50, :margin => 5, :text => "0"
        @m03 = edit_line :width => 50, :margin => 5, :text => "0"
      end
      flow :margin => 5 do
        @m10 = edit_line :width => 50, :margin => 5, :text => "0"
        @m11 = edit_line :width => 50, :margin => 5, :text => "1"
        @m12 = edit_line :width => 50, :margin => 5, :text => "0"
        @m13 = edit_line :width => 50, :margin => 5, :text => "0"
      end
      flow :margin => 5 do
        @m20 = edit_line :width => 50, :margin => 5, :text => "0"
        @m21 = edit_line :width => 50, :margin => 5, :text => "0"
        @m22 = edit_line :width => 50, :margin => 5, :text => "1"
        @m23 = edit_line :width => 50, :margin => 5, :text => "0"
      end
      flow :margin => 5 do
        @m30 = edit_line :width => 50, :margin => 5, :text => "0"
        @m31 = edit_line :width => 50, :margin => 5, :text => "0"
        @m32 = edit_line :width => 50, :margin => 5, :text => "0"
        @m33 = edit_line :width => 50, :margin => 5, :text => "1"
      end
      @cust_matr_btn = button "Apply"
    end
  end
  @btn1.click do
    @file_location = ask_open_file
    main_img = ChunkyPNG::Image.new(300, 300, ChunkyPNG::Color::WHITE)
    @fig = Figure.new @file_location, main_img
    redraw Figure::I
    @vert_list.items = @fig.verticles.keys
  end
  def redraw t_matr, vert=nil
    @img.path = @fig.draw t_matr, vert
    @bot_img.path = @fig.draw_projection :bottom, vert
    @left_img.path = @fig.draw_projection :left, vert
    @front_img.path = @fig.draw_projection :front, vert
    cleartmp @file_location
    @matrix.text = (printmatr t_matr).to_s 
  end
  @cust_matr_btn.click do
    t = []
    4.times { t << [0, 0, 0, 0] }
    t[0][0] = @m00.text.to_f; t[0][1] = @m01.text.to_f; t[0][2] = @m02.text.to_f; t[0][3] = @m03.text.to_f;
    t[1][0] = @m10.text.to_f; t[1][1] = @m11.text.to_f; t[1][2] = @m12.text.to_f; t[1][3] = @m13.text.to_f;
    t[2][0] = @m20.text.to_f; t[2][1] = @m21.text.to_f; t[2][2] = @m22.text.to_f; t[2][3] = @m23.text.to_f;
    t[3][0] = @m30.text.to_f; t[3][1] = @m31.text.to_f; t[3][2] = @m32.text.to_f; t[3][3] = @m33.text.to_f;
    redraw t
  end
  @btn2.click do
    px = @px_edit.text.to_f
    py = @py_edit.text.to_f
    pz = @pz_edit.text.to_f
    shift = @reverse.checked? ? -@val2.text.to_f : @val2.text.to_f
    r = Math.sqrt(px**2 + py**2 + pz**2)
    teta = -atan(pz/px)
    phi = Math::PI/2 - asin(py/r)
    debug("angles = teta: #{teta} phi: #{phi}")
    t_matrix1 = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [-px, -py, -pz, 1]]
    t_matrix2 = [[cos(teta), 0, -sin(teta), 0],
                [0, 1, 0, 0],
                [sin(teta), 0, cos(teta), 0],
                [0, 0, 0, 1]]
    t_matrix3 = [[cos(phi), sin(phi), 0, 0],
                 [-sin(phi), cos(phi), 0, 0],
                 [0, 0, 1, 0],
                 [0, 0, 0, 1]]
    t_matrix4 = [[1, shift, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
    t_matrix5 = [[cos(-phi), sin(-phi), 0, 0],
                 [-sin(-phi), cos(-phi), 0, 0],
                 [0, 0, 1, 0],
                 [0, 0, 0, 1]]
    t_matrix6 = [[cos(-teta), 0, -sin(-teta), 0],
                [0, 1, 0, 0],
                [sin(-teta), 0, cos(-teta), 0],
                [0, 0, 0, 1]]
    t_matrix7 = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [px, py, pz, 1]]
    t = multmatr t_matrix1, t_matrix2
    t = multmatr t, t_matrix3
    t = multmatr t, t_matrix4
    t = multmatr t, t_matrix5
    t = multmatr t, t_matrix6
    t = multmatr t, t_matrix7
    redraw t
  end
  @btn3.click do
    px = @px_edit.text.to_f
    py = @py_edit.text.to_f
    pz = @pz_edit.text.to_f
    scale = @reverse.checked? ? 1.0/@val3.text.to_f : @val3.text.to_f
    r = Math.sqrt(px**2 + py**2 + pz**2)
    teta = -atan(pz/px)
    phi = Math::PI/2 - asin(py/r)
    debug("angles = teta: #{teta} phi: #{phi}")
    t_matrix1 = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [-px, -py, -pz, 1]]
    t_matrix2 = [[cos(teta), 0, -sin(teta), 0],
                [0, 1, 0, 0],
                [sin(teta), 0, cos(teta), 0],
                [0, 0, 0, 1]]
    t_matrix3 = [[cos(phi), sin(phi), 0, 0],
                 [-sin(phi), cos(phi), 0, 0],
                 [0, 0, 1, 0],
                 [0, 0, 0, 1]]
    t_matrix4 = [[1, 0, 0, 0], [0, scale, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
    t_matrix5 = [[cos(-phi), sin(-phi), 0, 0],
                 [-sin(-phi), cos(-phi), 0, 0],
                 [0, 0, 1, 0],
                 [0, 0, 0, 1]]
    t_matrix6 = [[cos(-teta), 0, -sin(-teta), 0],
                [0, 1, 0, 0],
                [sin(-teta), 0, cos(-teta), 0],
                [0, 0, 0, 1]]
    t_matrix7 = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [px, py, pz, 1]]
    t = multmatr t_matrix1, t_matrix2
    t = multmatr t, t_matrix3
    t = multmatr t, t_matrix4
    t = multmatr t, t_matrix5
    t = multmatr t, t_matrix6
    t = multmatr t, t_matrix7
    redraw t
  end
  @btn4.click do
    verticle_num = @vert_list.text.to_i
    v = @fig.verticles[verticle_num]
    p1 = @fig.current_points[v[0]]
    p2 = @fig.current_points[v[1]]
    firstpoint_x = p1[0]
    firstpoint_y = p1[1]
    firstpoint_z = p1[2]
    px = p2[0] - p1[0]
    py = p2[1] - p1[1]
    pz = p2[2] - p1[2]
    r = Math.sqrt(px**2 + py**2 + pz**2)
    teta = -atan(pz/px)
    phi = Math::PI/2 - asin(py/r)
    debug("angles = teta: #{teta} phi: #{phi}")
    t_matrix1 = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [-firstpoint_x, -firstpoint_y, -firstpoint_z, 1]]
    t_matrix2 = [[cos(teta), 0, -sin(teta), 0],
                [0, 1, 0, 0],
                [sin(teta), 0, cos(teta), 0],
                [0, 0, 0, 1]]
    t_matrix3 = [[cos(phi), sin(phi), 0, 0],
                 [-sin(phi), cos(phi), 0, 0],
                 [0, 0, 1, 0],
                 [0, 0, 0, 1]]
    t_matrix4 = [[-1, 0, 0, 0], [0, 1, 0, 0], [0, 0, -1, 0], [0, 0, 0, 1]]
    t_matrix5 = [[cos(-phi), sin(-phi), 0, 0],
                 [-sin(-phi), cos(-phi), 0, 0],
                 [0, 0, 1, 0],
                 [0, 0, 0, 1]]
    t_matrix6 = [[cos(-teta), 0, -sin(-teta), 0],
                [0, 1, 0, 0],
                [sin(-teta), 0, cos(-teta), 0],
                [0, 0, 0, 1]]
    t_matrix7 = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [firstpoint_x, firstpoint_y, firstpoint_z, 1]]
    t = multmatr t_matrix1, t_matrix2
    t = multmatr t, t_matrix3
    t = multmatr t, t_matrix4
    t = multmatr t, t_matrix5
    t = multmatr t, t_matrix6
    t = multmatr t, t_matrix7
    redraw t, verticle_num
  end
  @btn5.click do
    angle = @reverse.checked? ? -@val5.text.to_f : @val5.text.to_f * Math::PI / 180
    px = @px_edit.text.to_f
    py = @py_edit.text.to_f
    pz = @pz_edit.text.to_f
    r = Math.sqrt(px**2 + py**2 + pz**2)
    #n1 = px/r
    #n2 = py/r
    #n3 = pz/r
    #t = [[n1**2 + (1-n1**2)*cos(angle) , n1*n2*(1 - cos(angle))+n1*sin(angle), n1*n3*(1 - cos(angle)) - n2*sin(angle), 0],
    #     [n1*n2*(1 - cos(angle)) - n3*sin(angle), n2**2 + (1-n2**2)*cos(angle), n2*n3*(1 - cos(angle)) + n1*sin(angle), 0],
    #     [n1*n3*(1 - cos(angle)) + n2*sin(angle), n2*n3*(1 - cos(angle)) - n1*sin(angle), n3**2 + (1 - n3**2)*cos(angle), 0],
    #     [0, 0, 0, 1]]
    teta = -atan(pz/px)
    phi = Math::PI/2 - asin(py/r)
    debug("angles = teta: #{teta} phi: #{phi}")
    t_matrix2 = [[cos(teta), 0, -sin(teta), 0],
                [0, 1, 0, 0],
                [sin(teta), 0, cos(teta), 0],
                [0, 0, 0, 1]]
    t_matrix3 = [[cos(phi), sin(phi), 0, 0],
                 [-sin(phi), cos(phi), 0, 0],
                 [0, 0, 1, 0],
                 [0, 0, 0, 1]]
    t_matrix4 = [[cos(angle), 0, -sin(angle), 0],
                [0, 1, 0, 0],
                [sin(angle), 0, cos(angle), 0],
                [0, 0, 0, 1]]
    t_matrix5 = [[cos(-phi), sin(-phi), 0, 0],
                 [-sin(-phi), cos(-phi), 0, 0],
                 [0, 0, 1, 0],
                 [0, 0, 0, 1]]
    t_matrix6 = [[cos(-teta), 0, -sin(-teta), 0],
                [0, 1, 0, 0],
                [sin(-teta), 0, cos(-teta), 0],
                [0, 0, 0, 1]]
    t = multmatr t_matrix2, t_matrix3
    #t = multmatr t, t_matrix3
    t = multmatr t, t_matrix4
    t = multmatr t, t_matrix5
    t = multmatr t, t_matrix6
    #t = multmatr t, t_matrix7
    redraw t
  end
  @btn_original.click do
    @fig.original
    redraw Figure::I
  end
end
