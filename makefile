PROJ := $(shell pwd)
ANDROID_PLATFORM := /opt/android-sdk/platforms/android-28
ANDROID_BUIDTOOLS := /opt/android-sdk/build-tools/28.0.0

all: $(PROJ)/bin/hello.apk

src/com/example/helloandroid/R.java:
	$(ANDROID_BUIDTOOLS)/aapt package -f -m -J $(PROJ)/src -M $(PROJ)/AndroidManifest.xml -S $(PROJ)/res -I $(ANDROID_PLATFORM)/android.jar
	
$(PROJ)/bin/classes.dex: src/com/example/helloandroid/MainActivity.java src/com/example/helloandroid/R.java
	javac -d obj -classpath src -bootclasspath /opt/android-sdk/platforms/android-28/android.jar $^ && \
	$(ANDROID_BUIDTOOLS)/dx --dex --output=$@ $(PROJ)/obj

$(PROJ)/bin/hello.unaligned.apk: $(PROJ)/bin/classes.dex
	$(ANDROID_BUIDTOOLS)/aapt package -f -m -F $@ -M $(PROJ)/AndroidManifest.xml -S $(PROJ)/res -I $(ANDROID_PLATFORM)/android.jar && \
	cp $(PROJ)/bin/classes.dex . && \
	$(ANDROID_BUIDTOOLS)/aapt add $(PROJ)/bin/hello.unaligned.apk classes.dex

$(PROJ)/bin/hello.aligned.apk: $(PROJ)/bin/hello.unaligned.apk
	$(ANDROID_BUIDTOOLS)/zipalign -f 4 $^ $@

$(PROJ)/bin/hello.apk: $(PROJ)/bin/hello.aligned.apk
	$(ANDROID_BUIDTOOLS)/apksigner sign --ks mykey.keystore $< && \
	cp $< $@

# sudo adb logcat
test: $(PROJ)/bin/hello.apk
	sudo adb install $(PROJ)/bin/hello.apk && \
	sudo adb shell am start -n com.example.helloandroid/.MainActivity

clean:
	rm -rf src/com/example/helloandroid/R.java obj/com/example/helloandroid/*.class $(PROJ)/bin/classes.dex $(PROJ)/bin/hello.unaligned.apk $(PROJ)/bin/hello.aligned.apk $(PROJ)/bin/hello.apk

