import 'package:wish_list_mobile/core/network/api_client.dart';

// Bilingual (es / en) localized strings dictionary for mobile screens.
// Traceability: [REQ-USER-002]
class AppStrings {
  final String locale;
  final String signInTitle;
  final String emailLabel;
  final String passwordLabel;
  final String usernameLabel;
  final String signInButton;
  final String signingInButton;
  final String signUpLink;
  final String signUpTitle;
  final String signUpButton;
  final String signingUpButton;
  final String termsAcceptedLabel;
  final String forgotPasswordLink;
  final String passwordResetTitle;
  final String passwordResetSubmitButton;
  final String passwordResetSubmittingButton;
  final String restoreAccountLink;
  final String accountRestoreTitle;
  final String accountRestoreSubmitButton;
  final String accountRestoreSubmittingButton;
  final String accountRestoreSubtitle;
  final String navFriends;
  final String navSearch;
  final String navProfile;
  final String incomingRequestsTitle;
  final String myFriendsTitle;
  final String connectedFriendSubtitle;
  final String noConnections;
  final String searchInputLabel;
  final String searchButton;
  final String addFriendButton;
  final String antiStalkingSubtitle;
  final String blockUserAction;
  final String reportUserAction;
  final String signOutButton;
  final String softDeleteAccountButton;
  final String languageLabel;
  final String timeZoneLabel;
  final String networkError;
  final String unauthorizedError;
  final String notFoundError;
  final String conflictError;
  final String invalidDataError;
  final String invalidInputError;
  final String genericError;

  const AppStrings({
    required this.locale,
    required this.signInTitle,
    required this.emailLabel,
    required this.passwordLabel,
    required this.usernameLabel,
    required this.signInButton,
    required this.signingInButton,
    required this.signUpLink,
    required this.signUpTitle,
    required this.signUpButton,
    required this.signingUpButton,
    required this.termsAcceptedLabel,
    required this.forgotPasswordLink,
    required this.passwordResetTitle,
    required this.passwordResetSubmitButton,
    required this.passwordResetSubmittingButton,
    required this.restoreAccountLink,
    required this.accountRestoreTitle,
    required this.accountRestoreSubmitButton,
    required this.accountRestoreSubmittingButton,
    required this.accountRestoreSubtitle,
    required this.navFriends,
    required this.navSearch,
    required this.navProfile,
    required this.incomingRequestsTitle,
    required this.myFriendsTitle,
    required this.connectedFriendSubtitle,
    required this.noConnections,
    required this.searchInputLabel,
    required this.searchButton,
    required this.addFriendButton,
    required this.antiStalkingSubtitle,
    required this.blockUserAction,
    required this.reportUserAction,
    required this.signOutButton,
    required this.softDeleteAccountButton,
    required this.languageLabel,
    required this.timeZoneLabel,
    required this.networkError,
    required this.unauthorizedError,
    required this.notFoundError,
    required this.conflictError,
    required this.invalidDataError,
    required this.invalidInputError,
    required this.genericError,
  });

  // [REQ-USER-002] Resolves localized strings for 'es' (default) or 'en'.
  factory AppStrings.forLocale(String rawLocale) {
    final normalized = rawLocale.trim().toLowerCase();
    return normalized == 'en' ? _en : _es;
  }

  // [REQ-USER-002] Maps any thrown error to a friendly localized message, so raw
  // technical text (ApiException(...), ArgumentError: ...) never reaches the user.
  String errorMessage(Object error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 0:
          return networkError;
        case 401:
          return unauthorizedError;
        case 404:
          return notFoundError;
        case 409:
          return conflictError;
        case 422:
          return invalidDataError;
        default:
          return genericError;
      }
    }
    if (error is ArgumentError) return invalidInputError;
    return genericError;
  }

  static const AppStrings _es = AppStrings(
    locale: 'es',
    signInTitle: 'Iniciar Sesión',
    emailLabel: 'Correo electrónico',
    passwordLabel: 'Contraseña',
    usernameLabel: '@username',
    signInButton: 'Entrar',
    signingInButton: 'Ingresando...',
    signUpLink: 'Crear una cuenta',
    signUpTitle: 'Crear Cuenta',
    signUpButton: 'Registrarme',
    signingUpButton: 'Registrando...',
    termsAcceptedLabel: 'Acepto los Términos de Uso',
    forgotPasswordLink: '¿Olvidaste tu contraseña?',
    passwordResetTitle: 'Restablecer Contraseña',
    passwordResetSubmitButton: 'Enviar instrucciones',
    passwordResetSubmittingButton: 'Enviando...',
    restoreAccountLink: 'Restaurar cuenta desactivada',
    accountRestoreTitle: 'Restaurar Cuenta',
    accountRestoreSubmitButton: 'Restaurar cuenta',
    accountRestoreSubmittingButton: 'Restaurando...',
    accountRestoreSubtitle:
        'Puedes restaurar tu cuenta dentro de los 30 días posteriores a la desactivación.',
    navFriends: 'Amigos',
    navSearch: 'Buscar',
    navProfile: 'Perfil',
    incomingRequestsTitle: 'Solicitudes Recibidas',
    myFriendsTitle: 'Mis Amigos',
    connectedFriendSubtitle: 'Amigo conectado',
    noConnections: 'Aún no tienes conexiones',
    searchInputLabel: 'Buscar por @username',
    searchButton: 'Buscar',
    addFriendButton: 'Agregar',
    antiStalkingSubtitle: 'Solo perfil básico visible (Anti-Stalking)',
    blockUserAction: 'Bloquear usuario',
    reportUserAction: 'Reportar usuario',
    signOutButton: 'Cerrar Sesión',
    softDeleteAccountButton: 'Desactivar Cuenta (30 días para restaurar)',
    languageLabel: 'Idioma',
    timeZoneLabel: 'Zona horaria',
    networkError: 'No hay conexión con el servidor. Revisa tu internet e inténtalo de nuevo.',
    unauthorizedError: 'Credenciales inválidas o sesión expirada.',
    notFoundError: 'No se encontró lo que buscabas.',
    conflictError: 'Esta acción ya se realizó o está duplicada.',
    invalidDataError: 'Los datos enviados no son válidos.',
    invalidInputError: 'Revisa los datos ingresados.',
    genericError: 'Algo salió mal. Inténtalo de nuevo.',
  );

  static const AppStrings _en = AppStrings(
    locale: 'en',
    signInTitle: 'Sign In',
    emailLabel: 'Email address',
    passwordLabel: 'Password',
    usernameLabel: '@username',
    signInButton: 'Sign In',
    signingInButton: 'Signing in...',
    signUpLink: 'Create an account',
    signUpTitle: 'Create Account',
    signUpButton: 'Sign Up',
    signingUpButton: 'Signing up...',
    termsAcceptedLabel: 'I accept the Terms of Use',
    forgotPasswordLink: 'Forgot your password?',
    passwordResetTitle: 'Reset Password',
    passwordResetSubmitButton: 'Send instructions',
    passwordResetSubmittingButton: 'Sending...',
    restoreAccountLink: 'Restore deactivated account',
    accountRestoreTitle: 'Restore Account',
    accountRestoreSubmitButton: 'Restore account',
    accountRestoreSubmittingButton: 'Restoring...',
    accountRestoreSubtitle:
        'You can restore your account within 30 days of deactivation.',
    navFriends: 'Friends',
    navSearch: 'Search',
    navProfile: 'Profile',
    incomingRequestsTitle: 'Incoming Requests',
    myFriendsTitle: 'My Friends',
    connectedFriendSubtitle: 'Connected friend',
    noConnections: 'You have no connections yet',
    searchInputLabel: 'Search by @username',
    searchButton: 'Search',
    addFriendButton: 'Add Friend',
    antiStalkingSubtitle: 'Basic profile card only (Anti-Stalking)',
    blockUserAction: 'Block user',
    reportUserAction: 'Report user',
    signOutButton: 'Sign Out',
    softDeleteAccountButton: 'Deactivate Account (30-day restore window)',
    languageLabel: 'Language',
    timeZoneLabel: 'Time zone',
    networkError: 'Cannot reach the server. Check your internet connection and try again.',
    unauthorizedError: 'Invalid credentials or expired session.',
    notFoundError: 'We could not find what you were looking for.',
    conflictError: 'This action was already done or is a duplicate.',
    invalidDataError: 'The submitted data is not valid.',
    invalidInputError: 'Please check the data you entered.',
    genericError: 'Something went wrong. Please try again.',
  );
}
