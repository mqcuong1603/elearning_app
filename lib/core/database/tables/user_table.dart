import '../database_config.dart';

class UserTable {
  static const String createTable = '''
    CREATE TABLE ${DatabaseConfig.tableUsers} (
      ${DatabaseConfig.columnId} TEXT PRIMARY KEY,
      username TEXT NOT NULL UNIQUE,
      display_name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      avatar_url TEXT,
      role TEXT NOT NULL,
      phone_number TEXT,
      student_id TEXT,
      bio TEXT,
      ${DatabaseConfig.columnCreatedAt} INTEGER NOT NULL,
      last_login_at INTEGER,
      ${DatabaseConfig.columnUpdatedAt} INTEGER
    )
  ''';

  static const String indexUsername = '''
    CREATE INDEX idx_users_username ON ${DatabaseConfig.tableUsers}(username)
  ''';

  static const String indexEmail = '''
    CREATE INDEX idx_users_email ON ${DatabaseConfig.tableUsers}(email)
  ''';

  static const String indexRole = '''
    CREATE INDEX idx_users_role ON ${DatabaseConfig.tableUsers}(role)
  ''';

  static List<String> get createStatements => [
        createTable,
        indexUsername,
        indexEmail,
        indexRole,
      ];
}
