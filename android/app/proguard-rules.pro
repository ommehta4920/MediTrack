# Fix flutter_local_notifications crash
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# VERY IMPORTANT: keep generic type info
-keepattributes Signature

# Gson (used internally)
-keep class com.google.gson.** { *; }
-keepattributes *Annotation*