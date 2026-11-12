import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/storage/auth_session_store.dart';
import '../data/auth_repository.dart';
import '../data/mail_app_launcher.dart';
import '../data/verification_deep_link_service.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_user.dart';
import '../domain/person_name.dart';
import '../domain/signup_rules.dart';

/// Étapes du flux. On a  avec le prénom et le
/// nom
enum AuthStep {
  emailEntry,
  confirmEmail,

  /// Compte déjà inscrit et vérifié.
  loginPassword,

  /// Inscription, première étape. Aussi utilisée après une connexion Google ou
  /// Facebook quand y a pas  le prénom et le nom
  identity,

  /// Inscription, seconde étape.
  createPassword,

  /// En attente du clic sur le lien reçu par e-mail.
  checkYourEmail,

  welcome,
}

class AuthFlowState {
  const AuthFlowState({
    required this.step,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isLoading,
    this.socialIdentity = false,
    this.errorMessage,
    this.infoMessage,
  });

  factory AuthFlowState.initial() => const AuthFlowState(
        step: AuthStep.emailEntry,
        email: '',
        firstName: '',
        lastName: '',
        isLoading: false,
      );

  final AuthStep step;
  final String email;
  final String firstName;
  final String lastName;
  final bool isLoading;

  /// True quand l'étape d'identité suit une connexion Google ou Facebook : le
  /// compte existe déjà, il ne faut ni mot de passe ni e-mail de confirmation.
  final bool socialIdentity;

  final String? errorMessage;

  /// Confirmation neutre, distincte de [errorMessage] pour ne pas afficher une
  /// erreur sur une action qui a réussi.
  final String? infoMessage;

  AuthFlowState copyWith({
    AuthStep? step,
    String? email,
    String? firstName,
    String? lastName,
    bool? isLoading,
    bool? socialIdentity,
    String? errorMessage,
    String? infoMessage,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return AuthFlowState(
      step: step ?? this.step,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isLoading: isLoading ?? this.isLoading,
      socialIdentity: socialIdentity ?? this.socialIdentity,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}

/// Durée pendant laquelle le mot de passe d'une nouvelle inscription  reste en
/// mémoire, le temps que l'utilisateur ouvre le lien reçu par e-mail. si ça
/// dépasse ce délais, on le purge
const Duration _pendingPasswordWindow = Duration(minutes: 10);

class AuthFlowController extends Notifier<AuthFlowState> {
  AuthRepository get _repository => getIt<AuthRepository>();
  VerificationDeepLinkService get _deepLinkService => getIt<VerificationDeepLinkService>();
  MailAppLauncher get _mailLauncher => getIt<MailAppLauncher>();
  AuthSessionStore get _session => getIt<AuthSessionStore>();

  /// pas  [AuthFlowState]  : un mot de passe ne doit pas transiter par
  /// un état observable depuis les outils de développement. Sa durée de vie est
  /// bornée, et il est effacé dès qu'il n'est plus utile.
  String? _pendingPassword;
  Timer? _pendingPasswordTimer;

  bool _isExistingUser = false;
  bool _isExistingVerified = false;

  int _failedLoginAttempts = 0;
  DateTime? _loginLockedUntil;

  static const int _maxLocalLoginAttempts = 5;
  static const Duration _localLockoutDuration = Duration(minutes: 2);

  @override
  AuthFlowState build() {
    // Après une déconnexion, le flux repart de zéro : sans cela, on retomberait sur
    // l'écran qu'on implémentera(peut-être date de naissance) après de la session précédente.
    void resetOnSignOut() {
      if (!_session.isAuthenticated.value) {
        _clearPendingPassword();
        state = AuthFlowState.initial();
      }
    }

    _session.isAuthenticated.addListener(resetOnSignOut);
    ref.onDispose(() {
      _session.isAuthenticated.removeListener(resetOnSignOut);
      _clearPendingPassword();
      _deepLinkService.stopListening();
    });

    // Une session ouverte sans prénom ni nom (application fermée en plein flux)
    // reprend directement à la saisie de l'identité.
    if (_session.isAuthenticated.value && _session.needsIdentity.value) {
      return AuthFlowState.initial().copyWith(
        step: AuthStep.identity,
        socialIdentity: true,
        email: _session.currentUser.value?.email ?? '',
      );
    }
    return AuthFlowState.initial();
  }

  Future<void> submitEmail(String email) async {
    final normalized = SignupRules.normalizeEmail(email);
    if (!SignupRules.isValidEmail(normalized)) {
      state = state.copyWith(errorMessage: 'Entrez une adresse e-mail valide.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      final result = await _repository.checkEmailExists(normalized);
      _isExistingUser = result.exists;
      _isExistingVerified = result.isVerified;
      state = state.copyWith(email: normalized, step: AuthStep.confirmEmail, isLoading: false);
    } on AuthException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.publicMessage);
    }
  }

  /// Cette séparation corrige le
  /// contournement de la vérification de l'e-mail :
  /// un nouveau compte passe à la saisie de l'identité, un compte vérifié passe au
  /// mot de passe, un compte existant mais non vérifié reprend la vérification.
  void confirmEmailAndProceed() {
    if (!_isExistingUser) {
      state = state.copyWith(step: AuthStep.identity, socialIdentity: false, clearError: true);
      return;
    }
    if (_isExistingVerified) {
      state = state.copyWith(step: AuthStep.loginPassword, clearError: true);
      return;
    }
    // Compte non vérifié : son mot de passe n'est pas connu dans cette session, donc
    // pas de connexion automatique. Une fois le lien ouvert, on demande le mot de passe.
    _deepLinkService.startListening(onVerified: _handleResumedVerification);
    state = state.copyWith(step: AuthStep.checkYourEmail, clearError: true);
  }

  void editEmail() {
    _deepLinkService.stopListening();
    state = state.copyWith(step: AuthStep.emailEntry, clearError: true, clearInfo: true);
  }

  /// Retour d'une étape, d'après le même ordre que l'avance.
  void back() {
    switch (state.step) {
      case AuthStep.confirmEmail:
        editEmail();
      case AuthStep.loginPassword:
        state = state.copyWith(step: AuthStep.confirmEmail, clearError: true);
      case AuthStep.identity:
        if (state.socialIdentity) return;
        state = state.copyWith(step: AuthStep.confirmEmail, clearError: true);
      case AuthStep.createPassword:
        state = state.copyWith(step: AuthStep.identity, clearError: true);
      case AuthStep.emailEntry:
      case AuthStep.checkYourEmail:
      case AuthStep.welcome:
        return;
    }
  }

  Future<void> submitIdentity({required String firstName, required String lastName}) async {
    final first = PersonName.normalize(firstName);
    final last = PersonName.normalize(lastName);
    if (PersonName.validate(first) != null || PersonName.validate(last) != null) {
      state = state.copyWith(errorMessage: 'Vérifiez votre prénom et votre nom.');
      return;
    }

    if (!state.socialIdentity) {
      state = state.copyWith(
        firstName: first,
        lastName: last,
        step: AuthStep.createPassword,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.saveIdentity(firstName: first, lastName: last);
      state = state.copyWith(
        firstName: first,
        lastName: last,
        isLoading: false,
        step: AuthStep.welcome,
      );
    } on AuthException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.publicMessage);
    }
  }

  Future<void> submitLoginPassword(String password) async {
    final lockedUntil = _loginLockedUntil;
    if (lockedUntil != null) {
      if (DateTime.now().isBefore(lockedUntil)) {
        final remaining = lockedUntil.difference(DateTime.now()).inSeconds;
        state = state.copyWith(errorMessage: 'Trop de tentatives. Réessayez dans $remaining s.');
        return;
      }
      _loginLockedUntil = null;
      _failedLoginAttempts = 0;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.login(email: state.email, password: password);
      _failedLoginAttempts = 0;
      state = state.copyWith(isLoading: false, firstName: user.firstName ?? '', step: AuthStep.welcome);
    } on AuthException catch (error) {
      _failedLoginAttempts++;
      if (_failedLoginAttempts >= _maxLocalLoginAttempts) {
        _loginLockedUntil = DateTime.now().add(_localLockoutDuration);
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Trop de tentatives. Réessayez dans ${_localLockoutDuration.inMinutes} minutes.',
        );
        return;
      }
      state = state.copyWith(isLoading: false, errorMessage: error.publicMessage);
    }
  }

  Future<void> submitSignupPassword(String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.register(
        email: state.email,
        firstName: state.firstName,
        lastName: state.lastName,
        password: password,
      );

      _pendingPassword = password;
      _pendingPasswordTimer?.cancel();
      _pendingPasswordTimer = Timer(_pendingPasswordWindow, _clearPendingPassword);

      _deepLinkService.startListening(onVerified: _handleFreshSignupVerification);
      state = state.copyWith(isLoading: false, step: AuthStep.checkYourEmail);
    } on AuthException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.publicMessage);
    }
  }

  /// Bouton « Je n'ai rien reçu ».
  Future<void> resendVerificationEmail() async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      await _repository.resendVerificationEmail(state.email);
      state = state.copyWith(
        isLoading: false,
        infoMessage: 'Un nouvel e-mail de confirmation a été envoyé.',
      );
    } on AuthException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.publicMessage);
    }
  }

  Future<bool> openMailApp() => _mailLauncher.openMailApp();

  Future<void> signInWithGoogle() => _signInWithProvider(_repository.signInWithGoogle);

  Future<void> signInWithFacebook() => _signInWithProvider(_repository.signInWithFacebook);

  /// Écran de bienvenue terminé : le routeur peut envoyer vers l'accueil.
  void finishWelcome() => _session.releaseFlow();

  /// Depuis l'étape d'identité d'une connexion Google ou Facebook : repartir avec
  /// un autre compte.
  Future<void> switchAccount() async {
    await _repository.logout();
    state = AuthFlowState.initial();
  }

  Future<void> _signInWithProvider(Future<AuthUser> Function() signIn) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      final user = await signIn();
      state = state.copyWith(
        isLoading: false,
        email: user.email,
        firstName: user.firstName ?? '',
        lastName: user.lastName ?? '',
        socialIdentity: user.needsIdentity,
        step: user.needsIdentity ? AuthStep.identity : AuthStep.welcome,
      );
    } on AuthException catch (error) {
      //on Fermer la fenêtre du fournisseur
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.isCancelled ? null : error.publicMessage,
        clearError: error.isCancelled,
      );
    }
  }

  /// Lien reçu pendant une nouvelle inscription  : le mot de passe est encore en
  /// mémoire, on peut donc connecter directement.
  Future<void> _handleFreshSignupVerification() async {
    final password = _pendingPassword;
    if (password == null) {
      state = state.copyWith(
        errorMessage: "Le délai de confirmation a expiré. Reprenez l'inscription.",
        step: AuthStep.emailEntry,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.login(email: state.email, password: password);
      _clearPendingPassword();
      _deepLinkService.stopListening();
      state = state.copyWith(isLoading: false, step: AuthStep.welcome);
    } on AuthException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.publicMessage);
    }
  }

  /// Lien reçu en reprise d'un compte existant non vérifié : on demande le mot de
  /// passe maintenant que l'adresse est confirmée.
  void _handleResumedVerification() {
    _isExistingVerified = true;
    _deepLinkService.stopListening();
    state = state.copyWith(
      step: AuthStep.loginPassword,
      clearError: true,
      infoMessage: 'Adresse confirmée. Entrez votre mot de passe.',
    );
  }

  void _clearPendingPassword() {
    _pendingPassword = null;
    _pendingPasswordTimer?.cancel();
    _pendingPasswordTimer = null;
  }
}

final authFlowControllerProvider =
    NotifierProvider<AuthFlowController, AuthFlowState>(AuthFlowController.new);
