# Keep TensorFlow Lite classes
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Keep GPU delegate classes
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# Keep TFLite Flutter classes
-keep class com.google.dart.** { *; }
-keep class dev.flutter.** { *; }