cmake_minimum_required (VERSION 3.1)

project(android_cmake_template)

string(REPLACE "_" "." JAVA_PROJECT_NAME ${PROJECT_NAME})
set(JAVA_PROJECT_NAME "com.${JAVA_PROJECT_NAME}")

string(REPLACE "_" "/" JAVA_PROJECT_PATH ${PROJECT_NAME})
set(JAVA_PROJECT_PATH "com/${JAVA_PROJECT_PATH}")

find_package(Java)

set(ANDROID_PLATFORM "/opt/android-sdk/platforms/android-28")
set(ANDROID_BUIDTOOLS "/opt/android-sdk/build-tools/28.0.0")

set(AAPT "${ANDROID_BUIDTOOLS}/aapt")

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/AndroidManifest.xml.in ${CMAKE_CURRENT_BINARY_DIR}/AndroidManifest.xml @ONLY)

file(GLOB SRC ${CMAKE_CURRENT_SOURCE_DIR}/src/${JAVA_PROJECT_PATH}/*.java)
list(REMOVE_ITEM SRC "${CMAKE_CURRENT_SOURCE_DIR}/src/${JAVA_PROJECT_PATH}/R.java")

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${JAVA_PROJECT_PATH}/R.java
	DEPENDS ${SRC}
	COMMAND ${AAPT} package -f -m -J ${CMAKE_CURRENT_BINARY_DIR}/ -M ${CMAKE_CURRENT_BINARY_DIR}/AndroidManifest.xml -S ${CMAKE_CURRENT_SOURCE_DIR}/res -I ${ANDROID_PLATFORM}/android.jar
	COMMENT "Creating R.java")

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/bin/classes.dex
	DEPENDS ${SRC} ${CMAKE_CURRENT_BINARY_DIR}/${JAVA_PROJECT_PATH}/R.java
	COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/obj
	COMMAND ${Java_JAVAC_EXECUTABLE} -d ${CMAKE_CURRENT_BINARY_DIR}/obj -classpath ${CMAKE_CURRENT_SOURCE_DIR}/src -bootclasspath /opt/android-sdk/platforms/android-28/android.jar ${SRC} ${CMAKE_CURRENT_BINARY_DIR}/${JAVA_PROJECT_PATH}/R.java
	COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/bin
	COMMAND ${ANDROID_BUIDTOOLS}/dx --dex --output=${CMAKE_CURRENT_BINARY_DIR}/bin/classes.dex ${CMAKE_CURRENT_BINARY_DIR}/obj
	COMMENT "Compiling Java sources")

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/bin/${JAVA_PROJECT_NAME}.unaligned.apk
	DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/bin/classes.dex
	COMMAND ${AAPT} package -f -m -F ${CMAKE_CURRENT_BINARY_DIR}/bin/${JAVA_PROJECT_NAME}.unaligned.apk -M ${CMAKE_CURRENT_BINARY_DIR}/AndroidManifest.xml -S ${CMAKE_CURRENT_SOURCE_DIR}/res -I ${ANDROID_PLATFORM}/android.jar
	COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/bin/classes.dex ${CMAKE_CURRENT_BINARY_DIR}/classes.dex
	COMMAND ${AAPT} add ${CMAKE_CURRENT_BINARY_DIR}/bin/${JAVA_PROJECT_NAME}.unaligned.apk classes.dex
	WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
	COMMENT "Creating unalined APK package")

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/bin/${JAVA_PROJECT_NAME}.aligned.apk
	DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/bin/${JAVA_PROJECT_NAME}.unaligned.apk
	COMMAND ${ANDROID_BUIDTOOLS}/zipalign -f 4 ${CMAKE_CURRENT_BINARY_DIR}/bin/${JAVA_PROJECT_NAME}.unaligned.apk ${CMAKE_CURRENT_BINARY_DIR}/bin/${JAVA_PROJECT_NAME}.aligned.apk
	COMMENT "Creating aligned APK package")

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/mykey.keystore
	COMMAND keytool -genkeypair -validity 365 -keystore ${CMAKE_CURRENT_BINARY_DIR}/mykey.keystore -keyalg RSA -keysize 2048
	COMMENT "Creating signature")

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/bin/${JAVA_PROJECT_NAME}.apk
	DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/bin/${JAVA_PROJECT_NAME}.aligned.apk ${CMAKE_CURRENT_BINARY_DIR}/mykey.keystore
	COMMAND ${ANDROID_BUIDTOOLS}/apksigner sign --ks ${CMAKE_CURRENT_BINARY_DIR}/mykey.keystore ${CMAKE_CURRENT_BINARY_DIR}/bin/${JAVA_PROJECT_NAME}.aligned.apk
	COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/bin/${JAVA_PROJECT_NAME}.aligned.apk ${CMAKE_CURRENT_BINARY_DIR}/bin/${JAVA_PROJECT_NAME}.apk
	COMMENT "Signing APK package")

add_custom_target(${PROJECT_NAME} ALL
	DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/bin/${JAVA_PROJECT_NAME}.apk)

# sudo adb logcat
add_custom_target(adb
	DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/bin/${JAVA_PROJECT_NAME}.apk
	COMMAND sudo adb install ${CMAKE_CURRENT_BINARY_DIR}/bin/${JAVA_PROJECT_NAME}.apk && sudo adb shell am start -n ${JAVA_PROJECT_NAME}/.MainActivity
	COMMENT "Testing APK package")

