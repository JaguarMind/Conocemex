import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
  ];

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'CONOCEMEX'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navCatalog.
  ///
  /// In es, this message translates to:
  /// **'Catalogo'**
  String get navCatalog;

  /// No description provided for @navOrders.
  ///
  /// In es, this message translates to:
  /// **'Pedidos'**
  String get navOrders;

  /// No description provided for @navProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @welcomeTo.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a\nMexico'**
  String get welcomeTo;

  /// No description provided for @continueWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get continueWithGoogle;

  /// No description provided for @signUpWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Registrarse con Google'**
  String get signUpWithGoogle;

  /// No description provided for @or.
  ///
  /// In es, this message translates to:
  /// **'O'**
  String get or;

  /// No description provided for @emailLabel.
  ///
  /// In es, this message translates to:
  /// **'CORREO'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In es, this message translates to:
  /// **'ejemplo@conocemex.com'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In es, this message translates to:
  /// **'CONTRASENA'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In es, this message translates to:
  /// **'••••••••'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In es, this message translates to:
  /// **'OLVIDO?'**
  String get forgotPassword;

  /// No description provided for @logIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesion'**
  String get logIn;

  /// No description provided for @signUp.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get signUp;

  /// No description provided for @dontHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'No tienes cuenta? '**
  String get dontHaveAccount;

  /// No description provided for @signUpLink.
  ///
  /// In es, this message translates to:
  /// **'Registrate'**
  String get signUpLink;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes cuenta? '**
  String get alreadyHaveAccount;

  /// No description provided for @logInLink.
  ///
  /// In es, this message translates to:
  /// **'Inicia Sesion'**
  String get logInLink;

  /// No description provided for @skipGuest.
  ///
  /// In es, this message translates to:
  /// **'SALTAR Y CONTINUAR COMO INVITADO'**
  String get skipGuest;

  /// No description provided for @skip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get skip;

  /// No description provided for @createAccount.
  ///
  /// In es, this message translates to:
  /// **'Crea tu\ncuenta'**
  String get createAccount;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Registrate como vendedor para dar a conocer tu negocio.'**
  String get createAccountSubtitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In es, this message translates to:
  /// **'NOMBRE COMPLETO'**
  String get fullNameLabel;

  /// No description provided for @fullNameHint.
  ///
  /// In es, this message translates to:
  /// **'Juan Perez'**
  String get fullNameHint;

  /// No description provided for @phoneLabel.
  ///
  /// In es, this message translates to:
  /// **'TELEFONO'**
  String get phoneLabel;

  /// No description provided for @phoneHint.
  ///
  /// In es, this message translates to:
  /// **'+52 55 1234 5678'**
  String get phoneHint;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'CONFIRMAR CONTRASENA'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Repite tu contrasena'**
  String get confirmPasswordHint;

  /// No description provided for @completeProfile.
  ///
  /// In es, this message translates to:
  /// **'Completa tu\nperfil'**
  String get completeProfile;

  /// No description provided for @completeProfileSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos algunos datos para personalizar tu experiencia como vendedor.'**
  String get completeProfileSubtitle;

  /// No description provided for @nationalityLabel.
  ///
  /// In es, this message translates to:
  /// **'NACIONALIDAD'**
  String get nationalityLabel;

  /// No description provided for @nationalityHint.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu pais'**
  String get nationalityHint;

  /// No description provided for @languageLabel.
  ///
  /// In es, this message translates to:
  /// **'IDIOMA DE PREFERENCIA'**
  String get languageLabel;

  /// No description provided for @languageHint.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu idioma'**
  String get languageHint;

  /// No description provided for @continueBtn.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueBtn;

  /// No description provided for @completeLater.
  ///
  /// In es, this message translates to:
  /// **'Completar despues'**
  String get completeLater;

  /// No description provided for @loadingLanguages.
  ///
  /// In es, this message translates to:
  /// **'Cargando idiomas...'**
  String get loadingLanguages;

  /// No description provided for @myPanel.
  ///
  /// In es, this message translates to:
  /// **'Mi Panel'**
  String get myPanel;

  /// No description provided for @welcomeConocemex.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a Conocemex'**
  String get welcomeConocemex;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Registra tu negocio para que turistas\nde todo el mundo puedan descubrirte.'**
  String get welcomeSubtitle;

  /// No description provided for @addFirstBusiness.
  ///
  /// In es, this message translates to:
  /// **'Agregar mi primer negocio'**
  String get addFirstBusiness;

  /// No description provided for @addBusiness.
  ///
  /// In es, this message translates to:
  /// **'Agregar negocio'**
  String get addBusiness;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @active.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In es, this message translates to:
  /// **'Inactivo'**
  String get inactive;

  /// No description provided for @noCategory.
  ///
  /// In es, this message translates to:
  /// **'Sin categoria'**
  String get noCategory;

  /// No description provided for @businessRegistration.
  ///
  /// In es, this message translates to:
  /// **'Registro de Negocio'**
  String get businessRegistration;

  /// No description provided for @businessNameLabel.
  ///
  /// In es, this message translates to:
  /// **'NOMBRE DEL NEGOCIO'**
  String get businessNameLabel;

  /// No description provided for @businessNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Tacos Don Pepe'**
  String get businessNameHint;

  /// No description provided for @categoryLabel.
  ///
  /// In es, this message translates to:
  /// **'CATEGORIA'**
  String get categoryLabel;

  /// No description provided for @categoryHint.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una categoria'**
  String get categoryHint;

  /// No description provided for @locationLabel.
  ///
  /// In es, this message translates to:
  /// **'UBICACION'**
  String get locationLabel;

  /// No description provided for @locationHint.
  ///
  /// In es, this message translates to:
  /// **'Calle, Colonia, Ciudad'**
  String get locationHint;

  /// No description provided for @coordinatesLabel.
  ///
  /// In es, this message translates to:
  /// **'COORDENADAS'**
  String get coordinatesLabel;

  /// No description provided for @latitudeHint.
  ///
  /// In es, this message translates to:
  /// **'Latitud'**
  String get latitudeHint;

  /// No description provided for @longitudeHint.
  ///
  /// In es, this message translates to:
  /// **'Longitud'**
  String get longitudeHint;

  /// No description provided for @confirmPublish.
  ///
  /// In es, this message translates to:
  /// **'Confirmar y Publicar'**
  String get confirmPublish;

  /// No description provided for @termsAccept.
  ///
  /// In es, this message translates to:
  /// **'Al publicar aceptas los terminos de uso.'**
  String get termsAccept;

  /// No description provided for @uploadPhoto.
  ///
  /// In es, this message translates to:
  /// **'Sube una foto de tu\nlocal o negocio'**
  String get uploadPhoto;

  /// No description provided for @photoFormats.
  ///
  /// In es, this message translates to:
  /// **'Formatos: JPG, PNG'**
  String get photoFormats;

  /// No description provided for @changePhoto.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get changePhoto;

  /// No description provided for @uploadingImage.
  ///
  /// In es, this message translates to:
  /// **'Subiendo imagen...'**
  String get uploadingImage;

  /// No description provided for @imageUploaded.
  ///
  /// In es, this message translates to:
  /// **'Imagen subida correctamente'**
  String get imageUploaded;

  /// No description provided for @imageUploadError.
  ///
  /// In es, this message translates to:
  /// **'Error al subir imagen'**
  String get imageUploadError;

  /// No description provided for @uploaded.
  ///
  /// In es, this message translates to:
  /// **'Subida'**
  String get uploaded;

  /// No description provided for @autoCompleteAi.
  ///
  /// In es, this message translates to:
  /// **'Autocompletar con IA'**
  String get autoCompleteAi;

  /// No description provided for @analyzingAi.
  ///
  /// In es, this message translates to:
  /// **'Analizando imagen con IA...'**
  String get analyzingAi;

  /// No description provided for @fieldsCompleted.
  ///
  /// In es, this message translates to:
  /// **'Campos autocompletados con IA'**
  String get fieldsCompleted;

  /// No description provided for @takePhoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get takePhoto;

  /// No description provided for @chooseGallery.
  ///
  /// In es, this message translates to:
  /// **'Elegir de galeria'**
  String get chooseGallery;

  /// No description provided for @businessPhoto.
  ///
  /// In es, this message translates to:
  /// **'Foto del negocio'**
  String get businessPhoto;

  /// No description provided for @newOffering.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Producto/Servicio'**
  String get newOffering;

  /// No description provided for @typeLabel.
  ///
  /// In es, this message translates to:
  /// **'TIPO'**
  String get typeLabel;

  /// No description provided for @product.
  ///
  /// In es, this message translates to:
  /// **'Producto'**
  String get product;

  /// No description provided for @service.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get service;

  /// No description provided for @nameLabel.
  ///
  /// In es, this message translates to:
  /// **'NOMBRE'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Tacos al pastor'**
  String get nameHint;

  /// No description provided for @descriptionLabel.
  ///
  /// In es, this message translates to:
  /// **'DESCRIPCION'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In es, this message translates to:
  /// **'Describe tu producto o servicio'**
  String get descriptionHint;

  /// No description provided for @priceLabel.
  ///
  /// In es, this message translates to:
  /// **'PRECIO (MXN)'**
  String get priceLabel;

  /// No description provided for @priceHint.
  ///
  /// In es, this message translates to:
  /// **'0.00'**
  String get priceHint;

  /// No description provided for @priceTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'TIPO PRECIO'**
  String get priceTypeLabel;

  /// No description provided for @priceFixed.
  ///
  /// In es, this message translates to:
  /// **'Precio fijo'**
  String get priceFixed;

  /// No description provided for @priceFrom.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get priceFrom;

  /// No description provided for @priceHourly.
  ///
  /// In es, this message translates to:
  /// **'Por hora'**
  String get priceHourly;

  /// No description provided for @pricePerPerson.
  ///
  /// In es, this message translates to:
  /// **'Por persona'**
  String get pricePerPerson;

  /// No description provided for @priceQuote.
  ///
  /// In es, this message translates to:
  /// **'Cotizar'**
  String get priceQuote;

  /// No description provided for @durationLabel.
  ///
  /// In es, this message translates to:
  /// **'DURACION (MINUTOS)'**
  String get durationLabel;

  /// No description provided for @durationHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: 60'**
  String get durationHint;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @uploadProductPhoto.
  ///
  /// In es, this message translates to:
  /// **'Sube una foto del producto'**
  String get uploadProductPhoto;

  /// No description provided for @uploadingAnalyzing.
  ///
  /// In es, this message translates to:
  /// **'Subiendo y analizando...'**
  String get uploadingAnalyzing;

  /// No description provided for @catalog.
  ///
  /// In es, this message translates to:
  /// **'Catalogo'**
  String get catalog;

  /// No description provided for @selectBusiness.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un negocio'**
  String get selectBusiness;

  /// No description provided for @selectBusinessSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige uno de tus negocios para ver\ny gestionar sus productos y servicios.'**
  String get selectBusinessSubtitle;

  /// No description provided for @noProducts.
  ///
  /// In es, this message translates to:
  /// **'Sin productos aun'**
  String get noProducts;

  /// No description provided for @noProductsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Agrega productos o servicios\na {businessName}.'**
  String noProductsSubtitle(String businessName);

  /// No description provided for @addProduct.
  ///
  /// In es, this message translates to:
  /// **'Agregar producto'**
  String get addProduct;

  /// No description provided for @productsAndServices.
  ///
  /// In es, this message translates to:
  /// **'Productos y Servicios'**
  String get productsAndServices;

  /// No description provided for @addBtn.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get addBtn;

  /// No description provided for @addFirst.
  ///
  /// In es, this message translates to:
  /// **'Agregar primero'**
  String get addFirst;

  /// No description provided for @noProductsYet.
  ///
  /// In es, this message translates to:
  /// **'Aun no tienes productos ni servicios'**
  String get noProductsYet;

  /// No description provided for @orders.
  ///
  /// In es, this message translates to:
  /// **'Pedidos'**
  String get orders;

  /// No description provided for @comingSoon.
  ///
  /// In es, this message translates to:
  /// **'Proximamente'**
  String get comingSoon;

  /// No description provided for @ordersSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Aqui veras el historial\nde pedidos de tus clientes.'**
  String get ordersSubtitle;

  /// No description provided for @catalogSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Aqui podras ver y gestionar\ntodos tus productos y servicios.'**
  String get catalogSubtitle;

  /// No description provided for @profile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profile;

  /// No description provided for @nameProp.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get nameProp;

  /// No description provided for @emailProp.
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get emailProp;

  /// No description provided for @phoneProp.
  ///
  /// In es, this message translates to:
  /// **'Telefono'**
  String get phoneProp;

  /// No description provided for @nationalityProp.
  ///
  /// In es, this message translates to:
  /// **'Nacionalidad'**
  String get nationalityProp;

  /// No description provided for @memberSince.
  ///
  /// In es, this message translates to:
  /// **'Miembro desde'**
  String get memberSince;

  /// No description provided for @notRegistered.
  ///
  /// In es, this message translates to:
  /// **'No registrado'**
  String get notRegistered;

  /// No description provided for @notRegisteredF.
  ///
  /// In es, this message translates to:
  /// **'No registrada'**
  String get notRegisteredF;

  /// No description provided for @vendor.
  ///
  /// In es, this message translates to:
  /// **'Vendedor'**
  String get vendor;

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar Sesion'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In es, this message translates to:
  /// **'Estas seguro de que deseas cerrar sesion?'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @visits.
  ///
  /// In es, this message translates to:
  /// **'{count} visitas'**
  String visits(int count);

  /// No description provided for @required.
  ///
  /// In es, this message translates to:
  /// **'Requerido'**
  String get required;

  /// No description provided for @invalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo valido'**
  String get invalidEmail;

  /// No description provided for @emailRequired.
  ///
  /// In es, this message translates to:
  /// **'El correo es requerido'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In es, this message translates to:
  /// **'La contrasena es requerida'**
  String get passwordRequired;

  /// No description provided for @minChars.
  ///
  /// In es, this message translates to:
  /// **'Minimo 6 caracteres'**
  String get minChars;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contrasenas no coinciden'**
  String get passwordsDontMatch;

  /// No description provided for @nameRequired.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre es requerido'**
  String get nameRequired;

  /// No description provided for @selectCategory.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una categoria'**
  String get selectCategory;

  /// No description provided for @selectNationality.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu nacionalidad'**
  String get selectNationality;

  /// No description provided for @selectLanguage.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un idioma'**
  String get selectLanguage;

  /// No description provided for @invalidLat.
  ///
  /// In es, this message translates to:
  /// **'Latitud invalida'**
  String get invalidLat;

  /// No description provided for @invalidLng.
  ///
  /// In es, this message translates to:
  /// **'Longitud invalida'**
  String get invalidLng;

  /// No description provided for @invalidPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio invalido'**
  String get invalidPrice;

  /// No description provided for @errorUnexpected.
  ///
  /// In es, this message translates to:
  /// **'Ocurrio un error inesperado. Intenta nuevamente.'**
  String get errorUnexpected;

  /// No description provided for @errorNetwork.
  ///
  /// In es, this message translates to:
  /// **'No se pudo conectar al servidor. Verifica tu internet.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In es, this message translates to:
  /// **'La solicitud tardo demasiado. Intenta nuevamente.'**
  String get errorTimeout;

  /// No description provided for @errorCredentials.
  ///
  /// In es, this message translates to:
  /// **'Correo o contrasena incorrectos.'**
  String get errorCredentials;

  /// No description provided for @errorGoogleCancel.
  ///
  /// In es, this message translates to:
  /// **'Inicio de sesion con Google cancelado.'**
  String get errorGoogleCancel;

  /// No description provided for @errorBiometric.
  ///
  /// In es, this message translates to:
  /// **'No fue posible validar tu biometria.'**
  String get errorBiometric;

  /// No description provided for @errorRateLimit.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Espera unos minutos.'**
  String get errorRateLimit;

  /// No description provided for @errorAlreadyRegistered.
  ///
  /// In es, this message translates to:
  /// **'Este correo ya esta registrado. Intenta iniciar sesion.'**
  String get errorAlreadyRegistered;

  /// No description provided for @errorLoginGoogle.
  ///
  /// In es, this message translates to:
  /// **'Error al iniciar sesion con Google'**
  String get errorLoginGoogle;

  /// No description provided for @errorLogin.
  ///
  /// In es, this message translates to:
  /// **'Error al iniciar sesion'**
  String get errorLogin;

  /// No description provided for @errorSignUp.
  ///
  /// In es, this message translates to:
  /// **'Error al registrarse'**
  String get errorSignUp;

  /// No description provided for @errorLoadPanel.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar el panel'**
  String get errorLoadPanel;

  /// No description provided for @errorUpdateBusiness.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar negocios'**
  String get errorUpdateBusiness;

  /// No description provided for @errorLoadCategories.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar categorias'**
  String get errorLoadCategories;

  /// No description provided for @errorCreateBusiness.
  ///
  /// In es, this message translates to:
  /// **'Error al crear negocio'**
  String get errorCreateBusiness;

  /// No description provided for @errorLoadOfferings.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar productos/servicios'**
  String get errorLoadOfferings;

  /// No description provided for @errorCreateOffering.
  ///
  /// In es, this message translates to:
  /// **'Error al crear producto/servicio'**
  String get errorCreateOffering;

  /// No description provided for @editProfile.
  ///
  /// In es, this message translates to:
  /// **'Editar Perfil'**
  String get editProfile;

  /// No description provided for @saveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar Cambios'**
  String get saveChanges;

  /// No description provided for @profileUpdated.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado correctamente'**
  String get profileUpdated;

  /// No description provided for @errorUpdateProfile.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar perfil'**
  String get errorUpdateProfile;

  /// No description provided for @appLanguage.
  ///
  /// In es, this message translates to:
  /// **'IDIOMA DE LA APP'**
  String get appLanguage;

  /// No description provided for @languageChanged.
  ///
  /// In es, this message translates to:
  /// **'Idioma actualizado'**
  String get languageChanged;

  /// No description provided for @connectMercadoPago.
  ///
  /// In es, this message translates to:
  /// **'Conectar Mercado Pago'**
  String get connectMercadoPago;

  /// No description provided for @mpConnecting.
  ///
  /// In es, this message translates to:
  /// **'Conectando...'**
  String get mpConnecting;

  /// No description provided for @mpConnected.
  ///
  /// In es, this message translates to:
  /// **'Mercado Pago conectado'**
  String get mpConnected;

  /// No description provided for @mpNotConnected.
  ///
  /// In es, this message translates to:
  /// **'No conectado'**
  String get mpNotConnected;

  /// No description provided for @mpOpenedBrowser.
  ///
  /// In es, this message translates to:
  /// **'Te abrimos Mercado Pago en el navegador. Cuando termines de autorizar, vuelve a la app.'**
  String get mpOpenedBrowser;

  /// No description provided for @mpPayments.
  ///
  /// In es, this message translates to:
  /// **'Pagos'**
  String get mpPayments;

  /// No description provided for @mpConnectSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Conecta tu cuenta para recibir pagos de turistas via QR.'**
  String get mpConnectSubtitle;

  /// No description provided for @chat.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @typeMessage.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje...'**
  String get typeMessage;

  /// No description provided for @noMessages.
  ///
  /// In es, this message translates to:
  /// **'Sin mensajes todavia'**
  String get noMessages;

  /// No description provided for @translating.
  ///
  /// In es, this message translates to:
  /// **'Traduciendo...'**
  String get translating;

  /// No description provided for @myCommunities.
  ///
  /// In es, this message translates to:
  /// **'Mis Comunidades'**
  String get myCommunities;

  /// No description provided for @discover.
  ///
  /// In es, this message translates to:
  /// **'Descubrir'**
  String get discover;

  /// No description provided for @createCommunity.
  ///
  /// In es, this message translates to:
  /// **'Crear Comunidad'**
  String get createCommunity;

  /// No description provided for @joinCommunity.
  ///
  /// In es, this message translates to:
  /// **'Unirse'**
  String get joinCommunity;

  /// No description provided for @leaveCommunity.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get leaveCommunity;

  /// No description provided for @communityName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la comunidad'**
  String get communityName;

  /// No description provided for @communityDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripcion (opcional)'**
  String get communityDescription;

  /// No description provided for @members.
  ///
  /// In es, this message translates to:
  /// **'miembros'**
  String get members;

  /// No description provided for @noCommunities.
  ///
  /// In es, this message translates to:
  /// **'Sin comunidades'**
  String get noCommunities;

  /// No description provided for @discoverSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Unete a comunidades o crea la tuya propia.'**
  String get discoverSubtitle;

  /// No description provided for @joinedCommunity.
  ///
  /// In es, this message translates to:
  /// **'Te uniste a la comunidad'**
  String get joinedCommunity;

  /// No description provided for @directChats.
  ///
  /// In es, this message translates to:
  /// **'CHATS DIRECTOS'**
  String get directChats;

  /// No description provided for @directChatsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Las solicitudes de chat de clientes apareceran aqui.'**
  String get directChatsSubtitle;

  /// No description provided for @requestsComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes de chat proximamente'**
  String get requestsComingSoon;

  /// No description provided for @joinWithCode.
  ///
  /// In es, this message translates to:
  /// **'Unirse con codigo'**
  String get joinWithCode;

  /// No description provided for @enterInviteCode.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el codigo de invitacion de la comunidad.'**
  String get enterInviteCode;

  /// No description provided for @inviteCode.
  ///
  /// In es, this message translates to:
  /// **'Codigo de invitacion'**
  String get inviteCode;

  /// No description provided for @communityCreated.
  ///
  /// In es, this message translates to:
  /// **'Comunidad creada'**
  String get communityCreated;

  /// No description provided for @shareInviteCode.
  ///
  /// In es, this message translates to:
  /// **'Comparte este codigo para que otros se unan:'**
  String get shareInviteCode;

  /// No description provided for @codeCopied.
  ///
  /// In es, this message translates to:
  /// **'Codigo copiado'**
  String get codeCopied;

  /// No description provided for @share.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get share;

  /// No description provided for @charge.
  ///
  /// In es, this message translates to:
  /// **'Cobrar'**
  String get charge;

  /// No description provided for @chargeAmount.
  ///
  /// In es, this message translates to:
  /// **'MONTO A COBRAR'**
  String get chargeAmount;

  /// No description provided for @chargeDescription.
  ///
  /// In es, this message translates to:
  /// **'DESCRIPCION (OPCIONAL)'**
  String get chargeDescription;

  /// No description provided for @chargeDescHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: 2 tacos al pastor'**
  String get chargeDescHint;

  /// No description provided for @chargeMinAmount.
  ///
  /// In es, this message translates to:
  /// **'Minimo \$5 MXN'**
  String get chargeMinAmount;

  /// No description provided for @generateQr.
  ///
  /// In es, this message translates to:
  /// **'Generar QR de cobro'**
  String get generateQr;

  /// No description provided for @generating.
  ///
  /// In es, this message translates to:
  /// **'Generando...'**
  String get generating;

  /// No description provided for @chargeQr.
  ///
  /// In es, this message translates to:
  /// **'QR de cobro'**
  String get chargeQr;

  /// No description provided for @waitingPayment.
  ///
  /// In es, this message translates to:
  /// **'Esperando pago...'**
  String get waitingPayment;

  /// No description provided for @scanQrInstruction.
  ///
  /// In es, this message translates to:
  /// **'Pide al turista que escanee el QR con la camara de su celular.'**
  String get scanQrInstruction;

  /// No description provided for @paymentReceived.
  ///
  /// In es, this message translates to:
  /// **'Pago recibido!'**
  String get paymentReceived;

  /// No description provided for @paymentFailed.
  ///
  /// In es, this message translates to:
  /// **'El pago no se completo'**
  String get paymentFailed;

  /// No description provided for @done.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get done;

  /// No description provided for @messages.
  ///
  /// In es, this message translates to:
  /// **'Mensajes'**
  String get messages;

  /// No description provided for @noConversations.
  ///
  /// In es, this message translates to:
  /// **'Sin conversaciones aun'**
  String get noConversations;

  /// No description provided for @client.
  ///
  /// In es, this message translates to:
  /// **'Cliente'**
  String get client;

  /// No description provided for @selectLocationMap.
  ///
  /// In es, this message translates to:
  /// **'Selecciona la ubicacion en el mapa'**
  String get selectLocationMap;

  /// No description provided for @tapToSelectLocation.
  ///
  /// In es, this message translates to:
  /// **'Toca el mapa para seleccionar ubicacion'**
  String get tapToSelectLocation;

  /// No description provided for @confirmLocation.
  ///
  /// In es, this message translates to:
  /// **'Confirmar ubicacion'**
  String get confirmLocation;

  /// No description provided for @loadingAddress.
  ///
  /// In es, this message translates to:
  /// **'Cargando direccion...'**
  String get loadingAddress;

  /// No description provided for @registerSale.
  ///
  /// In es, this message translates to:
  /// **'Registrar Venta'**
  String get registerSale;

  /// No description provided for @items.
  ///
  /// In es, this message translates to:
  /// **'articulos'**
  String get items;

  /// No description provided for @sales.
  ///
  /// In es, this message translates to:
  /// **'Ventas'**
  String get sales;

  /// No description provided for @selectBusinessSales.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un negocio para ver sus ventas'**
  String get selectBusinessSales;

  /// No description provided for @noSales.
  ///
  /// In es, this message translates to:
  /// **'Sin ventas registradas'**
  String get noSales;

  /// No description provided for @saleCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get saleCompleted;

  /// No description provided for @salePending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get salePending;

  /// No description provided for @saleFailed.
  ///
  /// In es, this message translates to:
  /// **'Fallida'**
  String get saleFailed;

  /// No description provided for @saleRefunded.
  ///
  /// In es, this message translates to:
  /// **'Reembolsada'**
  String get saleRefunded;

  /// No description provided for @disconnectMp.
  ///
  /// In es, this message translates to:
  /// **'Desvincular'**
  String get disconnectMp;

  /// No description provided for @disconnectMpConfirm.
  ///
  /// In es, this message translates to:
  /// **'Seguro que quieres desvincular tu cuenta de Mercado Pago de este negocio?'**
  String get disconnectMpConfirm;

  /// No description provided for @mpDisconnected.
  ///
  /// In es, this message translates to:
  /// **'Mercado Pago desvinculado'**
  String get mpDisconnected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
