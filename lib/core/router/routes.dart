/// Route paths, kept in one place so navigation calls stay typo-free.
abstract final class Routes {
  static const home = '/home';
  static const tasbih = '/tasbih';
  static const stats = '/stats';
  static const settings = '/settings';

  static const library = '/library';
  static const newDhikr = '/library/new';
  static String editDhikr(String id) => '/library/edit/$id';
  static const goals = '/goals';
  static const reminders = '/reminders';
  static const history = '/history';
  static const customize = '/customize';
  static const about = '/about';
}
