# Flutter core and embedding
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# AndroidX file provider used in AndroidManifest
-keep class androidx.core.content.FileProvider { *; }

# Google ML Kit (text recognition and related internal classes)
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Tesseract OCR (flutter_tesseract_ocr / tess-two)
-keep class io.paratoner.flutter_tesseract_ocr.** { *; }
-keep class com.googlecode.tesseract.android.** { *; }
-dontwarn com.googlecode.tesseract.android.**

# PDF viewer (flutter_pdfview / AndroidPdfViewer)
-keep class com.github.barteksc.pdfviewer.** { *; }
-keep class com.shockwave.pdfium.** { *; }
-dontwarn com.shockwave.pdfium.**

# Keep Kotlin metadata (helps reflection when used)
-keep class kotlin.Metadata { *; }

# Keep application activities and main launcher
-keep class ** extends android.app.Activity { *; }

# Prevent warnings for generated resources and build configs
-dontwarn **.R
-dontwarn **.R$*
-dontwarn **.BuildConfig
