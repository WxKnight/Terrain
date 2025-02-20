﻿using System;
using System.Linq;

namespace OpenCVForUnity
{

    /**
     * <p>Template class for a 4-element vector derived from Vec.</p>
     *
     * <p>template<typename _Tp> class CV_EXPORTS Scalar_ : public Vec<_Tp, 4> <code></p>
     *
     * <p>// C++ code:</p>
     *
     *
     * <p>public:</p>
     *
     * <p>//! various constructors</p>
     *
     * <p>Scalar_();</p>
     *
     * <p>Scalar_(_Tp v0, _Tp v1, _Tp v2=0, _Tp v3=0);</p>
     *
     * <p>Scalar_(const CvScalar& s);</p>
     *
     * <p>Scalar_(_Tp v0);</p>
     *
     * <p>//! returns a scalar with all elements set to v0</p>
     *
     * <p>static Scalar_<_Tp> all(_Tp v0);</p>
     *
     * <p>//! conversion to the old-style CvScalar</p>
     *
     * <p>operator CvScalar() const;</p>
     *
     * <p>//! conversion to another data type</p>
     *
     * <p>template<typename T2> operator Scalar_<T2>() const;</p>
     *
     * <p>//! per-element product</p>
     *
     * <p>Scalar_<_Tp> mul(const Scalar_<_Tp>& t, double scale=1) const;</p>
     *
     * <p>// returns (v0, -v1, -v2, -v3)</p>
     *
     * <p>Scalar_<_Tp> conj() const;</p>
     *
     * <p>// returns true iff v1 == v2 == v3 == 0</p>
     *
     * <p>bool isReal() const;</p>
     *
     * <p>};</p>
     *
     * <p>typedef Scalar_<double> Scalar;</p>
     *
     * <p>Being derived from <code>Vec<_Tp, 4></code>, <code>Scalar_</code> and
     * <code>Scalar</code> can be used just as typical 4-element vectors. In
     * addition, they can be converted to/from <code>CvScalar</code>. The type
     * <code>Scalar</code> is widely used in OpenCV to pass pixel values.
     * </code></p>
     *
     * @see <a href="http://docs.opencv.org/modules/core/doc/basic_structures.html#scalar">org.opencv.core.Scalar_</a>
     */
    [System.Serializable]
    public class Scalar : IEquatable<Scalar>
    {

        public double[] val;

        public Scalar (double v0, double v1, double v2, double v3)
        {
            val = new double[] { v0, v1, v2, v3 };
        }

        public Scalar (double v0, double v1, double v2)
        {
            val = new double[] { v0, v1, v2, 0 };
        }

        public Scalar (double v0, double v1)
        {
            val = new double[] { v0, v1, 0, 0 };
        }

        public Scalar (double v0)
        {
            val = new double[] { v0, 0, 0, 0 };
        }

        public Scalar (double[] vals)
        {
            if (vals != null && vals.Length == 4)
                val = (double[])vals.Clone ();
            else {
                val = new double[4];
                set (vals);
            }
        }

        public void set (double[] vals)
        {
            if (vals != null) {
                val [0] = vals.Length > 0 ? vals [0] : 0;
                val [1] = vals.Length > 1 ? vals [1] : 0;
                val [2] = vals.Length > 2 ? vals [2] : 0;
                val [3] = vals.Length > 3 ? vals [3] : 0;
            } else
                val [0] = val [1] = val [2] = val [3] = 0;
        }

        public static Scalar all (double v)
        {
            return new Scalar (v, v, v, v);
        }

        public Scalar clone ()
        {
            return new Scalar (val);
        }

        public Scalar mul (Scalar it, double scale)
        {
            return new Scalar (val [0] * it.val [0] * scale, val [1] * it.val [1] * scale,
                val [2] * it.val [2] * scale, val [3] * it.val [3] * scale);
        }

        public Scalar mul (Scalar it)
        {
            return mul (it, 1);
        }

        public Scalar conj ()
        {
            return new Scalar (val [0], -val [1], -val [2], -val [3]);
        }

        public bool isReal ()
        {
            return val [1] == 0 && val [2] == 0 && val [3] == 0;
        }

        //@Override
        public override int GetHashCode ()
        {
            const int prime = 31;
            int result = 1;
            //      result = prime * result + java.util.Arrays.hashCode(val);//TODO: @CHECK
            result = prime * result + Utils.HashContents (val);
            return result;
        }

        //@Override
        public override bool Equals (Object obj)
        {
            if (!(obj is Scalar))
                return false;
            if ((Scalar)obj == this)
                return true;

            Scalar it = (Scalar)obj;
            //      if (!java.util.Arrays.equals(val, it.val)) return false;//TODO: @CHECK
            if (!val.SequenceEqual (it.val))
                return false;
            return true;
        }

        //@Override
        public override string ToString ()
        {
            return "[" + val [0] + ", " + val [1] + ", " + val [2] + ", " + val [3] + "]";
        }

        //

        #region Operators

        // (here s stand for a scalar ( Scalar ), alpha for a real-valued scalar ( double ).)

        #region Unary

        // -s
        public static Scalar operator - (Scalar a)
        {
            return new Scalar (-a.val [0], -a.val [1], -a.val [2], -a.val [3]);
        }

        #endregion

        #region Binary

        // s + s
        public static Scalar operator + (Scalar a, Scalar b)
        {
            return new Scalar (a.val [0] + b.val [0], a.val [1] + b.val [1], a.val [2] + b.val [2], a.val [3] + b.val [3]);
        }

        // s - s
        public static Scalar operator - (Scalar a, Scalar b)
        {
            return new Scalar (a.val [0] - b.val [0], a.val [1] - b.val [1], a.val [2] - b.val [2], a.val [3] - b.val [3]);
        }

        // s * s, s * alpha, alpha * s
        public static Scalar operator * (Scalar a, Scalar b)
        {
            return new Scalar ((a.val [0] * b.val [0] - a.val [1] * b.val [1] - a.val [2] * b.val [2] - a.val [3] * b.val [3]),
                (a.val [0] * b.val [1] + a.val [1] * b.val [0] + a.val [2] * b.val [3] - a.val [3] * b.val [2]),
                (a.val [0] * b.val [2] - a.val [1] * b.val [3] + a.val [2] * b.val [0] + a.val [3] * b.val [1]),
                (a.val [0] * b.val [3] + a.val [1] * b.val [2] - a.val [2] * b.val [1] + a.val [3] * b.val [0]));
        }

        public static Scalar operator * (Scalar a, double alpha)
        {
            return new Scalar (a.val [0] * alpha, a.val [1] * alpha, a.val [2] * alpha, a.val [3] * alpha);
        }

        public static Scalar operator * (double alpha, Scalar a)
        {
            return a * alpha;
        }

        // s / s, s / alpha, alpha / s
        public static Scalar operator / (Scalar a, Scalar b)
        {
            return a * (1 / b);
        }

        public static Scalar operator / (Scalar a, double alpha)
        {
            double s = 1 / alpha;
            return new Scalar (a.val [0] * s, a.val [1] * s, a.val [2] * s, a.val [3] * s);
        }

        public static Scalar operator / (double a, Scalar b)
        {
            double s = a / (b.val [0] * b.val [0] + b.val [1] * b.val [1] + b.val [2] * b.val [2] + b.val [3] * b.val [3]);
            return b.conj () * s;
        }

        #endregion

        #region Comparison

        public bool Equals (Scalar a)
        {
            // If both are same instance, return true.
            if (System.Object.ReferenceEquals (this, a)) {
                return true;
            }

            // If object is null, return false.
            if ((object)a == null) {
                return false;
            }

            // Return true if the fields match:
            if (!this.val.SequenceEqual (a.val))
                return false;
            return true;
        }

        // s == s
        public static bool operator == (Scalar a, Scalar b)
        {
            // If both are null, or both are same instance, return true.
            if (System.Object.ReferenceEquals (a, b)) {
                return true;
            }

            // If one is null, but not both, return false.
            if (((object)a == null) || ((object)b == null)) {
                return false;
            }

            // Return true if the fields match:
            if (!a.val.SequenceEqual (b.val))
                return false;
            return true;
        }

        // s != s
        public static bool operator != (Scalar a, Scalar b)
        {
            return !(a == b);
        }

        #endregion

        #endregion

        //
    }
}
