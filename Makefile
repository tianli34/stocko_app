.PHONY: build-gen clean-gen watch-gen

build-gen:
	flutter pub get
	flutter pub run build_runner build --delete-conflicting-outputs

clean-gen:
	flutter pub run build_runner clean

watch-gen:
	flutter pub run build_runner watch --delete-conflicting-outputs
