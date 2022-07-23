dev-web:
	cd unpub_web &&\
	dart pub global activate webdev 2.7.10 &&\
	dart pub global activate webdev_proxy 0.1.6 &&\
	webdev serve

dev-api:
	cd unpub &&	dart run build_runner watch

build:
	cd unpub_web &&\
	dart pub global activate webdev 2.7.10 &&\
	dart pub global run webdev build
	dart unpub/tool/pre_publish.dart
	dart format -l 150 **/*.dart
