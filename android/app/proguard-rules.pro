# Suppress missing platform classes for older plugins on modern SDKs
-dontwarn android.window.BackEvent
-dontwarn **

-keep class io.flutter.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class com.google.android.gms.ads.** { *; }
