$LOAD_PATH << '.'
require 'pry'
require 'json'
class Toroid
  attr_accessor :r_big, :r_small
  def initialize r_big, r_small
    @r_big, @r_small = r_big, r_small
  end
  def x phi, psi
    (@r_big+@r_small*Math.cos(phi))*Math.cos(psi)
  end
  def y phi, psi
    (@r_big+@r_small*Math.cos(phi))*Math.sin(psi)
  end
  def z phi, psi
    @r_small*Math.sin(phi)
  end
end



def tor_normal(u,v,r_dest,r_gener)
  a = [r_dest*Math.cos(v),r_dest*Math.sin(v),0]
  b = [(r_dest + r_gener*Math.cos(u))*Math.cos(v),(r_dest + r_gener*Math.cos(u))*Math.sin(v),r_gener*Math.sin(u)]
  [a[0] - b[0],a[1] - b[1],a[2] - b[2]]
end

tor = Toroid.new(5, 2)

f = File.new("tor.txt", "w")

coords = []
verticles = []
polygons = []
normals = []

phi = 0.0

phi_step = 2*Math::PI/20
psi_step = 2*Math::PI/10

while phi < 2*Math::PI do
  psi = -Math::PI
  while psi < Math::PI do
    circle11, circle12 = phi, phi + phi_step
    circle21, circle22 = psi, psi + psi_step
    x1, y1, z1 = tor.x(circle11, circle21), tor.y(circle11, circle21), tor.z(circle11, circle21)
    x2, y2, z2 = tor.x(circle12, circle21), tor.y(circle12, circle21), tor.z(circle12, circle21)
    x3, y3, z3 = tor.x(circle11, circle22), tor.y(circle11, circle22), tor.z(circle11, circle22)
    x4, y4, z4 = tor.x(circle12, circle22), tor.y(circle12, circle22), tor.z(circle12, circle22)

    coords << [x1, y1, z1]
    coords << [x2, y2, z2]
    coords << [x3, y3, z3]
    coords << [x4, y4, z4]

    normals << tor_normal(circle11, circle21, 5, 2)
    normals << tor_normal(circle12, circle21, 5, 2)
    normals << tor_normal(circle11, circle22, 5, 2)
    normals << tor_normal(circle12, circle22, 5, 2)

    n = coords.count
    c1, c2, c3, c4 = n-4, n-3, n-2, n-1
#    verticles << [c1, c2]
#    verticles << [c2, c3]
#    verticles << [c3, c4]
#    verticles << [c4, c1]
#    verticles << [c1, c3]
#
#    n = verticles.count
#    cc1, cc2, cc3, cc4, cc5 = n-5, n-4, n-3, n-2, n-1
    polygons << [c1, c2, c3]
    polygons << [c1, c4, c3]
    psi += psi_step
  end
  phi += phi_step
end

#f.write(coords.count.to_s + "\n")
#coords.each do |triple|
#  f.write(triple.map {|item| item.to_s }.join(' ') + "\n")
#end
#f.write(verticles.count.to_s + "\n")
#verticles.each do |pair|
#  f.write(pair.map {|item| item.to_s }.join(' ') + "\n")
#end
to_write = {:coords => coords, :polygons => polygons, :normals => normals}
f.write JSON.generate(to_write)
f.close
