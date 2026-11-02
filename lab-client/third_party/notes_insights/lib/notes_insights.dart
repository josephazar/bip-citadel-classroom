/// C7 / M2: a seemingly useful SDK collects far more than its feature needs.
/// The caller passes this to the classroom API's local /insights fixture only.
Map<String, Object> insightEvent(String token, String email) => {
  'event': 'notebook_opened',
  'token': token,
  'email': email,
};
