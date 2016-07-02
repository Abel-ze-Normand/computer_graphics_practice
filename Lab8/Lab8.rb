$LOAD_PATH << '.'
require 'pry'
require 'chunky_png'
require 'json'

class Point 
  attr_accessor :x, :y, :z
  def initialize x, y, z
    @x, @y, @z = x.to_f, y.to_f, z.to_f
  end

  def to_a
    [@x, @y, @z]
  end
end

class Fixnum
  def r
    ChunkyPNG::Color.r(self)
  end
  def g
    ChunkyPNG::Color.g(self)
  end
  def b
    ChunkyPNG::Color.b(self)
  end
  def rgb
    [self.r, self.g, self.b]
  end
end

class Vector < Point

  def normalized?
    (length - 1).abs < 10**-8
  end

  def length
    Math.sqrt(@x**2 + @y**2 + @z**2)
  end

  def normalize
    l = length
    return if l == 1.0
    @x, @y, @z = @x/l, @y/l, @z/l
    [@x, @y, @z].to_vec
  end

  def check_is_vector v
    throw NotVectorEx unless v.class == Vector
  end

  def +(v)
    check_is_vector v
    self.to_a.map.with_index {|c, i| c + v.to_a[i] }.to_vec
  end

  def -(v)
    check_is_vector v
    self.to_a.map.with_index {|c, i| c - v.to_a[i] }.to_vec
  end

  def self.angle (v, s)
    v.check_is_vector v
    (s.x*v.x + s.y*v.y + s.z*v.z)/(s.length * v.length)
  end

  def *(k)
    return multiply_by_scalar k if k.class == Fixnum || k.class == Float
    return multiply_vectors k if k.class == Vector
  end

  def multiply_by_scalar k
    @x, @y, @z = @x*2, @y*2, @z*2
    [@x, @y, @z].to_vec
  end

  def multiply_vectors v
    a = self
    [a.z*v.y - a.y*v.z, a.x*v.z - a.z*v.x, a.y*v.x - a.x*v.y].to_vec
  end
end

class Array
  def to_vec
    Vector.new(self[0], self[1], self[2])
  end

  def to_point
    Point.new(self[0], self[1], self[2])
  end
end

class ModelWithLight
  attr_accessor :coords, :polygons, :normals, :ka, :kd, :ks, :il1, :il2, :l1vec, :l2vec, :v_p, :l1p, :l2p

  #ka - coeffitient of ambient light
  #kd - coeffitient of diffuse light
  #ks - coeffitient of specular light
  def initialize path, img, amb_col, ka, kd, ks, ia, il1, il2, il1_c, il2_c, v_p, n, l1p, l2p, save_path
    str = File.open(path)
    hash = JSON.parse(str.read)
    @coords = hash["coords"]
    @polygons = hash["polygons"]
    @normals = hash["normals"]
    @img = img
    initmaxmin
    @ka, @kd, @ks = ka, kd, ks
    @ia = ia
    @il1 = il1
    @il2 = il2
    @il1_c = il1_c
    @il2_c = il2_c
    @v_p = v_p
    @n = n
    @clos_p_index = closest_point
    @l1p = l1p
    @l2p = l2p
    @save_path = save_path
    @amb_col = amb_col
    @zbuffer = Array.new
    @img.height.times {|i| @zbuffer << Array.new(@img.width) }
    init_z_buffer
  end

  def closest_point
    index = 0
    mindist = 10**10
    @coords.each.with_index do |item, i|
      curr_dist = (@coords[index].to_vec - item.to_vec).length
      if curr_dist < mindist then
        mindist = curr_dist
        index = i
      end
    end
    return index
  end

  def d point
    (point - @coords[@clos_p_index]).length/10.0
  end

  def init_z_buffer
    @zbuffer.map do |arr|
      arr.map {|item| item = -Float::INFINITY}
    end
  end

  #def mainformula normal, p
  #  ambient = ChunkyPNG::Color.rgb(@ia * @ka.r, @ia * @ka.g, @ia * @ka.b)
  #  v1 = @l1p.to_a.to_vec - [p.x, p.y, p.z].to_vec
  #  v2 = @l2p.to_a.to_vec - [p.x, p.y, p.z].to_vec
  #  cos_teta1 = Vector.angle(v1*-1, normal)
  #  cos_teta2 = Vector.angle(v2*-1, normal)
  #  r1 = normal * 2 * Vector.angle(v1, normal) - v1
  #  r2 = normal * 2 * Vector.angle(v2, normal) - v2
  #  v_vec = [@v_p.x - p.x, @v_p.y - p.y, @v_p.z - p.z].to_vec
  #  cos_alpha1 = Vector.angle(r1, v_vec)
  #  cos_alpha2 = Vector.angle(r2, v_vec) 
  #  sum1 = ChunkyPNG::Color.rgb(@kd.r * cos_teta1 + @ks * cos_alpha1**@n)/(1.0 + d(p)),
  #                              @kd.g * cos_teta1 + @ks * cos_alpha1**@n)/(1.0 + d(p)),
  #                              @kd.b * cos_teta1 + @ks * cos_alpha1**@n)/(1.0 + d(p)))
  #  sum2 = ChunkyPNG::Color.rgb(@kd.r * cos_teta2 + @ks * cos_alpha2**@n)/(1.0 + d(p),
  #                              @kd.g * cos_teta2 + @ks * cos_alpha2**@n)/(1.0 + d(p),
  #                              @kd.b * cos_teta2 + @ks * cos_alpha2**@n)/(1.0 + d(p)))
  #  r = ambient.r + @il1 * sum1 + @il2 * sum2 > 255 ? 255 : ambient.r + @il1 * sum1 + @il2 * sum2
  #  g = ambient.g + @il1 * sum1 + @il2 * sum2 > 255 ? 255 : ambient.g + @il1 * sum1 + @il2 * sum2
  #  b = ambient.b + @il1 * sum1 + @il2 * sum2 > 255 ? 255 : ambient.b + @il1 * sum1 + @il2 * sum2
  #  ChunkyPNG::Color.rgb(r, g, b)
  #end
  
  def mainformula normal, p
    #binding.pry
    v1 = @l1p.to_a.to_vec - [p.x, p.y, p.z].to_vec
    v2 = @l2p.to_a.to_vec - [p.x, p.y, p.z].to_vec
    v1.normalize
    v2.normalize
    cos_teta1 = Vector.angle(v1*-1, normal)
    cos_teta2 = Vector.angle(v2*-1, normal)
    r1 = normal * 2 * Vector.angle(v1*-1, normal) - v1
    r2 = normal * 2 * Vector.angle(v2*-1, normal) - v2
    v_vec = Vector.new(0, 0, -1) #[@v_p.x - p.x, @v_p.y - p.y, @v_p.z - p.z].to_vec
    cos_alpha1 = Vector.angle(r1, v_vec)
    cos_alpha2 = Vector.angle(r2, v_vec) 
    r = intencity(@ia, @amb_col.r, @il1, @il1_c.r, @il2, @il2_c.r, @ka.r, @kd.r, @ks, cos_teta1, cos_teta2, cos_alpha1, cos_alpha2, @n).floor
    g = intencity(@ia, @amb_col.g, @il1, @il1_c.g, @il2, @il2_c.g, @ka.g, @kd.g, @ks, cos_teta1, cos_teta2, cos_alpha1, cos_alpha2, @n).floor
    b = intencity(@ia, @amb_col.b, @il1, @il1_c.b, @il2, @il2_c.b, @ka.b, @kd.b, @ks, cos_teta1, cos_teta2, cos_alpha1, cos_alpha2, @n).floor
    ChunkyPNG::Color.rgb(r, g, b)
  end

  def intencity ia, amb_col, id1, i1_c, id2, i2_c, ka, kd, ks, cos_teta1, cos_teta2, cos_alpha1, cos_alpha2, n
    #cos_teta1 = cos_teta1 < 0 ? 0 : cos_teta
    #cos_teta2 = cos_teta2 < 0 ? 0 : cos_teta2
    #cos_alpha1 = cos_alpha1 < 0 ? 0 : cos_alpha1
    #cos_alpha2 = cos_alpha2 < 0 ? 0 : cos_alpha2
    i = ia * amb_col * ka + id1 * i1_c * (kd * cos_teta1 + ks * cos_alpha1**n) + id2 * i2_c * (kd * cos_teta2 + ks * cos_alpha2**n)
    if i < 0 then return 0 end
    return i > 255 ? 255 : i
  end

  def kx
    (@x1 - @x0).to_f/(@xmax - @xmin)
  end

  def ky
    (@y1 - @y0).to_f/(@ymax - @ymin)
  end

  def transx x
    (@x0 + k*(x - @xmin)).floor
  end

  def transy y
    (@y1 - k*(y - @ymin)).floor
  end

  def k
    @k ||=[kx(), ky()].min
  end

  def initmaxmin
    @x0 = 0
    @y0 = 0
    @x1 = @img.width
    @y1 = @img.height
    @xmax = @ymax = -10**10
    @xmin = @ymin = 10**10
    @coords.each do |value|
      @xmax = @xmax < value[0] ? value[0] : @xmax
      @xmin = @xmin > value[0] ? value[0] : @xmin
      @ymax = @ymax < value[1] ? value[1] : @ymax
      @ymin = @ymin > value[1] ? value[1] : @ymin
    end
    @xmin -= 1.0
    @xmax += 1.0
    @ymin -= 1.0
    @ymax += 1.0
  end

  def convert_to_screen_cc p
    Vector.new(transx(p.x), transy(p.y), 0)
  end

  def degenerate_triangle? p1, p2, p3
    (p1.x - p3.x)/(p2.x - p3.x) == (p1.y - p3.y)/(p2.y - p3.y)
  end

  def rasterize_triangle_monotonous polygon_index, color
    p1 = @coords[@polygons[polygon_index][0]].to_point
    p2 = @coords[@polygons[polygon_index][1]].to_point
    p3 = @coords[@polygons[polygon_index][2]].to_point
    #sort
    if p1.y < p2.y then p1, p2 = p2, p1 end
    if p2.y < p3.y then p2, p3 = p3, p2 end
    if p1.y < p3.y then p1, p3 = p3, p1 end

    # x = (x2 - x1)*(y - y1)/(y2 - y1) + x1

    k1 = (p3.x - p2.x)/(p3.x - p2.x)
    k2 = (p3.x - p1.x)/(p3.x - p1.x)
    for i in (p3.y)..(p2.y)
      lx = (k1*(i - p2.y) + p2.x).floor
      rx = (k2*(i - p1.y) + p1.x).floor
      if lx > rx then lx, rx = rx, lx end
      for x in lx..rx
        @img[x, i] = color
      end
    end
  end

  def rasterize_guro polygon_index
    p1 = @coords[@polygons[polygon_index][0]].to_point
    p2 = @coords[@polygons[polygon_index][1]].to_point
    p3 = @coords[@polygons[polygon_index][2]].to_point
    #return if degenerate_triangle? p1, p2, p3

    n1 = @normals[@polygons[polygon_index][0]].to_vec
    n2 = @normals[@polygons[polygon_index][1]].to_vec
    n3 = @normals[@polygons[polygon_index][2]].to_vec

    #if p3.y > p2.y then
    #  p3, p2 = p2, p3
    #  n3, n2 = n2, n3
    #end
    #if p3.y > p1.y then
    #  p3, p1 = p1, p3
    #  n3, n1 = n1, n3
    #end
    #if p2.y > p1.y then
    #  p2, p1 = p1, p2
    #  n2, n1 = n1, n2
    #end
    #
    if p1.y > p2.y then
      p1, p2 = p2, p1
      n1, n2 = n2, n1
    end
    if p1.y > p3.y then
      p1, p3 = p3, p1
      n1, n3 = n3, n1
    end
    if p2.y > p3.y then
      p2, p3 = p3, p2
      n2, n3 = n3, n2
    end

    if p1.z < 0 || p2.z < 0 || p3.z < 0 then return end
    
    #binding.pry

    if p1.y == p3.y then return end #degenerate triangle

    #binding.pry
    i_p1 = mainformula n1, p1
    i_p2 = mainformula n2, p2
    i_p3 = mainformula n3, p3

    p1, p2, p3 = convert_to_screen_cc(p1), convert_to_screen_cc(p2), convert_to_screen_cc(p3)
    
    k1 = (p3.x - p2.x)/(p3.y - p2.y)
    k2 = (p3.x - p1.x)/(p3.y - p1.y)

    full_p1p3 = (p3-p1).to_a.to_vec.length
    full_p2p3 = (p3-p2).to_a.to_vec.length
    for i in (p3.y.floor)..(p2.y.floor) #they are anyway integer
      if k1 == Float::INFINITY || k1 == -Float::INFINITY || k1.nan? then break end
      lx = (k1*(i - p2.y) + p2.x).floor
      rx = (k2*(i - p1.y) + p1.x).floor
      if lx > rx then lx, rx = rx, lx end
      part_p1p3 = ([lx, i, 0].to_vec - [p3.x, p3.y, 0].to_vec).length
      part_p2p3 = ([rx, i, 0].to_vec - [p3.x, p3.y, 0].to_vec).length

      del_p1p3 = part_p1p3/full_p1p3
      del_p2p3 = part_p2p3/full_p2p3

      i_p1p3 = ChunkyPNG::Color.rgb((del_p1p3*i_p1.r + (1 - del_p1p3)*i_p3.r).floor, (del_p1p3*i_p1.g + (1 - del_p1p3)*i_p3.g).floor, (del_p1p3*i_p1.b + (1 - del_p1p3)*i_p3.b).floor)
      i_p2p3 = ChunkyPNG::Color.rgb((del_p2p3*i_p2.r + (1 - del_p2p3)*i_p3.r).floor, (del_p2p3*i_p2.g + (1 - del_p2p3)*i_p3.g).floor, (del_p2p3*i_p2.b + (1 - del_p2p3)*i_p3.b).floor)

      i_l, i_r = nil
      if (p2.x > p1.x) then
        i_l, i_r = i_p1p3, i_p2p3
      else
        i_l, i_r = i_p2p3, i_p1p3
      end

      flag = nil
      #if (p2.y.floor - 40 < i) then
      #  flag = true
      #  binding.pry
      #  p
      #end

      horizontal_length = ([lx, i, 0].to_vec - [rx, i, 0].to_vec).length
      if horizontal_length == 0.0 then next end

      for x in lx..rx
        #binding.pry
        begin
          #binding.pry if flag
          part_length = ([x, i, 0].to_vec - [lx, i, 0].to_vec).length
          del = part_length/horizontal_length
          @img[x, i] = ChunkyPNG::Color.rgb((del*i_r.r + (1 - del)*i_l.r).floor, (del*i_r.g + (1 - del)*i_l.g).floor, (del*i_r.b + (1 - del)*i_l.b).floor)
        rescue
          next
        end
      end
    end
    k1 = (p2.x - p1.x)/(p2.y - p1.y)
    if k1 == Float::INFINITY || k1 == -Float::INFINITY || k1.nan? then return end
    full_p1p2 = (p1-p2).to_a.to_vec.length
    for i in (p2.y.floor)..(p1.y.floor)
      lx = (k1*(i - p1.y) + p1.x).floor
      rx = (k2*(i - p1.y) + p1.x).floor
      if lx > rx then lx, rx = rx, lx end
      part_p1p3 = ([lx, i, 0].to_vec - [p3.x, p3.y, 0].to_vec).length
      part_p1p2 = ([rx, i, 0].to_vec - [p2.x, p2.y, 0].to_vec).length

      del_p1p3 = part_p1p3/full_p1p3
      del_p1p2 = part_p1p2/full_p1p2

      i_p1p3 = ChunkyPNG::Color.rgb((del_p1p3*i_p1.r + (1 - del_p1p3)*i_p3.r).floor, (del_p1p3*i_p1.g + (1 - del_p1p3)*i_p3.g).floor, (del_p1p3*i_p1.b + (1 - del_p1p3)*i_p3.b).floor)
      i_p1p2 = ChunkyPNG::Color.rgb((del_p1p2*i_p1.r + (1 - del_p1p2)*i_p2.r).floor, (del_p1p2*i_p1.g + (1 - del_p1p2)*i_p2.g).floor, (del_p1p2*i_p1.b + (1 - del_p1p2)*i_p2.b).floor)

      i_l, i_r = nil
      if (p2.x > p1.x) then
        i_l, i_r = i_p1p3, i_p1p2
      else
        i_l, i_r = i_p1p2, i_p1p3
      end

      horizontal_length = ([lx, i, 0].to_vec - [rx, i, 0].to_vec).length
      if horizontal_length == 0.0 then next end

      for x in lx..rx
        begin
          part_length = ([x, i, 0].to_vec - [lx, i, 0].to_vec).length
          del = part_length/horizontal_length
          @img[x, i] = ChunkyPNG::Color.rgb((del*i_r.r + (1 - del)*i_l.r).floor, (del*i_r.g + (1 - del)*i_l.g).floor, (del*i_r.b + (1 - del)*i_l.b).floor)
        rescue
          next
        end
      end
    end
  end

  def render method
    case method 
    when "pointwize"

    when "guro"
      @polygons.each.with_index do |triple, index|
        rasterize_guro index
      end
    when "fong"
    end

    @img.save(@save_path)
  end
end

png = ChunkyPNG::Image.new 500, 500, ChunkyPNG::Color::WHITE

#def initialize path, img, amb_col, ka, kd, ks, ia, il1, il2, il1_c, il2_c, v_p, n, l1p, l2p, save_path
#binding.pry
model = ModelWithLight.new('Torus.txt',
                           png,
                           ChunkyPNG::Color::WHITE,
                           ChunkyPNG::Color.rgb(0, 0, 0),
                           ChunkyPNG::Color.rgb(0, 0, 0),
                           0.4, 0.05, 0.0, 0.5,
                           ChunkyPNG::Color::WHITE,
                           ChunkyPNG::Color::WHITE,
                           Point.new(0, 0, 100),
                           10,
                           Point.new(10, 0, 5),
                           Point.new(10, 0, 5),
                           __FILE__ + 'tor.png')
model.render("guro")
p


