Shoes.setup do
  gem 'chunky_png'
  gem 'tty'
end
require 'chunky_png'
require 'Matrix'
require 'tty'
def trans new_img, orig_img, t_matrix, method = :close_pixel, prog
  for y in (0...new_img.height)
    for x in (0...new_img.width)
      color = interpolate x, y, method, orig_img, t_matrix
      if color then new_img[x, y] = color end
      prog.fraction = (y * new_img.width + x).to_f/(new_img.height * new_img.width)
    end
  end
  return new_img
end
def new_matr arr
  m = Matrix[]
  arr.each {|a| m = Matrix.rows(m.to_a << a)}
  return m
end
def closest x, y
  return x.round, y.round  
end
def interpolate newx, newy, method, orig_img, matr
  if method == :close_pixel then
    x, y = backtrans newx, newy, matr
    x, y = closest x, y
    if x >= orig_img.width-1 || y >= orig_img.height-1 || x < 0 || y < 0 then return nil end
    return orig_img[x, y]
  else
    x, y = backtrans newx, newy, matr
    if x >= orig_img.width-1 || y >= orig_img.height-1 || x < 0 || y < 0 then return nil end
    x1 = x.floor
    x2 = x.ceil
    y1 = y.floor
    y2 = y.ceil
    if x1 < 0 || y1 < 0 || x2 >=orig_img.width || y2 >=orig_img.width then return nil end
    a = orig_img[x1, y1]
    b = orig_img[x2, y1]
    c = orig_img[x2, y2]
    d = orig_img[x1, y2]
    aa = x - x1
    bb = y - y1
    cl = ChunkyPNG::Color.rgb(ChunkyPNG::Color.r(a) + (bb*(ChunkyPNG::Color.r(d) - ChunkyPNG::Color.r(a))).floor, ChunkyPNG::Color.g(a) + (bb*(ChunkyPNG::Color.g(d) - ChunkyPNG::Color.g(a))).floor, ChunkyPNG::Color.b(a) + (bb*(ChunkyPNG::Color.b(d) - ChunkyPNG::Color.b(a))).floor)
    cr = ChunkyPNG::Color.rgb(ChunkyPNG::Color.r(b) + (bb*(ChunkyPNG::Color.r(c) - ChunkyPNG::Color.r(b))).floor, ChunkyPNG::Color.g(b) + (bb*(ChunkyPNG::Color.g(c) - ChunkyPNG::Color.g(b))).floor, ChunkyPNG::Color.b(b) + (bb*(ChunkyPNG::Color.b(c) - ChunkyPNG::Color.b(b))).floor)
    color = ChunkyPNG::Color.rgb(ChunkyPNG::Color.r(cl) + (aa*(ChunkyPNG::Color.r(cr) - ChunkyPNG::Color.r(cl))).floor, ChunkyPNG::Color.g(cl) + (aa*(ChunkyPNG::Color.g(cr) - ChunkyPNG::Color.g(cl))).floor, ChunkyPNG::Color.b(cl) + (aa*(ChunkyPNG::Color.b(cr) - ChunkyPNG::Color.b(cl))).floor)
    return color
  end
end
def backtrans x, y, matr
  m = new_matr(matr).inverse
  coords = [x, y, 1]
  coords = mult coords, m.to_a
  return coords[0]/coords[2], coords[1]/coords[2]
end
def cos phi
  Math.cos phi
end
def sin phi
  Math.sin phi
end
def cleartmp path
  new_path = path[0..path.rindex('/')] 
  list = Dir.entries new_path
  list.each do |flname|
    File.delete(new_path + flname) if /[0-9]+new.\png/ =~ flname
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
Shoes.app :title => "LAB4", :width=>1200, :height=>650, :resize=>false do
  flow do #control bar
    @margin = 10
    stack :width => "100%" do
      @control1 = flow do
        @btn_open = button("Load image")
        @btn_1 = button("Move horizontally")
        @edit1 = edit_line :width => 50, :margin_top => 2
        @btn_2 = button("Scale by CD")
        @edit2 = edit_line :width => 50, :margin_top => 2
        @btn_3 = button("Shift for CD")
        @edit3 = edit_line :width => 50, :margin_top => 2
        @btn_4 = button("Mirror around C")
        @btn_5 = button("Rotate around A")
        @edit4 = edit_line :width => 50, :margin_top => 2
        inscription "degrees"
        @btn_restore = button("Original")
      end
      @control2 = flow do
        @chk = check
        inscription "Reverse"
        @bilinear = check :checked => true
        inscription "Bilinear interpolation"
        @prog = progress :margin_left => 20
      end
      @xrange = inscription "from to"
      @yrange = inscription "from to"
      @cd = flow do
      end
    end
    @orig_slot = stack :width => "100%", :margin_bottom => 10 do
      background green
      para "Original:"
      @orig_pic_slot = stack :margin_top => 0, :margin_left => @margin, :width => "100%" do
        @original = image :margin => 0
        fill red
        @c = oval :top => 0, :left => 0, :radius => 4
        fill yellow
        @d = oval :top => 0, :left => 0, :radius => 4
        para "Blue is A, Red is C, Yellow is D"
      end
    end
    stack :width => "100%" do
      border red, strokewidth: 3
      stack :margin_top => 0, :margin_left => @margin do
        para "Result:"
        @new_pic_slot = stack do
          @newimage = image :path => "./", :margin_bottom => 10
          fill blue
          @a = oval :top => 0, :left => 0, :radius => 4
        end
      end
    end
    para "Total matrix:", :margin => 10
    @matr_txt = edit_box :margin => 10
    para "Current matrix:", :margin => 10
    @currmatr_txt = edit_box :margin => 10
  end
    #open picture dialog
    @btn_open.click do
      @orig_img_path = ask_open_file
      @original.path = @orig_img_path
      @ax = 0
      @ay = 0
      @cx = 0
      @cy = 0
      @dx = 0
      @dy = 0
      @xrange.text = "X from 0 to #{@original.full_width}"
      @yrange.text = "Y from 0 to #{@original.full_height}"
      #@orig_slot.append { para @orig_img_path }
      @newimage.path = @orig_img_path      
      @cd.clear
      @cd.append do
        inscription "C: (#{@cx}, #{@cy})"
        inscription "D: (#{@dx}, #{@dy})"
      end
      @matrix = [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]]
    end
    #click on 
    @orig_pic_slot.click do |but, x, y|
      if but == 1 then
        @cx = x - @orig_pic_slot.left - @margin 
        @cy = y - @orig_pic_slot.top - @orig_slot.top 
        @c.move @cx, @cy 
      elsif but == 2 then
        @dx = x - @orig_pic_slot.left - @margin 
        @dy = y - @orig_pic_slot.top - @orig_slot.top 
        @d.move @dx, @dy
      end
      @cd.clear
      @cd.append do
        inscription "C: (#{@cx}, #{@cy})"
        inscription "D: (#{@dx}, #{@dy})"
      end
    end
    @new_pic_slot.click do |but, x, y|
      @ax = x - @orig_pic_slot.left - @margin
      @ay = y - @orig_pic_slot.top - @orig_slot.height - @orig_pic_slot.height + @original.full_height  - @control1.top - @control2.top - @orig_slot.top + 80- @margin
      @a.move @ax, @ay
    end
    @btn_restore.click do
      @newimage.path = @orig_img_path
      @matr_txt.text = printmatr [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
      @matrix = [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]]
    end
    #shift
    @btn_1.click do
      dx = @chk.checked? ? -@edit1.text.to_f : @edit1.text.to_f
      t_matrix = [[1, 0, 0], [0, 1, 0], [dx, 0, 1]]
      @matrix = multmatr @matrix, t_matrix
      render t_matrix
    end
    #scale
    @btn_2.click do
      size = @chk.checked? ? 1.0/@edit2.text.to_i : @edit2.text.to_i
      t_matrix1 = [[1, 0, 0], [0, 1, 0], [-@cx, -@cy, 1]]
      angle = Math::PI/2 - Math.atan(((@dy - @cy).to_f/(@dx - @cx)))
      t_matrix2 = [[cos(angle), sin(angle), 0], [-sin(angle), cos(angle), 0], [0, 0, 1]]
      t_matrix3 = [[1, 0, 0], [0, size, 0], [0, 0, 1]]
      t_matrix4 = [[cos(-angle), sin(-angle), 0], [-sin(-angle), cos(-angle), 0], [0, 0, 1]]
      t_matrix5 = [[1, 0, 0], [0, 1, 0], [@cx, @cy, 1]]
      t = multmatr t_matrix1, t_matrix2
      t = multmatr t, t_matrix3
      t = multmatr t, t_matrix4
      t = multmatr t, t_matrix5
      @matrix = multmatr @matrix, t
      render t
    end
    @btn_3.click do
      shift = @chk.checked? ? -@edit3.text.to_i : @edit3.text.to_i
      t_matrix1 = [[1, 0, 0], [0, 1, 0], [-@cx, -@cy, 1]]
      angle = Math::PI/2 - Math.atan(((@dy - @cy).to_f/(@dx - @cx)))
      t_matrix2 = [[cos(angle), sin(angle), 0], [-sin(angle), cos(angle), 0], [0, 0, 1]]
      t_matrix3 = [[1, shift, 0], [0, 1, 0], [0, 0, 1]]
      t_matrix4 = [[cos(-angle), sin(-angle), 0], [-sin(-angle), cos(-angle), 0], [0, 0, 1]]
      t_matrix5 = [[1, 0, 0], [0, 1, 0], [@cx, @cy, 1]]
      t = multmatr t_matrix1, t_matrix2
      t = multmatr t, t_matrix3
      t = multmatr t, t_matrix4
      t = multmatr t, t_matrix5
      @matrix = multmatr @matrix, t
      render t
    end
    @btn_4.click do
      t_matrix1 = [[1, 0, 0], [0, 1, 0], [-@cx, -@cy, 1]]
      t_matrix2 = [[-1, 0, 0], [0, -1, 0], [0, 0, 1]]
      t_matrix3 = [[1, 0, 0], [0, 1, 0], [@cx, @cy, 1]]
      t = multmatr t_matrix1, t_matrix2
      t = multmatr t, t_matrix3
      @matrix = multmatr @matrix, t
      render t
    end
    @btn_5.click do
      angle = (@chk.checked? ? -@edit4.text.to_i : @edit4.text.to_i) * Math::PI / 180
      t_matrix1 = [[1, 0, 0], [0, 1, 0], [-@ax, -@ay, 1]]
      t_matrix2 = [[cos(angle), sin(angle), 0], [-sin(angle), cos(angle), 0], [0, 0, 1]]
      t_matrix3 = [[1, 0, 0], [0, 1, 0], [@ax, @ay, 1]]
      t = multmatr t_matrix1, t_matrix2
      t = multmatr t, t_matrix3
      @matrix = multmatr @matrix, t
      render t
    end
    def render t
      method = @bilinear.checked? ? :bilinear : :close_pixel
      orig_img = ChunkyPNG::Image.from_file(@orig_img_path)
      new_img = ChunkyPNG::Image.new(@original.full_width, @original.full_height, ChunkyPNG::Color::WHITE)
      @new_img_path = @orig_img_path[0..@orig_img_path.rindex('/')] + Time.new.getutc.to_i.to_s + 'new.png'
      thread = Thread.new { new_img = trans new_img, orig_img, @matrix, method, @prog }
      thread.join
      new_img.save @new_img_path
      @newimage.path = @new_img_path
      cleartmp @new_img_path
      @matr_txt.text = printmatr @matrix
      @currmatr_txt.text = printmatr t
    end
end
