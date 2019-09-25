class Algorithms {
  static String capitalizeFirstLetterAndLowercase(String s) {
    if (s != null && s.length > 1) {
      // not very efficient algorithm
      return "${s[0].toUpperCase()}${s.substring(1).toLowerCase()}";
    } else {
      return s;
    }
  }

  static String capitalizeFirstLetter(String s) {
    if (s != null && s.isNotEmpty) {
      return "${s[0].toUpperCase()}${s.length > 1 ? s.substring(1) : ""}";
    } else {
      return s;
    }
  }

  static bool isEmpty(String s) => s == null || s == "";

  static bool isNotEmpty(String s) => s != null && s.isNotEmpty;
}
