#include <jni.h>

extern "C"
JNIEXPORT jstring JNICALL
Java_com_example_healthhome_HealthHomeTgCalls_nativeTest(
        JNIEnv* env,
        jobject /* thiz */) {

    return env->NewStringUTF("HealthHome native bridge is working");
}