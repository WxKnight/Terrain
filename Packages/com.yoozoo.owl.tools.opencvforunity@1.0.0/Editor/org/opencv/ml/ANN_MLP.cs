
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace OpenCVForUnity
{

    // C++: class ANN_MLP
    //javadoc: ANN_MLP

    public class ANN_MLP : StatModel
    {

        protected override void Dispose (bool disposing)
        {
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
            try {
                if (disposing) {
                }
                if (IsEnabledDispose) {
                    if (nativeObj != IntPtr.Zero)
                        ml_ANN_1MLP_delete (nativeObj);
                    nativeObj = IntPtr.Zero;
                }
            } finally {
                base.Dispose (disposing);
            }
#else
            return;
#endif
        }

        protected internal ANN_MLP (IntPtr addr)
            : base (addr)
        {
        }

        // internal usage only
        public static new ANN_MLP __fromPtr__ (IntPtr addr)
        {
            return new ANN_MLP (addr);
        }

        public const int BACKPROP = 0;
        public const int RPROP = 1;
        public const int ANNEAL = 2;
        public const int IDENTITY = 0;
        public const int SIGMOID_SYM = 1;
        public const int GAUSSIAN = 2;
        public const int RELU = 3;
        public const int LEAKYRELU = 4;
        public const int UPDATE_WEIGHTS = 1;
        public const int NO_INPUT_SCALE = 2;
        public const int NO_OUTPUT_SCALE = 4;
        //
        // C++:  Mat getLayerSizes()
        //

        //javadoc: ANN_MLP::getLayerSizes()
        public Mat getLayerSizes ()
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            Mat retVal = new Mat (ml_ANN_1MLP_getLayerSizes_10 (nativeObj));
        
            return retVal;
#else
            return null;
#endif
        }


        //
        // C++:  Mat getWeights(int layerIdx)
        //

        //javadoc: ANN_MLP::getWeights(layerIdx)
        public Mat getWeights (int layerIdx)
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            Mat retVal = new Mat (ml_ANN_1MLP_getWeights_10 (nativeObj, layerIdx));
        
            return retVal;
#else
            return null;
#endif
        }


        //
        // C++: static Ptr_ANN_MLP create()
        //

        //javadoc: ANN_MLP::create()
        public static ANN_MLP create ()
        {
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            ANN_MLP retVal = ANN_MLP.__fromPtr__ (ml_ANN_1MLP_create_10 ());
        
            return retVal;
#else
            return null;
#endif
        }


        //
        // C++: static Ptr_ANN_MLP load(String filepath)
        //

        //javadoc: ANN_MLP::load(filepath)
        public static ANN_MLP load (string filepath)
        {
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            ANN_MLP retVal = ANN_MLP.__fromPtr__ (ml_ANN_1MLP_load_10 (filepath));
        
            return retVal;
#else
            return null;
#endif
        }


        //
        // C++:  TermCriteria getTermCriteria()
        //

        //javadoc: ANN_MLP::getTermCriteria()
        public TermCriteria getTermCriteria ()
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            double[] tmpArray = new double[3];
            ml_ANN_1MLP_getTermCriteria_10 (nativeObj, tmpArray);
            TermCriteria retVal = new TermCriteria (tmpArray);
        
            return retVal;
#else
            return null;
#endif
        }


        //
        // C++:  double getAnnealCoolingRatio()
        //

        //javadoc: ANN_MLP::getAnnealCoolingRatio()
        public virtual double getAnnealCoolingRatio ()
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            double retVal = ml_ANN_1MLP_getAnnealCoolingRatio_10 (nativeObj);
        
            return retVal;
#else
            return -1;
#endif
        }


        //
        // C++:  double getAnnealFinalT()
        //

        //javadoc: ANN_MLP::getAnnealFinalT()
        public virtual double getAnnealFinalT ()
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            double retVal = ml_ANN_1MLP_getAnnealFinalT_10 (nativeObj);
        
            return retVal;
#else
            return -1;
#endif
        }


        //
        // C++:  double getAnnealInitialT()
        //

        //javadoc: ANN_MLP::getAnnealInitialT()
        public virtual double getAnnealInitialT ()
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            double retVal = ml_ANN_1MLP_getAnnealInitialT_10 (nativeObj);
        
            return retVal;
#else
            return -1;
#endif
        }


        //
        // C++:  double getBackpropMomentumScale()
        //

        //javadoc: ANN_MLP::getBackpropMomentumScale()
        public double getBackpropMomentumScale ()
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            double retVal = ml_ANN_1MLP_getBackpropMomentumScale_10 (nativeObj);
        
            return retVal;
#else
            return -1;
#endif
        }


        //
        // C++:  double getBackpropWeightScale()
        //

        //javadoc: ANN_MLP::getBackpropWeightScale()
        public double getBackpropWeightScale ()
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            double retVal = ml_ANN_1MLP_getBackpropWeightScale_10 (nativeObj);
        
            return retVal;
#else
            return -1;
#endif
        }


        //
        // C++:  double getRpropDW0()
        //

        //javadoc: ANN_MLP::getRpropDW0()
        public double getRpropDW0 ()
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            double retVal = ml_ANN_1MLP_getRpropDW0_10 (nativeObj);
        
            return retVal;
#else
            return -1;
#endif
        }


        //
        // C++:  double getRpropDWMax()
        //

        //javadoc: ANN_MLP::getRpropDWMax()
        public double getRpropDWMax ()
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            double retVal = ml_ANN_1MLP_getRpropDWMax_10 (nativeObj);
        
            return retVal;
#else
            return -1;
#endif
        }


        //
        // C++:  double getRpropDWMin()
        //

        //javadoc: ANN_MLP::getRpropDWMin()
        public double getRpropDWMin ()
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            double retVal = ml_ANN_1MLP_getRpropDWMin_10 (nativeObj);
        
            return retVal;
#else
            return -1;
#endif
        }


        //
        // C++:  double getRpropDWMinus()
        //

        //javadoc: ANN_MLP::getRpropDWMinus()
        public double getRpropDWMinus ()
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            double retVal = ml_ANN_1MLP_getRpropDWMinus_10 (nativeObj);
        
            return retVal;
#else
            return -1;
#endif
        }


        //
        // C++:  double getRpropDWPlus()
        //

        //javadoc: ANN_MLP::getRpropDWPlus()
        public double getRpropDWPlus ()
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            double retVal = ml_ANN_1MLP_getRpropDWPlus_10 (nativeObj);
        
            return retVal;
#else
            return -1;
#endif
        }


        //
        // C++:  int getAnnealItePerStep()
        //

        //javadoc: ANN_MLP::getAnnealItePerStep()
        public virtual int getAnnealItePerStep ()
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            int retVal = ml_ANN_1MLP_getAnnealItePerStep_10 (nativeObj);
        
            return retVal;
#else
            return -1;
#endif
        }


        //
        // C++:  int getTrainMethod()
        //

        //javadoc: ANN_MLP::getTrainMethod()
        public int getTrainMethod ()
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            int retVal = ml_ANN_1MLP_getTrainMethod_10 (nativeObj);
        
            return retVal;
#else
            return -1;
#endif
        }


        //
        // C++:  void setActivationFunction(int type, double param1 = 0, double param2 = 0)
        //

        //javadoc: ANN_MLP::setActivationFunction(type, param1, param2)
        public void setActivationFunction (int type, double param1, double param2)
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            ml_ANN_1MLP_setActivationFunction_10 (nativeObj, type, param1, param2);
        
            return;
#else
            return;
#endif
        }

        //javadoc: ANN_MLP::setActivationFunction(type)
        public void setActivationFunction (int type)
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            ml_ANN_1MLP_setActivationFunction_11 (nativeObj, type);
        
            return;
#else
            return;
#endif
        }


        //
        // C++:  void setAnnealCoolingRatio(double val)
        //

        //javadoc: ANN_MLP::setAnnealCoolingRatio(val)
        public virtual void setAnnealCoolingRatio (double val)
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            ml_ANN_1MLP_setAnnealCoolingRatio_10 (nativeObj, val);
        
            return;
#else
            return;
#endif
        }


        //
        // C++:  void setAnnealFinalT(double val)
        //

        //javadoc: ANN_MLP::setAnnealFinalT(val)
        public virtual void setAnnealFinalT (double val)
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            ml_ANN_1MLP_setAnnealFinalT_10 (nativeObj, val);
        
            return;
#else
            return;
#endif
        }


        //
        // C++:  void setAnnealInitialT(double val)
        //

        //javadoc: ANN_MLP::setAnnealInitialT(val)
        public virtual void setAnnealInitialT (double val)
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            ml_ANN_1MLP_setAnnealInitialT_10 (nativeObj, val);
        
            return;
#else
            return;
#endif
        }


        //
        // C++:  void setAnnealItePerStep(int val)
        //

        //javadoc: ANN_MLP::setAnnealItePerStep(val)
        public virtual void setAnnealItePerStep (int val)
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            ml_ANN_1MLP_setAnnealItePerStep_10 (nativeObj, val);
        
            return;
#else
            return;
#endif
        }


        //
        // C++:  void setBackpropMomentumScale(double val)
        //

        //javadoc: ANN_MLP::setBackpropMomentumScale(val)
        public void setBackpropMomentumScale (double val)
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            ml_ANN_1MLP_setBackpropMomentumScale_10 (nativeObj, val);
        
            return;
#else
            return;
#endif
        }


        //
        // C++:  void setBackpropWeightScale(double val)
        //

        //javadoc: ANN_MLP::setBackpropWeightScale(val)
        public void setBackpropWeightScale (double val)
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            ml_ANN_1MLP_setBackpropWeightScale_10 (nativeObj, val);
        
            return;
#else
            return;
#endif
        }


        //
        // C++:  void setLayerSizes(Mat _layer_sizes)
        //

        //javadoc: ANN_MLP::setLayerSizes(_layer_sizes)
        public void setLayerSizes (Mat _layer_sizes)
        {
            ThrowIfDisposed ();
            if (_layer_sizes != null)
                _layer_sizes.ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            ml_ANN_1MLP_setLayerSizes_10 (nativeObj, _layer_sizes.nativeObj);
        
            return;
#else
            return;
#endif
        }


        //
        // C++:  void setRpropDW0(double val)
        //

        //javadoc: ANN_MLP::setRpropDW0(val)
        public void setRpropDW0 (double val)
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            ml_ANN_1MLP_setRpropDW0_10 (nativeObj, val);
        
            return;
#else
            return;
#endif
        }


        //
        // C++:  void setRpropDWMax(double val)
        //

        //javadoc: ANN_MLP::setRpropDWMax(val)
        public void setRpropDWMax (double val)
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            ml_ANN_1MLP_setRpropDWMax_10 (nativeObj, val);
        
            return;
#else
            return;
#endif
        }


        //
        // C++:  void setRpropDWMin(double val)
        //

        //javadoc: ANN_MLP::setRpropDWMin(val)
        public void setRpropDWMin (double val)
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            ml_ANN_1MLP_setRpropDWMin_10 (nativeObj, val);
        
            return;
#else
            return;
#endif
        }


        //
        // C++:  void setRpropDWMinus(double val)
        //

        //javadoc: ANN_MLP::setRpropDWMinus(val)
        public void setRpropDWMinus (double val)
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            ml_ANN_1MLP_setRpropDWMinus_10 (nativeObj, val);
        
            return;
#else
            return;
#endif
        }


        //
        // C++:  void setRpropDWPlus(double val)
        //

        //javadoc: ANN_MLP::setRpropDWPlus(val)
        public void setRpropDWPlus (double val)
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            ml_ANN_1MLP_setRpropDWPlus_10 (nativeObj, val);
        
            return;
#else
            return;
#endif
        }


        //
        // C++:  void setTermCriteria(TermCriteria val)
        //

        //javadoc: ANN_MLP::setTermCriteria(val)
        public void setTermCriteria (TermCriteria val)
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            ml_ANN_1MLP_setTermCriteria_10 (nativeObj, val.type, val.maxCount, val.epsilon);
        
            return;
#else
            return;
#endif
        }


        //
        // C++:  void setTrainMethod(int method, double param1 = 0, double param2 = 0)
        //

        //javadoc: ANN_MLP::setTrainMethod(method, param1, param2)
        public void setTrainMethod (int method, double param1, double param2)
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            ml_ANN_1MLP_setTrainMethod_10 (nativeObj, method, param1, param2);
        
            return;
#else
            return;
#endif
        }

        //javadoc: ANN_MLP::setTrainMethod(method)
        public void setTrainMethod (int method)
        {
            ThrowIfDisposed ();
#if UNITY_PRO_LICENSE || ((UNITY_ANDROID || UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR) || UNITY_5 || UNITY_5_3_OR_NEWER
        
            ml_ANN_1MLP_setTrainMethod_11 (nativeObj, method);
        
            return;
#else
            return;
#endif
        }


#if (UNITY_IOS || UNITY_WEBGL) && !UNITY_EDITOR
        const string LIBNAME = "__Internal";
        







#else
        const string LIBNAME = "opencvforunity";
#endif



        // C++:  Mat getLayerSizes()
        [DllImport (LIBNAME)]
        private static extern IntPtr ml_ANN_1MLP_getLayerSizes_10 (IntPtr nativeObj);

        // C++:  Mat getWeights(int layerIdx)
        [DllImport (LIBNAME)]
        private static extern IntPtr ml_ANN_1MLP_getWeights_10 (IntPtr nativeObj, int layerIdx);

        // C++: static Ptr_ANN_MLP create()
        [DllImport (LIBNAME)]
        private static extern IntPtr ml_ANN_1MLP_create_10 ();

        // C++: static Ptr_ANN_MLP load(String filepath)
        [DllImport (LIBNAME)]
        private static extern IntPtr ml_ANN_1MLP_load_10 (string filepath);

        // C++:  TermCriteria getTermCriteria()
        [DllImport (LIBNAME)]
        private static extern void ml_ANN_1MLP_getTermCriteria_10 (IntPtr nativeObj, double[] retVal);

        // C++:  double getAnnealCoolingRatio()
        [DllImport (LIBNAME)]
        private static extern double ml_ANN_1MLP_getAnnealCoolingRatio_10 (IntPtr nativeObj);

        // C++:  double getAnnealFinalT()
        [DllImport (LIBNAME)]
        private static extern double ml_ANN_1MLP_getAnnealFinalT_10 (IntPtr nativeObj);

        // C++:  double getAnnealInitialT()
        [DllImport (LIBNAME)]
        private static extern double ml_ANN_1MLP_getAnnealInitialT_10 (IntPtr nativeObj);

        // C++:  double getBackpropMomentumScale()
        [DllImport (LIBNAME)]
        private static extern double ml_ANN_1MLP_getBackpropMomentumScale_10 (IntPtr nativeObj);

        // C++:  double getBackpropWeightScale()
        [DllImport (LIBNAME)]
        private static extern double ml_ANN_1MLP_getBackpropWeightScale_10 (IntPtr nativeObj);

        // C++:  double getRpropDW0()
        [DllImport (LIBNAME)]
        private static extern double ml_ANN_1MLP_getRpropDW0_10 (IntPtr nativeObj);

        // C++:  double getRpropDWMax()
        [DllImport (LIBNAME)]
        private static extern double ml_ANN_1MLP_getRpropDWMax_10 (IntPtr nativeObj);

        // C++:  double getRpropDWMin()
        [DllImport (LIBNAME)]
        private static extern double ml_ANN_1MLP_getRpropDWMin_10 (IntPtr nativeObj);

        // C++:  double getRpropDWMinus()
        [DllImport (LIBNAME)]
        private static extern double ml_ANN_1MLP_getRpropDWMinus_10 (IntPtr nativeObj);

        // C++:  double getRpropDWPlus()
        [DllImport (LIBNAME)]
        private static extern double ml_ANN_1MLP_getRpropDWPlus_10 (IntPtr nativeObj);

        // C++:  int getAnnealItePerStep()
        [DllImport (LIBNAME)]
        private static extern int ml_ANN_1MLP_getAnnealItePerStep_10 (IntPtr nativeObj);

        // C++:  int getTrainMethod()
        [DllImport (LIBNAME)]
        private static extern int ml_ANN_1MLP_getTrainMethod_10 (IntPtr nativeObj);

        // C++:  void setActivationFunction(int type, double param1 = 0, double param2 = 0)
        [DllImport (LIBNAME)]
        private static extern void ml_ANN_1MLP_setActivationFunction_10 (IntPtr nativeObj, int type, double param1, double param2);

        [DllImport (LIBNAME)]
        private static extern void ml_ANN_1MLP_setActivationFunction_11 (IntPtr nativeObj, int type);

        // C++:  void setAnnealCoolingRatio(double val)
        [DllImport (LIBNAME)]
        private static extern void ml_ANN_1MLP_setAnnealCoolingRatio_10 (IntPtr nativeObj, double val);

        // C++:  void setAnnealFinalT(double val)
        [DllImport (LIBNAME)]
        private static extern void ml_ANN_1MLP_setAnnealFinalT_10 (IntPtr nativeObj, double val);

        // C++:  void setAnnealInitialT(double val)
        [DllImport (LIBNAME)]
        private static extern void ml_ANN_1MLP_setAnnealInitialT_10 (IntPtr nativeObj, double val);

        // C++:  void setAnnealItePerStep(int val)
        [DllImport (LIBNAME)]
        private static extern void ml_ANN_1MLP_setAnnealItePerStep_10 (IntPtr nativeObj, int val);

        // C++:  void setBackpropMomentumScale(double val)
        [DllImport (LIBNAME)]
        private static extern void ml_ANN_1MLP_setBackpropMomentumScale_10 (IntPtr nativeObj, double val);

        // C++:  void setBackpropWeightScale(double val)
        [DllImport (LIBNAME)]
        private static extern void ml_ANN_1MLP_setBackpropWeightScale_10 (IntPtr nativeObj, double val);

        // C++:  void setLayerSizes(Mat _layer_sizes)
        [DllImport (LIBNAME)]
        private static extern void ml_ANN_1MLP_setLayerSizes_10 (IntPtr nativeObj, IntPtr _layer_sizes_nativeObj);

        // C++:  void setRpropDW0(double val)
        [DllImport (LIBNAME)]
        private static extern void ml_ANN_1MLP_setRpropDW0_10 (IntPtr nativeObj, double val);

        // C++:  void setRpropDWMax(double val)
        [DllImport (LIBNAME)]
        private static extern void ml_ANN_1MLP_setRpropDWMax_10 (IntPtr nativeObj, double val);

        // C++:  void setRpropDWMin(double val)
        [DllImport (LIBNAME)]
        private static extern void ml_ANN_1MLP_setRpropDWMin_10 (IntPtr nativeObj, double val);

        // C++:  void setRpropDWMinus(double val)
        [DllImport (LIBNAME)]
        private static extern void ml_ANN_1MLP_setRpropDWMinus_10 (IntPtr nativeObj, double val);

        // C++:  void setRpropDWPlus(double val)
        [DllImport (LIBNAME)]
        private static extern void ml_ANN_1MLP_setRpropDWPlus_10 (IntPtr nativeObj, double val);

        // C++:  void setTermCriteria(TermCriteria val)
        [DllImport (LIBNAME)]
        private static extern void ml_ANN_1MLP_setTermCriteria_10 (IntPtr nativeObj, int val_type, int val_maxCount, double val_epsilon);

        // C++:  void setTrainMethod(int method, double param1 = 0, double param2 = 0)
        [DllImport (LIBNAME)]
        private static extern void ml_ANN_1MLP_setTrainMethod_10 (IntPtr nativeObj, int method, double param1, double param2);

        [DllImport (LIBNAME)]
        private static extern void ml_ANN_1MLP_setTrainMethod_11 (IntPtr nativeObj, int method);

        // native support for java finalize()
        [DllImport (LIBNAME)]
        private static extern void ml_ANN_1MLP_delete (IntPtr nativeObj);

    }
}
