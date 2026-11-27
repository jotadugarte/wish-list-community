import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/values/domain_values.dart';

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
  final String navWishlists;
  final String navShared;
  final String myWishlistsTitle;
  final String sharedWithMeTitle;
  final String friendWishlistsTitle;
  final String wishlistDetailTitle;
  final String wishlistTitleLabel;
  final String createWishlistButton;
  final String noWishlistsYet;
  final String noSharedWishlists;
  final String noFriendWishlists;
  final String wishlistEmptyShellHint;
  final String addItemButton;
  final String editItemTitle;
  final String itemTitleLabel;
  final String itemSpecsLabel;
  final String itemPriorityLabel;
  final String itemLinksLabel;
  final String itemPriceLabel;
  final String itemCurrencyLabel;
  final String pasteStoreUrlLabel;
  final String previewLinkButton;
  final String confirmPreviewButton;
  final String noItemsYet;
  final String saveItemButton;
  final String privacyModeLabel;
  final String privacyFriendsLabel;
  final String privacySharedLabel;
  final String secretLinkLabel;
  final String copySecretLinkButton;
  final String rotateSecretLinkButton;
  final String viewWishlistsAction;
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
  final String reportWishlistAction;
  final String reportWishlistSuccess;
  final String reportWishlistDuplicate;
  final String reportWishlistUnavailable;
  final String reportReasonLabel;
  final String reportSubmitButton;
  final String rateLimitedError;
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
  final String myReservationsTitle;
  final String noReservationsYet;
  final String reserveButton;
  final String extendReservationButton;
  final String cancelReservationButton;
  final String markPurchasedButton;
  final String markDeliveredButton;
  final String markReceivedButton;
  final String confirmReceivedButton;
  final String thankYouOptionalLabel;
  final String receivedGiftsTitle;
  final String confirmVoidGiftsMessage;
  final String estimatedDateLabel;
  final String availabilityAvailable;
  final String availabilityReservedByMe;
  final String availabilityUnavailable;
  final String openMyReservationsAction;
  final String navInbox;
  final String inboxTitle;
  final String noNotificationsYet;
  final String notificationPrefsTitle;
  final String pushChannelLabel;
  final String emailChannelLabel;
  final String inAppChannelLabel;
  final String termsLinkLabel;
  final String privacyLinkLabel;
  final String openLegalLinkAction;
  final String addPhotosGalleryButton;
  final String addPhotoCameraButton;
  final String selectedPhotosLabel;

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
    required this.navWishlists,
    required this.navShared,
    required this.myWishlistsTitle,
    required this.sharedWithMeTitle,
    required this.friendWishlistsTitle,
    required this.wishlistDetailTitle,
    required this.wishlistTitleLabel,
    required this.createWishlistButton,
    required this.noWishlistsYet,
    required this.noSharedWishlists,
    required this.noFriendWishlists,
    required this.wishlistEmptyShellHint,
    required this.addItemButton,
    required this.editItemTitle,
    required this.itemTitleLabel,
    required this.itemSpecsLabel,
    required this.itemPriorityLabel,
    required this.itemLinksLabel,
    required this.itemPriceLabel,
    required this.itemCurrencyLabel,
    required this.pasteStoreUrlLabel,
    required this.previewLinkButton,
    required this.confirmPreviewButton,
    required this.noItemsYet,
    required this.saveItemButton,
    required this.privacyModeLabel,
    required this.privacyFriendsLabel,
    required this.privacySharedLabel,
    required this.secretLinkLabel,
    required this.copySecretLinkButton,
    required this.rotateSecretLinkButton,
    required this.viewWishlistsAction,
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
    required this.reportWishlistAction,
    required this.reportWishlistSuccess,
    required this.reportWishlistDuplicate,
    required this.reportWishlistUnavailable,
    required this.reportReasonLabel,
    required this.reportSubmitButton,
    required this.rateLimitedError,
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
    required this.myReservationsTitle,
    required this.noReservationsYet,
    required this.reserveButton,
    required this.extendReservationButton,
    required this.cancelReservationButton,
    required this.markPurchasedButton,
    required this.markDeliveredButton,
    required this.markReceivedButton,
    required this.confirmReceivedButton,
    required this.thankYouOptionalLabel,
    required this.receivedGiftsTitle,
    required this.confirmVoidGiftsMessage,
    required this.estimatedDateLabel,
    required this.availabilityAvailable,
    required this.availabilityReservedByMe,
    required this.availabilityUnavailable,
    required this.openMyReservationsAction,
    required this.navInbox,
    required this.inboxTitle,
    required this.noNotificationsYet,
    required this.notificationPrefsTitle,
    required this.pushChannelLabel,
    required this.emailChannelLabel,
    required this.inAppChannelLabel,
    required this.termsLinkLabel,
    required this.privacyLinkLabel,
    required this.openLegalLinkAction,
    required this.addPhotosGalleryButton,
    required this.addPhotoCameraButton,
    required this.selectedPhotosLabel,
  });

  // [REQ-USER-002] Resolves localized strings for 'es' (default) or 'en'.
  factory AppStrings.forLocale(String rawLocale) {
    final normalized = rawLocale.trim().toLowerCase();
    return normalized == 'en' ? _en : _es;
  }

  // [REQ-DISC-001] Localized label for a ReportReasonVo (wire codes stay English).
  String reportReasonLabelFor(ReportReasonVo reason) {
    switch (reason.value) {
      case 'spam':
        return locale == 'en' ? 'Spam' : 'Spam';
      case 'harassment':
        return locale == 'en' ? 'Harassment' : 'Acoso';
      case 'impersonation':
        return locale == 'en' ? 'Impersonation' : 'Suplantación';
      case 'inappropriate_content':
        return locale == 'en' ? 'Inappropriate content' : 'Contenido inapropiado';
      case 'scam':
        return locale == 'en' ? 'Scam' : 'Estafa';
      default:
        return reason.value;
    }
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
        case 429:
          return rateLimitedError;
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
    navWishlists: 'Listas',
    navShared: 'Compartidas',
    myWishlistsTitle: 'Mis listas de deseos',
    sharedWithMeTitle: 'Compartidas conmigo',
    friendWishlistsTitle: 'Listas del amigo',
    wishlistDetailTitle: 'Lista de deseos',
    wishlistTitleLabel: 'Título de la lista',
    createWishlistButton: 'Crear lista',
    noWishlistsYet: 'Aún no tienes listas',
    noSharedWishlists: 'Nadie ha compartido listas contigo todavía',
    noFriendWishlists: 'No hay listas visibles',
    wishlistEmptyShellHint: 'Agrega regalos a esta lista.',
    addItemButton: 'Agregar ítem',
    editItemTitle: 'Editar ítem',
    itemTitleLabel: 'Título',
    itemSpecsLabel: 'Especificaciones (color, talla, variante)',
    itemPriorityLabel: 'Prioridad',
    itemLinksLabel: 'Enlaces de compra (uno por línea)',
    itemPriceLabel: 'Precio (centavos, opcional)',
    itemCurrencyLabel: 'Moneda (USD, CRC…)',
    pasteStoreUrlLabel: 'Pegar enlace de tienda',
    previewLinkButton: 'Vista previa',
    confirmPreviewButton: 'Usar vista previa',
    noItemsYet: 'Aún no hay ítems',
    saveItemButton: 'Guardar ítem',
    privacyModeLabel: 'Privacidad',
    privacyFriendsLabel: 'Amigos',
    privacySharedLabel: 'Compartida',
    secretLinkLabel: 'Enlace secreto',
    copySecretLinkButton: 'Copiar enlace',
    rotateSecretLinkButton: 'Rotar enlace',
    viewWishlistsAction: 'Ver listas',
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
    reportWishlistAction: 'Reportar lista',
    reportWishlistSuccess: 'Reporte enviado. Gracias.',
    reportWishlistDuplicate: 'Ya reportaste esta lista.',
    reportWishlistUnavailable: 'Esta lista no está disponible.',
    reportReasonLabel: 'Motivo',
    reportSubmitButton: 'Enviar reporte',
    rateLimitedError: 'Demasiadas solicitudes. Espera unos minutos.',
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
    myReservationsTitle: 'Mis reservaciones',
    noReservationsYet: 'Aún no tienes reservaciones',
    reserveButton: 'Reservar',
    extendReservationButton: 'Extender',
    cancelReservationButton: 'Cancelar reservación',
    markPurchasedButton: 'Marcar como comprado',
    markDeliveredButton: 'Marcar como entregado',
    markReceivedButton: 'Ya recibí esto',
    confirmReceivedButton: 'Confirmar recepción',
    thankYouOptionalLabel: 'Nota de agradecimiento opcional',
    receivedGiftsTitle: 'Regalos recibidos',
    confirmVoidGiftsMessage: 'Tienes un regalo abierto. Confirma para anularlo al bloquear/deshacer amistad.',
    estimatedDateLabel: 'Fecha estimada',
    availabilityAvailable: 'Disponible',
    availabilityReservedByMe: 'Reservado por mí',
    availabilityUnavailable: 'No disponible',
    openMyReservationsAction: 'Mis reservaciones',
    navInbox: 'Avisos',
    inboxTitle: 'Avisos',
    noNotificationsYet: 'Aún no tienes avisos',
    notificationPrefsTitle: 'Preferencias de avisos',
    pushChannelLabel: 'Teléfono',
    emailChannelLabel: 'Correo',
    inAppChannelLabel: 'Campanita',
    termsLinkLabel: 'Términos de uso',
    privacyLinkLabel: 'Privacidad',
    openLegalLinkAction: 'Abrir',
    addPhotosGalleryButton: 'Galería',
    addPhotoCameraButton: 'Cámara',
    selectedPhotosLabel: 'Fotos listas',
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
    navWishlists: 'Lists',
    navShared: 'Shared',
    myWishlistsTitle: 'My wishlists',
    sharedWithMeTitle: 'Shared with me',
    friendWishlistsTitle: "Friend's wishlists",
    wishlistDetailTitle: 'Wishlist',
    wishlistTitleLabel: 'Wishlist title',
    createWishlistButton: 'Create list',
    noWishlistsYet: 'You have no wishlists yet',
    noSharedWishlists: 'Nothing shared with you yet',
    noFriendWishlists: 'No visible wishlists',
    wishlistEmptyShellHint: 'Add gifts to this list.',
    addItemButton: 'Add item',
    editItemTitle: 'Edit item',
    itemTitleLabel: 'Title',
    itemSpecsLabel: 'Specifications (color, size, variant)',
    itemPriorityLabel: 'Priority',
    itemLinksLabel: 'Purchase links (one per line)',
    itemPriceLabel: 'Price (cents, optional)',
    itemCurrencyLabel: 'Currency (USD, CRC…)',
    pasteStoreUrlLabel: 'Paste store link',
    previewLinkButton: 'Preview',
    confirmPreviewButton: 'Use preview',
    noItemsYet: 'No items yet',
    saveItemButton: 'Save item',
    privacyModeLabel: 'Privacy',
    privacyFriendsLabel: 'Friends',
    privacySharedLabel: 'Shared',
    secretLinkLabel: 'Secret link',
    copySecretLinkButton: 'Copy link',
    rotateSecretLinkButton: 'Rotate link',
    viewWishlistsAction: 'View wishlists',
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
    reportWishlistAction: 'Report list',
    reportWishlistSuccess: 'Report submitted. Thank you.',
    reportWishlistDuplicate: 'You already reported this list.',
    reportWishlistUnavailable: 'This list is unavailable.',
    reportReasonLabel: 'Reason',
    reportSubmitButton: 'Submit report',
    rateLimitedError: 'Too many requests. Please wait a few minutes.',
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
    myReservationsTitle: 'My reservations',
    noReservationsYet: 'You have no reservations yet',
    reserveButton: 'Reserve',
    extendReservationButton: 'Extend',
    cancelReservationButton: 'Cancel reservation',
    markPurchasedButton: 'Mark purchased',
    markDeliveredButton: 'Mark delivered',
    markReceivedButton: 'I already received this',
    confirmReceivedButton: 'Confirm receipt',
    thankYouOptionalLabel: 'Optional thank-you note',
    receivedGiftsTitle: 'Received Gifts',
    confirmVoidGiftsMessage: 'You have an open gift. Confirm to void it when blocking/unfriending.',
    estimatedDateLabel: 'Estimated date',
    availabilityAvailable: 'Available',
    availabilityReservedByMe: 'Reserved by me',
    availabilityUnavailable: 'Unavailable',
    openMyReservationsAction: 'My reservations',
    navInbox: 'Inbox',
    inboxTitle: 'Notifications',
    noNotificationsYet: 'No notifications yet',
    notificationPrefsTitle: 'Notification preferences',
    pushChannelLabel: 'Push',
    emailChannelLabel: 'Email',
    inAppChannelLabel: 'In-app',
    termsLinkLabel: 'Terms of Use',
    privacyLinkLabel: 'Privacy Policy',
    openLegalLinkAction: 'Open',
    addPhotosGalleryButton: 'Gallery',
    addPhotoCameraButton: 'Camera',
    selectedPhotosLabel: 'Photos ready',
  );
}
