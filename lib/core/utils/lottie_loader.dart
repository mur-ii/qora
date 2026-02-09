import 'package:lottie/lottie.dart';

/// Kelas utilitas yang didedikasikan untuk memuat dan mengelola animasi Lottie.
class LottieLoader {
  LottieLoader._(); // Private constructor

  static Future<LottieComposition?> lottieLoader(List<int> bytes) async {
    try {
      return await LottieComposition.decodeZip(
        bytes,
        filePicker: (files) {
          return files.firstWhere(
            (f) => f.name.startsWith('animations/') && f.name.endsWith('.json'),
          );
        },
      );
    } catch (e) {
      return null;
    }
  }
}
