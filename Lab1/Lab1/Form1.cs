using System;
using System.Collections.Generic;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.IO;
using System.Globalization;
using System.Reflection;

namespace Lab1
{

    public partial class Form1 : Form
    {
        ArrayList coords_pairs = new ArrayList();
        ArrayList verticles = new ArrayList();

        double Xmax, Xmin, Ymax, Ymin;
        string name;

        int R = 3;
        SolidBrush brush = new SolidBrush(Color.Black);
        Pen pen = Pens.Black;

        public Form1()
        {
            InitializeComponent();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            coords_pairs.Clear();
            verticles.Clear();

            Xmax = 0;
            Xmin = 0;
            Ymax = 0;
            Ymin = 0;

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
                            if (!checkBox1.Checked) pair.draw = true;
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
                        InitMaxnMins();
                        MessageBox.Show("Successfully loaded");
                        label5.Text = form.FileName.Substring(form.FileName.LastIndexOf('\\') + 1);
                        label6.Text = name;
                        Draw();
                    }
            }
            catch
            {
                MessageBox.Show("Bad file");
            }
        }

        private void InitMaxnMins()
        {
            Xmax = Xmin = Ymax = Ymin = 0;
            if (checkBox1.Checked)
            {
                for (int i = 0; i < coords_pairs.Count; i++)
                    ((PairCoords)coords_pairs[i]).draw = true;
            }
            else
            {
                for (int i = 0; i < coords_pairs.Count; i++)
                    ((PairCoords)coords_pairs[i]).draw = false;

                foreach(Verticle item in verticles)
                {
                    ((PairCoords)coords_pairs[item.a - 1]).draw = true;
                    ((PairCoords)coords_pairs[item.b - 1]).draw = true;
                }
            }

            foreach(PairCoords pair in coords_pairs)
            {
                if (pair.draw)
                {
                    if (pair.x > Xmax) Xmax = pair.x;
                    if (pair.x < Xmin) Xmin = pair.x;

                    if (pair.y > Ymax) Ymax = pair.y;
                    if (pair.y < Ymin) Ymin = pair.y;
                }
            }

            Ymin -= 1;
            Xmin -= 1;
        }


        private void Draw()
        {
            if (radioButton1.Checked)
                DrawProportional();
            else
                DrawUnproportional();
        }

        private void DrawCross(double kx, double ky, int x0, double xmin, int y1, double ymin)
        {
            if (!checkBox3.Checked || label5.Text == "") return;
            Graphics g = Graphics.FromImage(pictureBox1.Image);
            int x = TransX(x0, kx, 0, xmin);
            int y = TransY(y1, ky, 0, ymin);
            g.DrawLine(Pens.Black, x - 5, y, x + 5, y);
            g.DrawLine(Pens.Black, x, y - 5, x, y + 5);
        }

        private double Kx()
        {
            return (double)(pictureBox1.Width - 20) / (Xmax - Xmin);
        }

        private double Ky()
        {
            return (double)(pictureBox1.Height - 20) / (Ymax - Ymin);
        }

        private void DrawProportional()
        {
            pictureBox1.Image = new Bitmap(pictureBox1.Width, pictureBox1.Height);
            double kx = Kx();
            double ky = Ky();
            int X0 = 10;
            int Y1 = pictureBox1.Height + 10;
            double K = Math.Min(kx, ky);

            DrawVerticles(K, K, X0, Y1);
            DrawPoints(K, K, X0, Y1);
            DrawCross(K, K, X0, Xmin, Y1, Ymin);
        }

        private void DrawUnproportional()
        {
            pictureBox1.Image = new Bitmap(pictureBox1.Width, pictureBox1.Height);
            double kx = Kx();
            double ky = Ky();
            int X0 = 10;
            int Y1 = pictureBox1.Height + 10;

            DrawVerticles(kx, ky, X0, Y1);
            DrawPoints(kx, ky, X0, Y1);
            DrawCross(kx, ky, X0, Xmin, Y1, Ymin);
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

        private void DrawPoints(double kx, double ky, int X0, int Y1)
        {
            if (!checkBox1.Checked)
            {
                label8.Text = "0";
                return;
            }
            Graphics g = Graphics.FromImage(pictureBox1.Image);

            int count = 0;
            foreach (PairCoords pair in coords_pairs)
            {
                int x = TransX(X0, kx, pair.x, Xmin);
                int y = TransY(Y1, ky, pair.y, Ymin);
                g.FillEllipse(brush, x - R / 2, y - R / 2, R, R);
                count++;
            }

            label8.Text = count.ToString();
        }

        private void DrawVerticles(double kx, double ky, int X0, int Y1)
        {
            if (!checkBox2.Checked)
            {
                label10.Text = "0";
                return;
            }
            Graphics g = Graphics.FromImage(pictureBox1.Image);

            int count = 0;
            if (!checkBox4.Checked)
            {
                foreach (Verticle vert in verticles)
                {
                    int x1 = TransX(X0, kx, ((PairCoords)coords_pairs[vert.a - 1]).x, Xmin);
                    int y1 = TransY(Y1, ky, ((PairCoords)coords_pairs[vert.a - 1]).y, Ymin);
                    int x2 = TransX(X0, kx, ((PairCoords)coords_pairs[vert.b - 1]).x, Xmin);
                    int y2 = TransY(Y1, ky, ((PairCoords)coords_pairs[vert.b - 1]).y, Ymin);
                    g.DrawLine(pen, new Point(x1, y1), new Point(x2, y2));
                    count++;
                }
            }
            else
            {
                for (int i = 0; i < coords_pairs.Count - 1; i++)
                {
                    int x1 = TransX(X0, kx, ((PairCoords)coords_pairs[i]).x, Xmin);
                    int y1 = TransY(Y1, ky, ((PairCoords)coords_pairs[i]).y, Ymin);
                    int x2 = TransX(X0, kx, ((PairCoords)coords_pairs[i+1]).x, Xmin);
                    int y2 = TransY(Y1, ky, ((PairCoords)coords_pairs[i+1]).y, Ymin);
                    g.DrawLine(pen, new Point(x1, y1), new Point(x2, y2));
                    count++;
                }
            }

            label10.Text = count.ToString();
        }

        private void radioButton1_CheckedChanged(object sender, EventArgs e)
        {
            Draw();
        }

        private void radioButton2_CheckedChanged(object sender, EventArgs e)
        {
            Draw();
        }

        private void checkBox1_CheckedChanged(object sender, EventArgs e)
        {
            InitMaxnMins();
            Draw();
        }

        private void checkBox2_CheckedChanged(object sender, EventArgs e)
        {
            Draw();
        }

        private void numericUpDown1_ValueChanged(object sender, EventArgs e)
        {
            if (numericUpDown1.Value == 0) numericUpDown1.Value = 1;
            if (numericUpDown1.Value == 101) numericUpDown1.Value = 100;
            R = (int)numericUpDown1.Value;
            Draw();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            foreach (PropertyInfo item in typeof(Color).GetProperties())
            {
                if (item.PropertyType.FullName == "System.Drawing.Color")
                    comboBox1.Items.Add(item.Name);
            }
            comboBox1.SelectedIndex = 1;
            WriteSize();
        }

        private void comboBox1_SelectedIndexChanged(object sender, EventArgs e)
        {
            Color cols = new Color();
            pen = new Pen((Color)typeof(Color).GetProperty(comboBox1.SelectedItem.ToString()).GetValue(cols));
            if (coords_pairs.Count == 0) return;
            Draw();
        }

        private void Form1_ResizeEnd(object sender, EventArgs e)
        {
            InitMaxnMins();
            Draw();
            WriteSize();
        }

        private void WriteSize()
        {
            label12.Text = String.Format("({0} ; {1})", 0, pictureBox1.Width);
            label13.Text = String.Format("({0} ; {1})", 0, pictureBox1.Height);
        }

        private void pictureBox1_MouseMove(object sender, MouseEventArgs e)
        {
            if (coords_pairs.Count == 0) return;
            double printx, printy;
            printx = printy = 0;
            if (radioButton2.Checked)
            {
                printx = BackTransX(10, Kx(), e.X, Xmin);
                printy = BackTransY(pictureBox1.Height + 10, Ky(), e.Y, Ymin);
            }
            else
            {
                if (Math.Min(Kx(), Ky()) == Kx())
                {
                    printx = BackTransX(10, Kx(), e.X, Xmin);
                    printy = BackTransY(pictureBox1.Height + 10, Kx(), e.Y, Ymin);
                }
                else
                {
                    printx = BackTransX(10, Ky(), e.X, Xmin);
                    printy = BackTransY(pictureBox1.Height + 10, Ky(), e.Y, Ymin);
                }
            }
            label15.Text = String.Format("({0:F2} ; {1:F2})", printx, printy);
            Point nearest_point = new Point(int.MaxValue, int.MaxValue);
            int num = 0;
            double kx = Kx(), ky = Ky();
            if (radioButton1.Checked)
            {
                double t = Math.Min(kx, ky);
                kx = ky = t;
            }
            int X, Y;
            for(int i = 0; i < coords_pairs.Count; i++)
            {
                X = TransX(10, kx, ((PairCoords)coords_pairs[i]).x, Xmin);
                Y = TransY(pictureBox1.Height + 10, ky, ((PairCoords)coords_pairs[i]).y, Ymin);
                double minrange = Math.Sqrt((nearest_point.X - e.X) * (nearest_point.X - e.X) + (nearest_point.Y - e.Y) * (nearest_point.Y - e.Y));
                double range = Math.Sqrt((X - e.X) * (X - e.X) + (Y - e.Y) * (Y - e.Y));
                
                if (range < minrange)
                {
                    num = i;
                    nearest_point.X = X;
                    nearest_point.Y = Y;
                }
            }
            if (checkBox5.Checked)
            {
                DrawPoints(kx, ky, 10, pictureBox1.Height + 10);
                Graphics g = Graphics.FromImage(pictureBox1.Image);
                g.FillEllipse(Brushes.Red, nearest_point.X - R / 2, nearest_point.Y - R / 2, R, R);
                pictureBox1.Refresh();
            }
            label16.Text = String.Format("({0})", num + 1);
        }

        private void checkBox3_CheckedChanged(object sender, EventArgs e)
        {
            if (coords_pairs.Count == 0) return;
            if (checkBox3.Checked)
            {
                PairCoords pp = new PairCoords();
                pp.x = 0;
                pp.y = 0;
                pp.draw = true;
                coords_pairs.Add(pp);
            }
            else
            {
                coords_pairs.RemoveAt(coords_pairs.Count - 1);
            }
            InitMaxnMins();
            Draw();
        }

        private void button2_Click(object sender, EventArgs e)
        {
            SaveFileDialog form = new SaveFileDialog();
            form.AddExtension = true;
            form.DefaultExt = "jpg";
            if (form.ShowDialog() == DialogResult.OK)
                pictureBox1.Image.Save(form.FileName, System.Drawing.Imaging.ImageFormat.Jpeg);
        }

        private void checkBox4_CheckedChanged(object sender, EventArgs e)
        {
            Draw();
        }

        private void checkBox5_CheckedChanged(object sender, EventArgs e)
        {

        }


    }

    public class PairCoords
    {
        public double x;
        public double y;
        public bool draw;
    }

    public class Verticle
    {
        public int a;
        public int b;
    }
}
