using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Collections;
using System.IO;
using System.Globalization;
using MathNet.Numerics;

namespace Lab3
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
            
        }

        double[,] I = new double[,] { { 1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 } };
        Figure original, current;
        double[,] lastmatr = null;
        double lx, ly, ldx, ldy;
        double langle;
        double ls;
        //ListCoords coords_pairs = new ListCoords();
        //ArrayList verticles = new ArrayList();
        string name;
        double Xmax, Xmin, Ymax, Ymin;
        int R = 5;

        private void button1_Click(object sender, EventArgs e)
        {
            //coords_pairs.Clear();
            //verticles.Clear();
            
            Xmax = 0;
            Xmin = 0;
            Ymax = 0;
            Ymin = 0;
            Xmax = Xmin = Ymax = Ymin = -1;
            current = null;
            original = new Figure();

            ListCoords coords_pairs = new ListCoords();
            ArrayList verticles = new ArrayList();
            try
            {
                OpenFileDialog form = new OpenFileDialog();
                form.DefaultExt = ".txt";
                if (form.ShowDialog() == DialogResult.OK)
                    using (StreamReader sr = new StreamReader(form.FileName, Encoding.Default))
                    {
                        string line = null;
                        line = sr.ReadLine();

                        name = line;
                        int count;
                        line = sr.ReadLine();
                        if (!int.TryParse(line, out count))
                            throw new Exception();
                        for (int i = 0; i < count; i++)
                        {
                            PairCoords pair = new PairCoords();
                            line = sr.ReadLine();
                            string[] vals = line.Split(' ');
                            bool isOK = double.TryParse(vals[0], NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out pair.x);
                            isOK = double.TryParse(vals[1], NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out pair.y);
                            if (vals.Length != 2 || !isOK)
                                throw new Exception();
                            else
                                coords_pairs.Add(pair);
                        }
                        line = sr.ReadLine();
                        if (!int.TryParse(line, out count))
                            throw new Exception();
                        for (int i = 0; i < count; i++)
                        {
                            Verticle v = new Verticle();
                            line = sr.ReadLine();
                            string[] vals = line.Split(' ');
                            if (vals.Length != 2 || !int.TryParse(vals[0], out v.a) || !int.TryParse(vals[1], out v.b))
                                throw new Exception();
                            else
                                verticles.Add(v);
                        }
                        original.coords_pairs = coords_pairs;
                        original.verticles = verticles;
                        original.brush = new SolidBrush(Color.Blue);
                        original.pen = new Pen(Color.Blue);
                        current = new Figure();
                        current.coords_pairs = original.coords_pairs;
                        current.verticles = original.verticles;
                        InitMaxnMins(original, current);
                        MessageBox.Show("Successfully loaded");
                        Log(current, richTextBox1);
                        Log(current, richTextBox2);
                        Draw(original);
                        PrintMatrix(I);
                    }
            }
            catch
            {
                MessageBox.Show("Bad file");
            }
        }

        private void Log(Figure fig, RichTextBox txt)
        {
            txt.Clear();
            for (int i = 0; i < fig.coords_pairs.Length; i++)
                txt.Text += String.Format("{0}: <{1, 4:F2}, {2, 4:F2}>\n", i+1, fig.coords_pairs[i].x, fig.coords_pairs[i].y);
        }

        private void PrintMatrix(double[,] matr)
        {
            richTextBox3.Clear();
            for (int i = 0; i < 3; i++)
            {
                string s = "";
                for (int j = 0; j < 3; j++)
                    s += Math.Round(matr[i, j], 4).ToString() + (j == 2 ? "\n" : "|");
                richTextBox3.Text += s;
            }
        }

        private double[,] GetMatrix()
        {
            try
            {
                double[,] a = new double[3, 3];
                for (int i = 0; i < 3; i++)
                {
                    string[] temp = richTextBox3.Lines[i].Split('|');
                    if (temp.Length != 3) throw new Exception();
                    for (int j = 0; j < 3; j++)
                        a[i, j] = double.Parse(temp[j]);
                }
                return a;
            }
            catch
            {
                MessageBox.Show("Failure T matrix. Return to identity matrix.");
                PrintMatrix(I);
                return I;
            }
        }

        private void InitMaxnMins(Figure first, Figure sec)
        {
            if (checkBox1.Checked && !(Xmax == -1 && Xmin == -1 && Ymin == -1 && Ymax == -1)) return;
            Xmax = Xmin = Ymax = Ymin = 0;
            for (int i = 0; i < first.coords_pairs.Length; i++)
            {
                if (Math.Max(first.coords_pairs[i].x, sec.coords_pairs[i].x) > Xmax) Xmax = Math.Max(first.coords_pairs[i].x, sec.coords_pairs[i].x);
                if (Math.Min(first.coords_pairs[i].x, sec.coords_pairs[i].x) < Xmin) Xmin = Math.Min(first.coords_pairs[i].x, sec.coords_pairs[i].x);

                if (Math.Max(first.coords_pairs[i].y, sec.coords_pairs[i].y) > Ymax) Ymax = Math.Max(first.coords_pairs[i].y, sec.coords_pairs[i].y);
                if (Math.Min(first.coords_pairs[i].y, sec.coords_pairs[i].y) < Ymin) Ymin = Math.Min(first.coords_pairs[i].y, sec.coords_pairs[i].y);
            }

            Ymin -= 1;
            Xmin -= 1;
        }

        private double Kx()
        {
            return (double)(pictureBox1.Width - 20) / (Xmax - Xmin);
        }

        private double Ky()
        {
            return (double)(pictureBox1.Height - 20) / (Ymax - Ymin);
        }

        private void Draw(Figure fig, bool redraw=true)
        {
            if (redraw) pictureBox1.Image = new Bitmap(pictureBox1.Width, pictureBox1.Height);
            double kx = Kx();
            double ky = Ky();
            int X0 = 10;
            int Y1 = pictureBox1.Height + 10;
            double K = Math.Min(kx, ky);

            DrawVerticles(fig, K, K, X0, Y1);
            DrawPoints(fig, K, K, X0, Y1);
            DrawCross(K, K, X0, Xmin, Y1, Ymin);
        }

        private void DrawPoints(Figure fig, double kx, double ky, int X0, int Y1)
        {
            Graphics g = Graphics.FromImage(pictureBox1.Image);

            int count = 0;
            for (int i = 0; i < fig.coords_pairs.Length; i++)
            {
                int x = TransX(X0, kx, fig.coords_pairs[i].x, Xmin);
                int y = TransY(Y1, ky, fig.coords_pairs[i].y, Ymin);
                g.FillEllipse(fig.brush, x - R / 2, y - R / 2, R, R);
                count++;
            }
        }

        private void DrawVerticles(Figure fig, double kx, double ky, int X0, int Y1)
        {
            Graphics g = Graphics.FromImage(pictureBox1.Image);

            int count = 0;
            for (int i = 0; i < fig.verticles.Count; i++)
            {
                int x1 = TransX(X0, kx, ((PairCoords)fig.coords_pairs[((Verticle)fig.verticles[i]).a-1]).x, Xmin);
                int y1 = TransY(Y1, ky, ((PairCoords)fig.coords_pairs[((Verticle)fig.verticles[i]).a-1]).y, Ymin);
                int x2 = TransX(X0, kx, ((PairCoords)fig.coords_pairs[((Verticle)fig.verticles[i]).b-1]).x, Xmin);
                int y2 = TransY(Y1, ky, ((PairCoords)fig.coords_pairs[((Verticle)fig.verticles[i]).b-1]).y, Ymin);
                g.DrawLine(fig.pen, new Point(x1, y1), new Point(x2, y2));
                count++;
            }
        }

        private void DrawCross(double kx, double ky, int x0, double xmin, int y1, double ymin)
        {
            Graphics g = Graphics.FromImage(pictureBox1.Image);
            int x = TransX(x0, kx, 0, xmin);
            int y = TransY(y1, ky, 0, ymin);
            g.DrawLine(Pens.Black, x - 5, y, x + 5, y);
            g.DrawLine(Pens.Black, x, y - 5, x, y + 5);
        }

        private int TransX(int x0, double K, double x, double Xmin)
        {
            return (int)(x0 + K * (x - Xmin));
        }

        private int TransY(int y1, double K, double y, double Ymin)
        {
            return (int)(y1 - K * (y - Ymin));
        }

        private double BackTransX(int x0, double K, int x, double Xmin)
        {
            return (x + K * Xmin - x0) / K;
        }

        private double BackTransY(int y1, double K, int y, double Ymin)
        {
            return (y - K * Ymin - y1) / (-K);
        }

        private void button2_Click(object sender, EventArgs e)
        {
            current.coords_pairs = original.coords_pairs;
            current.verticles = original.verticles;
            InitMaxnMins(current, original);
            Draw(current);
            Log(current, richTextBox2);
            DisableBack();
        }

        private void button5_Click(object sender, EventArgs e)
        {
            double a = 0;
            try
            {
                a = double.Parse(textBox1.Text);
            }
            catch
            {
                MessageBox.Show("Wrong Input");
                textBox1.Text = "";
                return;
            }
            if (checkBox2.Checked) a = -a;
            double[,] matr = new double[3, 3] 
            { { 1, 0, 0 }, 
            { 0, 1, 0 }, 
            { 0, a, 1 } };
            Trans(matr, current);
            DisableBack();
            //button10.Enabled = true;
        }

        private void button6_Click(object sender, EventArgs e)
        {
            int v = 0;
            try
            {
                v = int.Parse(textBox3.Text);
                if (v <= 0 || v - 1 > original.verticles.Count) throw new Exception();
            }
            catch
            {
                MessageBox.Show("Wrong Input");
                textBox3.Text = "";
                return;
            }
            Figure newfig = new Figure();
            double x1 = current.coords_pairs[((Verticle)current.verticles[v-1]).a - 1].x;
            double y1 = current.coords_pairs[((Verticle)current.verticles[v-1]).a - 1].y;
            double x2 = current.coords_pairs[((Verticle)current.verticles[v-1]).b - 1].x;
            double y2 = current.coords_pairs[((Verticle)current.verticles[v-1]).b - 1].y;
            double angle = 0;
            double dx = x2 - x1;
            double dy = y2 - y1;
            angle = Math.PI/2 - Math.Atan(dy / dx);
            double k = checkBox2.Checked ? 1.0/1.5 : 1.5;
            double[,] matr = new double[3, 3] 
            {
                {Math.Pow(Math.Cos(angle), 2) + k*Math.Pow(Math.Sin(angle), 2), -Math.Cos(angle) * Math.Sin(angle) + k * Math.Cos(angle) * Math.Sin(angle), 0},
                {-Math.Cos(angle)*Math.Sin(angle) + k * Math.Cos(angle)*Math.Sin(angle), k * Math.Pow(Math.Cos(angle),2) + Math.Pow(Math.Sin(angle), 2), 0},
                {x1 + k*Math.Sin(angle)*(-y1*Math.Cos(angle) - x1*Math.Sin(angle)) + Math.Cos(angle)*(-x1*Math.Cos(angle) + y1*Math.Sin(angle)), 
                 y1 + k*Math.Cos(angle)*(-y1*Math.Cos(angle) - x1*Math.Sin(angle)) - Math.Sin(angle)*(-x1*Math.Cos(angle) + y1*Math.Sin(angle)), 1}
            };
            lx = x1;
            ly = y1;
            langle = angle;
            Trans(matr, current);
            x1 = current.coords_pairs[((Verticle)current.verticles[v - 1]).a - 1].x;
            y1 = current.coords_pairs[((Verticle)current.verticles[v - 1]).a - 1].y;
            x2 = current.coords_pairs[((Verticle)current.verticles[v - 1]).b - 1].x;
            y2 = current.coords_pairs[((Verticle)current.verticles[v - 1]).b - 1].y;
            Point a = new Point(TransX(10, Math.Min(Kx(), Ky()), x1, Xmin), TransY(pictureBox1.Height + 10, Math.Min(Kx(), Ky()), y1, Ymin));
            Point b = new Point(TransX(10, Math.Min(Kx(), Ky()), x2, Xmin), TransY(pictureBox1.Height + 10, Math.Min(Kx(), Ky()), y2, Ymin));
            Graphics g = Graphics.FromImage(pictureBox1.Image);
            g.DrawLine(Pens.Magenta, a, b);
            DisableBack();
            //button11.Enabled = true;
        }

        private void button7_Click(object sender, EventArgs e)
        {
            double s = 0;
            try
            {
                s = double.Parse(textBox4.Text);
            }
            catch
            {
                MessageBox.Show("Wrong Input");
                textBox4.Text = "";
                return;
            }
            if (checkBox2.Checked) s = -s;
            double[,] matr = new double[3, 3] 
            { { 1, s, 0 }, 
            { 0, 1, 0 }, 
            { 0, 0, 1} };
            ls = s;
            Trans(matr, current);
            DisableBack();
            //button12.Enabled = true;
        }

        private void Trans(double[,] matr, Figure newfig)
        {
            PrintMatrix(matr);
            newfig.coords_pairs *= matr;
            newfig.brush = new SolidBrush(Color.Red);
            newfig.verticles = current.verticles;
            newfig.pen = Pens.Red;
            InitMaxnMins(original, newfig);
            Draw(original);
            Draw(newfig, false);
            Log(newfig, richTextBox2);
            current = newfig;
            lastmatr = matr;
        }

        private void button8_Click(object sender, EventArgs e)
        {
            double dx = 0, dy = 0;
            try
            {
                dx = double.Parse(textBox7.Text);
                dy = double.Parse(textBox8.Text);
            }
            catch
            {
                MessageBox.Show("Wrong Input");
                textBox7.Text = textBox8.Text = "";
            }
            double[,] matr = null;
            double pi = Math.PI;
            double phi = Math.Acos(dx/dy);
            ldx = dx;
            ldy = dy;
            if (dx == 0 && dy == 0) matr = new double[3, 3] { { -1, 0, 0 }, { 0, -1, 0 }, { 0, 0, 1 } };
            else if (dx == 0) matr = new double[3, 3] { { -1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 } };
            else if (dy == 0) matr = new double[3, 3] { { 1, 0, 0 }, { 0, -1, 0 }, { 0, 0, 1 } };
            else matr = new double[3, 3] 
            { { -Math.Cos(pi/2 - phi), Math.Sin(pi/2 - phi), 0 }, 
            { Math.Sin(pi/2 - phi), Math.Cos(pi/2 - phi), 0 },
            { 0, 0, 1 } };
            Trans(matr, current);
            DisableBack();
            //button13.Enabled = true;
        }

        private void button9_Click(object sender, EventArgs e)
        {
            int p = 0;
            double angle = 0;
            try
            {
                p = int.Parse(textBox5.Text);
                angle = double.Parse(textBox6.Text);
            }
            catch
            {
                MessageBox.Show("Wrong Input");
                textBox5.Text = textBox5.Text = "";
            }
            if (p < 0 || p > current.coords_pairs.Length)
            {
                MessageBox.Show("Wrong Input");
                return;
            }
            double x = current.coords_pairs[p-1].x;
            double y = current.coords_pairs[p-1].y;
            angle = angle / 180 * Math.PI;
            langle = angle;
            if (checkBox2.Checked) angle = -angle;
            double[,] matr = new double[,] 
            {{Math.Cos(angle), Math.Sin(angle), 0}, 
            {-Math.Sin(angle), Math.Cos(angle), 0}, 
            {-x*(Math.Cos(angle) - 1) + y * Math.Sin(angle), -x * Math.Sin(angle) - y * (Math.Cos(angle) - 1), 1}};
            lx = x;
            ly = y;
            Trans(matr, current);
            Point pp = new Point(TransX(10, Math.Min(Kx(), Ky()), x, Xmin) - R/2, TransY(pictureBox1.Height + 10, Math.Min(Kx(), Ky()), y, Ymin) - R/2);
            Graphics g = Graphics.FromImage(pictureBox1.Image);
            g.FillEllipse(Brushes.Yellow, pp.X, pp.Y, R, R);
            DisableBack();
            //button14.Enabled = true;
        }

        private void button10_Click(object sender, EventArgs e)
        {
            if (lastmatr == null) return;
            lastmatr[2, 1] *= -1;
            Trans(lastmatr, current);
            DisableBack();
        }

        private void button11_Click(object sender, EventArgs e)
        {
            if (lastmatr == null) return;
            double k = 1/1.5;
            double angle = langle;
            double x1 = lx;
            double y1 = ly;
            double[,] matr = new double[3,3]
            {
                {Math.Pow(Math.Cos(angle), 2) + k*Math.Pow(Math.Sin(angle), 2), -Math.Cos(angle) * Math.Sin(angle) + k * Math.Cos(angle) * Math.Sin(angle), 0},
                {-Math.Cos(angle)*Math.Sin(angle) + k * Math.Cos(angle)*Math.Sin(angle), k * Math.Pow(Math.Cos(angle),2) + Math.Pow(Math.Sin(angle), 2), 0},
                {x1 + k*Math.Sin(angle)*(-y1*Math.Cos(angle) - x1*Math.Sin(angle)) + Math.Cos(angle)*(-x1*Math.Cos(angle) + y1*Math.Sin(angle)), 
                 y1 + k*Math.Cos(angle)*(-y1*Math.Cos(angle) - x1*Math.Sin(angle)) - Math.Sin(angle)*(-x1*Math.Cos(angle) + y1*Math.Sin(angle)), 1}
            };
            Trans(matr, current);
            DisableBack();
        }

        private void button12_Click(object sender, EventArgs e)
        {
            if (lastmatr == null) return;
            double[,] matr = new double[3,3] 
            {
                {1, -ls, 0},{0, 1, 0},{0, 0, 1}
            };
            Trans(matr, current);
            DisableBack();
        }
        
        private void DisableBack()
        {
            return;
            button10.Enabled = button11.Enabled = button12.Enabled = button13.Enabled = button14.Enabled = false;
        }

        private void button13_Click(object sender, EventArgs e)
        {
            double pi = Math.PI;
            double phi = -Math.Acos(ldx / ldy);
            double[,] matr = new double[3, 3] { { -Math.Cos(pi / 2 - phi), Math.Sin(pi / 2 - phi), 0 }, { Math.Sin(pi / 2 - phi), Math.Cos(pi / 2 - phi), 0 }, { 0, 0, 1 } };
            Trans(matr, current);
            DisableBack(); 
        }

        private void button14_Click(object sender, EventArgs e)
        {
            double[,] matr = new double[,] 
            {{Math.Cos(-langle), Math.Sin(-langle), 0}, 
            {-Math.Sin(-langle), Math.Cos(-langle), 0}, 
            {-lx*(Math.Cos(-langle) - 1) + ly * Math.Sin(-langle), -lx * Math.Sin(-langle) - ly * (Math.Cos(-langle) - 1), 1}};
            Trans(matr, current);
            DisableBack();
        }

        private void button3_Click(object sender, EventArgs e)
        {
            double[,] matr = GetMatrix();
            if (matr == I) return;
            Trans(matr, original);
            DisableBack();
        }

        private void button4_Click(object sender, EventArgs e)
        {
            double[,] matr = GetMatrix();
            if (matr == I) return;
            Trans(matr, current);
            DisableBack();
        }
    }

    public class PairCoords
    {
        public double x;
        public double y;
        public double h = 1;
    }

    public class Verticle
    {
        public int a;
        public int b;
    }

    public class ListCoords
    {
        ArrayList intlist = new ArrayList();
        public int Length
        {
            get { return intlist.Count; }
        }
        public ListCoords()
        { }

        public ListCoords(ArrayList list)
        { intlist = list; }

        public PairCoords this[int i]
        {
            get { return (PairCoords)intlist[i]; }
            set { intlist[i] = value; }
        }
        public static ListCoords operator*(ListCoords a, double [,] b)
        {
            ArrayList outlist = new ArrayList();
            for(int i = 0; i < a.Length; i++)
            {
                PairCoords pp = new PairCoords();
                pp.x = a[i].x * b[0, 0] + a[i].y * b[1, 0] + a[i].h * b[2, 0];
                pp.y = a[i].x * b[0, 1] + a[i].y * b[1, 1] + a[i].h * b[2, 1];
                pp.h = a[i].x * b[0, 2] + a[i].y * b[1, 2] + a[i].h * b[2, 2];
                pp.x /= pp.h;
                pp.y /= pp.h;
                pp.h /= pp.h;
                outlist.Add(pp);
            }
            return new ListCoords(outlist);
        }
        public void Clear()
        {
            intlist.Clear();
        }
        public void Add(PairCoords a)
        {
            intlist.Add(a);
        }
    }

    public class Figure
    {
        public ArrayList verticles;
        public ListCoords coords_pairs;
        public SolidBrush brush = new SolidBrush(Color.Black);
        public Pen pen = new Pen(Color.Black);
    }
}
