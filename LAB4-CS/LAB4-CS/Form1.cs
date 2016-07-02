using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace LAB4_CS
{
    public partial class Form1 : Form
    {
        Matrix I = new Matrix(new double[3, 3] { { 1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 } });
        Bitmap original;
        public Form1()
        {
            InitializeComponent();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            OpenFileDialog openform = new OpenFileDialog();
            if (openform.ShowDialog() == DialogResult.OK)
            {
                pictureBox1.Image = Image.FromFile(openform.FileName);
                Bitmap bitmap = (pictureBox1.Image as Bitmap).Clone(new Rectangle(0, 0, pictureBox1.Width, pictureBox1.Height), (pictureBox1.Image as Bitmap).PixelFormat);
                original = (Bitmap)bitmap.Clone();
            }
        }
    }

    public class Matrix
    {
        private double[,] intmatr;
        public double this[int i, int j]
        {
            get { return intmatr[i, j]; }
            set { intmatr[i, j] = value; }
        }
        public static Matrix operator*(Matrix a, Matrix b)
        {
            int N = a.intmatr.Length;
            double[,] res = new double[a.intmatr.GetLength(1), b.intmatr.GetLength(0)];
            for (int i = 0; i < a.intmatr.GetLength(0); i++)
            {
                for (int j = 0; j < b.intmatr.GetLength(1); j++)
                {
                    double S = 0;
                    for (int k = 0; k < N; k++)
                    {
                        S += a[i, k] * b[k, j];
                    }
                    res[i, j] = S;
                }
            }
            return new Matrix(res);
        }
        public Matrix(double[,] a)
        {
            intmatr = a;
        }
    }
}
