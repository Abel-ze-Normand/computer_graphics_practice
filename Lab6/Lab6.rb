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
def threepointpers1 teta, phi, l, m, n, r
  [[cos(teta), sin(teta)*sin(phi), 0, -r*sin(teta)*cos(phi)],
   [0, cos(phi), 0, r*sin(phi)],
   [sin(teta), -cos(teta)*sin(phi), 0, r*cos(teta)*cos(phi)],
   [l, m, 0, n*r + 1]]
end
def threepointpers teta, phi, l, m, n, r
  t1 = [[cos(teta), 0, -sin(teta), 0],
        [0, 1, 0, 0],
        [sin(teta), 0, cos(teta), 0],
        [0, 0, 0, 1]]
  t2 = [[1, 0, 0, 0],
        [0, cos(phi), sin(phi), 0],
        [0, -sin(phi), cos(phi), 0],
        [0, 0, 0, 1]]
  t3 = [[1, 0, 0, 0],
        [0, 1, 0, 0],
        [0, 0, 1, 0],
        [l, m, n, 1]]
  t4 = [[1, 0, 0, 0],
        [0, 1, 0, 0],
        [0, 0, 1, 1.0/r],
        [0, 0, 0, 1]]
  t = multmatr t1, t2
  t = multmatr t, t3
  multmatr t, t4
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
    normalize new_points
  end

  def original
    @current_points = @orig_points
  end

  def draw_projection proj, vert, phi=nil, psi=nil, l=nil, m=nil, n=nil, k=nil
    t_matr = case proj
             when :front
               FRONT_PROJ
             when :left
               LEFT_PROJ
             when :bottom
               BOTTOM_PROJ
             when :threepoint
               threepointpers phi, psi, l, m, n, k
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

Shoes.app :width => 850, :height => 550, :title => "LAB6" do
  def redraw t_matr=Figure::I, vert=nil
    @img1.path = @fig.draw_projection :threepoint, vert, @phi, @psi, @l, @m, @n, @k
    @img2.path = @fig.draw_projection :front, vert
    cleartmp @file_location
  end
  @psi = 0
  @phi = 0
  @l = 100
  @m = 100
  @n = 100
  @k = 100
  @openfile = button "Load"
  flow :width => "100%" do
    @img1 = image "./", :margin => 10, :width => "50%"
    @img2 = image "./", :margin => 10, :width => "50%"
    inscription "<phi (horizontal)"
    flow :width => 150 do
      @phibtnm = button "--"
      @phi_edit = edit_line :width => 40, :text => "0", :state => "readonly"
      @phibtnp = button "++"
    end
    inscription "<psi (around Ox)"
    flow :width => 150 do
      @psibtnm = button "--"
      @psi_edit = edit_line :width => 40, :text => "0", :state => "readonly"
      @psibtnp = button "++"
    end
    inscription "shift"
    flow :width => 200 do
      stack :width => "30%" do
        @lplus = button "+"
        @l_edit = edit_line :width => 40, :text => @l.to_s, :state => "readonly"
        @lminus = button "-"
      end
      stack :width => "30%" do
        @mplus = button "+"
        @m_edit = edit_line :width => 40, :text => @m.to_s, :state => "readonly"
        @mminus = button "-"
      end
      stack :width => "30%" do
        @nplus = button "+"
        @n_edit = edit_line :width => 40, :text => @n.to_s, :state => "readonly"
        @nminus = button "-"
      end
    end
    inscription "k coord"
    stack :width => 50 do
      @kplus = button "+"
      @k_edit = edit_line :width => 40, :text => 5, :state => "readonly"
      @kminus = button "-"
    end
  end
  @openfile.click do
    @file_location = ask_open_file
    main_img = ChunkyPNG::Image.new(400, 400, ChunkyPNG::Color::WHITE)
    @fig = Figure.new @file_location, main_img
    redraw Figure::I
  end
  @phibtnm.click do
    @phi = @phi_edit.text.to_f
    @phi -= 1
    @phi_edit.text = @phi.to_s
    @phi = @phi * Math::PI / 180
    redraw 
  end
  @phibtnp.click do
    @phi = @phi_edit.text.to_f
    @phi += 1
    @phi_edit.text = @phi.to_s
    @phi = @phi * Math::PI / 180
    redraw 
  end
  @psibtnp.click do
    @psi = @psi_edit.text.to_f
    @psi += 1
    @psi_edit.text = @psi.to_s
    @psi = @psi * Math::PI / 180
    redraw 
  end
  @psibtnm.click do
    @psi = @psi_edit.text.to_f
    @psi -= 1
    @psi_edit.text = @psi.to_s
    @psi = @psi * Math::PI / 180
    redraw 
  end
  @lplus.click do
    @l = @l_edit.text.to_f
    @l += 1
    @l_edit.text = @l.to_s
    redraw
  end
  @lminus.click do
    @l = @l_edit.text.to_f
    @l -= 1
    @l_edit.text = @l.to_s
    redraw
  end
  @mplus.click do
    @m = @m_edit.text.to_f
    @m += 1
    @m_edit.text = @m.to_s
    redraw
  end
  @mminus.click do
    @m = @m_edit.text.to_f
    @m -= 1
    @m_edit.text = @m.to_s
    redraw
  end
  @nplus.click do
    @n = @n_edit.text.to_f
    @n += 1
    @n_edit.text = @n.to_s
    redraw
  end
  @nminus.click do
    @n = @n_edit.text.to_f
    @n -= 1
    @n_edit.text = @n.to_s
    redraw
  end
  @kplus.click do
    @k = @k_edit.text.to_f
    @k += 1
    @k_edit.text = @k.to_s
    redraw
  end
  @kminus.click do
    @k = @k_edit.text.to_f
    @k -= 1
    @k_edit.text = @k.to_s
    redraw
  end
end
