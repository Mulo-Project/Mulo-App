# youtubedl-android (full 에디션): 리플렉션으로 JSON을 읽고 프로세스를 띄운다.
-keep class com.yausername.** { *; }
-keep class com.fasterxml.jackson.** { *; }
-dontwarn com.fasterxml.jackson.**
-dontwarn org.apache.commons.compress.**
-dontwarn org.tukaani.xz.**

# WorkManager / Room: 리플렉션으로 DB 구현체와 생성자를 찾는다 (release 시작 크래시 방지).
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# youtubedl-android가 압축 풀기에 쓰는 commons-compress / xz: R8이 클래스를 바꾸면
# ExtraFieldUtils 초기화에서 "is not a concrete class"로 죽는다.
-keep class org.apache.commons.compress.** { *; }
-keep class org.tukaani.xz.** { *; }
-keep class com.yausername.youtubedl_common.** { *; }
