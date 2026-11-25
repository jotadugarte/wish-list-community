// Bilingual (es / en) localized strings dictionary for mobile screens.
// Traceability: [REQ-USER-002]
class AppStrings {
  final String locale;
  final String signInTitle;
  final String emailLabel;
  final String passwordLabel;
  final String signInButton;
  final String signingInButton;
  final String navFriends;
  final String navSearch;
  final String navProfile;
  final String incomingRequestsTitle;
  final String myFriendsTitle;
  final String connectedFriendSubtitle;
  final String searchInputLabel;
  final String searchButton;
  final String addFriendButton;
  final String antiStalkingSubtitle;
  final String blockUserAction;
  final String reportUserAction;
  final String signOutButton;
  final String softDeleteAccountButton;

  const AppStrings({
    required this.locale,
    required this.signInTitle,
    required this.emailLabel,
    required this.passwordLabel,
    required this.signInButton,
    required this.signingInButton,
    required this.navFriends,
    required this.navSearch,
    required this.navProfile,
    required this.incomingRequestsTitle,
    required this.myFriendsTitle,
    required this.connectedFriendSubtitle,
    required this.searchInputLabel,
    required this.searchButton,
    required this.addFriendButton,
    required this.antiStalkingSubtitle,
    required this.blockUserAction,
    required this.reportUserAction,
    required this.signOutButton,
    required this.softDeleteAccountButton,
  });

  // [REQ-USER-002] Resolves localized strings for 'es' (default) or 'en'.
  factory AppStrings.forLocale(String rawLocale) {
    final normalized = rawLocale.trim().toLowerCase();
    return normalized == 'en' ? _en : _es;
  }

  static const AppStrings _es = AppStrings(
    locale: 'es',
    signInTitle: 'Iniciar Sesión',
    emailLabel: 'Correo electrónico',
    passwordLabel: 'Contraseña',
    signInButton: 'Entrar',
    signingInButton: 'Ingresando...',
    navFriends: 'Amigos',
    navSearch: 'Buscar',
    navProfile: 'Perfil',
    incomingRequestsTitle: 'Solicitudes Recibidas',
    myFriendsTitle: 'Mis Amigos',
    connectedFriendSubtitle: 'Amigo conectado',
    searchInputLabel: 'Buscar por @username',
    searchButton: 'Buscar',
    addFriendButton: 'Agregar',
    antiStalkingSubtitle: 'Solo perfil básico visible (Anti-Stalking)',
    blockUserAction: 'Bloquear usuario',
    reportUserAction: 'Reportar usuario',
    signOutButton: 'Cerrar Sesión',
    softDeleteAccountButton: 'Desactivar Cuenta (30 días para restaurar)',
  );

  static const AppStrings _en = AppStrings(
    locale: 'en',
    signInTitle: 'Sign In',
    emailLabel: 'Email address',
    passwordLabel: 'Password',
    signInButton: 'Sign In',
    signingInButton: 'Signing in...',
    navFriends: 'Friends',
    navSearch: 'Search',
    navProfile: 'Profile',
    incomingRequestsTitle: 'Incoming Requests',
    myFriendsTitle: 'My Friends',
    connectedFriendSubtitle: 'Connected friend',
    searchInputLabel: 'Search by @username',
    searchButton: 'Search',
    addFriendButton: 'Add Friend',
    antiStalkingSubtitle: 'Basic profile card only (Anti-Stalking)',
    blockUserAction: 'Block user',
    reportUserAction: 'Report user',
    signOutButton: 'Sign Out',
    softDeleteAccountButton: 'Deactivate Account (30-day restore window)',
  );
}
