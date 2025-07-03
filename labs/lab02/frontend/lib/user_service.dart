class UserService {
  Future<Map<String, String>> fetchUser() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return {'name': 'Default User', 'email': 'default@example.com'};
  }
}
