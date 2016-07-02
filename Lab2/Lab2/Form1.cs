using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Globalization;

namespace Lab2
{
    public partial class Form1 : Form
    {
        delegate double function(double x);
        double a1, b1, d1;
        double a2, b2, c2;
        double a3, b3;
        double Xmin, Xmax, Ymin, Ymax;
        double Tmax, Tmin;
        int X0, Y1;
        double N = 1000;
        double h = 1;
        double ht = 1;
        double M = 0;


        public Form1()
        {
            InitializeComponent();
        }

        private double f1(double x)
        {
            return a1 * Math.Pow(Math.Cos(x), 2) + b1 * Math.Sin(d1 * x);
        }

        private double f2(double x)
        {
            return Math.Tan(a2 * x) / b2 / x + c2 * x;
        }

        private double f3x(double t)
        {
            return a3 * Math.Pow(Math.Cos(t), 2) + a3 * Math.Cos(t);
        }

        private double f3y(double t)
        {
            return b3 * Math.Cos(t) * Math.Sin(t) + b3 * Math.Sin(t);
        }

        private int TransX(double x, double Width)
        {
            return (int)(X0 + Kx(Width) * (x - Xmin));
        }

        private int TransY(double y, double Height)
        {
            return (int)(Height - Ky(Height) * (y - Ymin));
        }

        private double BackTransX(int x, double Width)
        {
            return (x + Kx(Width) * Xmin - X0) / Kx(Width);
        }

        private double BackTransY(int y, double Height)
        {
            return (y - Ky(Height) * Ymin - Height) / (-Ky(Height));
        }

        private double Kx(double Width)
        {
            return Width / (Xmax - Xmin);
        }

        private double Ky(double Height)
        {
            return Height / (Ymax - Ymin);
        }

        private void DrawLines(PictureBox target)
        {
            Graphics g = Graphics.FromImage(target.Image);

            int AxisX = TransY(0, target.Height);
            int AxisY = TransX(0, target.Width);

            g.DrawLine(Pens.Blue, 0, AxisX, target.Width - 1, AxisX);
            g.DrawLine(Pens.Blue, AxisY, 0, AxisY, target.Height - 1);

            double h = (Xmax - Xmin) / 20;
            for (int i = 0; i < 10; i++)
            {
                double xm = Xmin + i * h;
                double xp = Xmax - i * h;
                g.DrawLine(Pens.Blue, TransX(xm, target.Width), AxisX + 2, TransX(xm, target.Width), AxisX - 2);
                g.DrawString(String.Format("{0:F2}", xm), new Font("Arial", 10), new SolidBrush(Color.Black), TransX(xm, target.Width), AxisX + 3);
                g.DrawLine(Pens.Blue, TransX(xp, target.Width), AxisX + 2, TransX(xp, target.Width), AxisX - 2);
                g.DrawString(String.Format("{0:F2}", xp), new Font("Arial", 10), new SolidBrush(Color.Black), TransX(xp, target.Width), AxisX + 3);
                //if (i == 9 && (Xmin > 0 || Xmax < 0))
                //{
                double xx = Xmax - 10 * h;
                g.DrawLine(Pens.Blue, TransX(xx, target.Width), AxisX + 2, TransX(xx, target.Width), AxisX - 2);
                g.DrawString(String.Format("{0:F2}", xx), new Font("Arial", 10), new SolidBrush(Color.Black), TransX(xx, target.Width), AxisX + 3);
                //}
            }
            h = (Ymax - Ymin) / 20;
            for(int i = 0; i < 10; i++)
            {
                double ym = Ymin + i * h;
                double yp = Ymax - i * h;
                g.DrawLine(Pens.Blue, AxisY + 2, TransY(ym, target.Height), AxisY - 2, TransY(ym, target.Height));
                g.DrawString(String.Format("{0:F2}", ym), new Font("Arial", 10), new SolidBrush(Color.Black), AxisY + 3, TransY(ym, target.Height));
                g.DrawLine(Pens.Blue, AxisY + 2, TransY(yp, target.Height), AxisY - 2, TransY(yp, target.Height));
                g.DrawString(String.Format("{0:F2}", yp), new Font("Arial", 10), new SolidBrush(Color.Black), AxisY + 3, TransY(yp, target.Height));
                //if (i == 9 && (Ymin > 0 || Ymax < 0))
                //{
                double yy = Ymax - 10 * h;
                g.DrawLine(Pens.Blue, AxisY + 2, TransY(yy, target.Height), AxisY - 2, TransY(yy, target.Height));
                g.DrawString(String.Format("{0:F2}", yy), new Font("Arial", 10), new SolidBrush(Color.Black), AxisY + 3, TransY(yy, target.Height));
                //}
            }
        }

        private void DrawGraph(PictureBox target, function f = null, function fx = null, function fy = null)
        {
            Graphics g = Graphics.FromImage(target.Image);
            List<Point> points = new List<Point>();

            if (target != pictureBox4)
            {
                for (double x = Xmin; x < Xmax; x += h)
                {
                    int drawx = TransX(x, target.Width);
                    double y = f(x);
                    int drawy = TransY(y, target.Height);
                    Point p = new Point(drawx, drawy);
                    points.Add(p);
                }
                DrawLines(target);
                //g.DrawLines(Pens.Red, points.ToArray());
                Point[] points_array = points.ToArray();
                int top = TransY(Ymax, target.Height);
                int bottom = TransY(Ymin, target.Height);
                for (int i = 0; i < points_array.Length-2; i++)
                {
                    if (points_array[i].Y < top || points_array[i].Y > bottom || points_array[i+1].Y < top || points_array[i+1].Y > bottom || double.IsNaN(points_array[i].Y) || double.IsNaN(points_array[i+1].Y)) continue;
                    g.DrawLine(Pens.Red, points_array[i], points_array[i + 1]);
                }
            }
            else
            {
                for (double t = Tmin; t <= Tmax; t += ht)
                {
                    double x = fx(t);
                    double y = fy(t);

                    int drawx = TransX(x, target.Width);
                    int drawy = TransY(y, target.Height);
                    Point p = new Point(drawx, drawy);
                    points.Add(p);
                }
                DrawLines(target);
                g.DrawLines(Pens.Red, points.ToArray());
            }
        }

        private void Draw(PictureBox target, function f = null, function fx = null, function fy = null)
        {
            target.Image = new Bitmap(target.Width, target.Height);
            target.BackColor = Color.White;
            if (target != pictureBox4 && Xmax <= Xmin)
            {
                MessageBox.Show("Failure data");
                return;
            }
            if (target != pictureBox4)
            {
                h = (Xmax - Xmin) / N;
                Ymin = f(Xmin);
                Ymax = f(Xmin);
                for (double x = Xmin + h; x < Xmax; x += h)
                {
                    if (f(x) > Ymax) Ymax = f(x);
                    if (f(x) < Ymin) Ymin = f(x);
                }
                if (target == pictureBox2)
                {
                    label5.Text = String.Format("{0:F2}", Ymin);
                    label6.Text = String.Format("{0:F2}", Ymax);
                }
                else
                {
                    if (Ymax > M) Ymax = M;
                    if (Ymin < -M) Ymin = -M;
                    label32.Text = String.Format("{0:F2}", Ymax);
                    label31.Text = String.Format("{0:F2}", Ymin);
                }
                if (Ymax == Ymin)
                {
                    double range = (Xmax - Xmin) / 4;
                    Ymax += range;
                    Ymin -= range;
                }
                else
                {
                    Ymax += 1;
                    Ymin -= 1;
                }
                DrawGraph(target, f: f);
            }
            else
            {
                ht = (Tmax - Tmin) / N;
                Ymin = fy(Tmin);
                Ymax = fy(Tmin);
                Xmin = fx(Tmin);
                Xmax = fx(Tmin);

                for(double t = Tmin; t <= Tmax; t += h)
                {
                    if (fy(t) > Ymax) Ymax = fy(t);
                    if (fy(t) < Ymin) Ymin = fy(t);
                    if (fx(t) > Xmax) Xmax = fx(t);
                    if (fx(t) < Xmin) Xmin = fx(t);
                }

                label22.Text = String.Format("{0:F2}", Xmax);
                label23.Text = String.Format("{0:F2}", Xmin);
                label24.Text = String.Format("{0:F2}", Ymax);
                label25.Text = String.Format("{0:F2}", Ymin);

                if (checkBox1.Checked)
                {
                    Xmax = Ymax = Math.Max(Xmax, Ymax);
                    Xmin = Ymin = Math.Min(Xmin, Ymin);
                }

                Ymax += 1;
                Ymin -= 1;
                Xmax += 1;
                Xmin -= 1;
                DrawGraph(target, fx: fx, fy: fy);
            }
        }

        private void SaveImage(PictureBox target, PictureBox formula, string name, double? a=null, double? b=null, double? d=null)
        {
            SaveFileDialog saveform = new SaveFileDialog();
            saveform.AddExtension = true;
            saveform.DefaultExt = "jpg";
            saveform.Filter = "Файлы изображений (*.jpg)|*.jpg|Все файлы(*.*)|*.*";
            saveform.FileName = name;
            if (saveform.ShowDialog() == DialogResult.OK)
            {
                Bitmap temp = (Bitmap)target.Image.Clone();
                Graphics g = Graphics.FromImage(temp);
                g.DrawImage(formula.Image, temp.Width - formula.Width - 1, 1, formula.Width * 3 / 4, formula.Height * 3 / 4);
                g.DrawString(name.ToUpper() + "\n" + (a != null ? ("a = " + a + "\n") : "") + (b != null ? ("b = " + b + "\n") : "") + (d != null ? ("d = " + d + "\n") : ""), new Font("Arial", 10), Brushes.Red, 1, 1);
                temp.Save(saveform.FileName);
            }
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            X0 = 0;
            //Y1 = pictureBox2.Height;
            pictureBox2.Image = null;
            pictureBox4.Image = null;
            pictureBox6.Image = null;
        }

        private void button1_Click(object sender, EventArgs e)
        {
            try
            {
                Xmin = double.Parse(textBox1.Text, CultureInfo.InvariantCulture);
                Xmax = double.Parse(textBox2.Text, CultureInfo.InvariantCulture);
                a1 = double.Parse(textBox3.Text, CultureInfo.InvariantCulture);
                b1 = double.Parse(textBox4.Text, CultureInfo.InvariantCulture);
                d1 = double.Parse(textBox5.Text, CultureInfo.InvariantCulture);
                Draw(pictureBox2, f: f1);
            }
            catch
            {
                MessageBox.Show("Failure data");
            }
        }

        private void pictureBox2_MouseMove(object sender, MouseEventArgs e)
        {
            if (pictureBox2.Image == null) return;
            label9.Text = String.Format("{0:F2}", BackTransX(e.X, ((PictureBox)sender).Width));
            label10.Text = String.Format("{0:F2}", BackTransY(e.Y, ((PictureBox)sender).Height));
        }

        private void Form1_ResizeEnd(object sender, EventArgs e)
        {
            //Y1 = pictureBox2.Height;
            if (pictureBox2.Image != null)
                Draw(pictureBox2, f: f1);
            if (pictureBox6.Image != null)
                Draw(pictureBox6, f: f2);
            if (pictureBox4.Image != null)
                Draw(pictureBox4, fx: f3x, fy: f3y);
        }

        private void button2_Click(object sender, EventArgs e)
        {
            try
            {
                a3 = double.Parse(textBox6.Text, CultureInfo.InvariantCulture);
                b3 = double.Parse(textBox7.Text, CultureInfo.InvariantCulture);

                Tmin = double.Parse(textBox8.Text, CultureInfo.InvariantCulture);
                Tmax = double.Parse(textBox9.Text, CultureInfo.InvariantCulture);
            }
            catch
            {
                MessageBox.Show("Failure data for algebraic curve");
                return;
            }

            if (Tmin >= Tmax)
            {
                MessageBox.Show("Failure data for algebraic curve");
                return;
            }
            else
            {
                Draw(pictureBox4, fx: f3x, fy: f3y);
            }
        }

        private void checkBox1_CheckedChanged(object sender, EventArgs e)
        {
            Draw(pictureBox4, fx: f3x, fy: f3y);
        }

        private void button3_Click(object sender, EventArgs e)
        {
            SaveImage(pictureBox2, pictureBox1, "Simple function", a: a1, b: b1, d: d1);
        }

        private void button4_Click(object sender, EventArgs e)
        {
            SaveImage(pictureBox4, pictureBox3, "Cardioide", a: a3, b: b3);
        }

        private void pictureBox4_MouseMove(object sender, MouseEventArgs e)
        {
            if (pictureBox4.Image == null) return;
            label41.Text = String.Format("{0:F2}", BackTransX(e.X, ((PictureBox)sender).Width));
            label40.Text = String.Format("{0:F2}", BackTransY(e.Y, ((PictureBox)sender).Height));
        }

        private void pictureBox6_MouseMove(object sender, MouseEventArgs e)
        {
            if (pictureBox6.Image == null) return;
            label37.Text = String.Format("{0:F2}", BackTransX(e.X, ((PictureBox)sender).Width));
            label36.Text = String.Format("{0:F2}", BackTransY(e.Y, ((PictureBox)sender).Height));
        }

        private void button5_Click(object sender, EventArgs e)
        {
            try
            {
                a2 = double.Parse(textBox11.Text, CultureInfo.InvariantCulture);
                b2 = double.Parse(textBox10.Text, CultureInfo.InvariantCulture);
                c2 = double.Parse(textBox12.Text, CultureInfo.InvariantCulture);

                Xmin = double.Parse(textBox14.Text, CultureInfo.InvariantCulture);
                Xmax = double.Parse(textBox13.Text, CultureInfo.InvariantCulture);
                M = double.Parse(textBox15.Text, CultureInfo.InvariantCulture);
                if (a2 == 0 && b2 == 0) throw new Exception();
                Draw(pictureBox6, f: f2);
            }
            catch
            {
                MessageBox.Show("Failure data for discontinous function");
            }
        }

        private void button6_Click(object sender, EventArgs e)
        {
            SaveImage(pictureBox6, pictureBox5, "Discontinous function", a: a2, b: b2, d: c2);
        }
    }
}
