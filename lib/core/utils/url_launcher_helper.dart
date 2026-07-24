export 'url_launcher_stub.dart'
    if (dart.library.js) 'url_launcher_web.dart'
    if (dart.library.io) 'url_launcher_io.dart';
