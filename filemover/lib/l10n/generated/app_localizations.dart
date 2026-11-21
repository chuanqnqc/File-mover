import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('zh'),
  ];

  /// No description provided for @operationFailedReviewTheOriginal.
  ///
  /// In en, this message translates to:
  /// **'Operation failed. Review the original details below.'**
  String get operationFailedReviewTheOriginal;

  /// No description provided for @refreshHistory.
  ///
  /// In en, this message translates to:
  /// **'Refresh history'**
  String get refreshHistory;

  /// No description provided for @heading.
  ///
  /// In en, this message translates to:
  /// **'Move the data. Keep the path.'**
  String get heading;

  /// No description provided for @intro.
  ///
  /// In en, this message translates to:
  /// **'Safely relocate a Windows folder and leave a junction at its original location. Local NTFS drives only.'**
  String get intro;

  /// No description provided for @anOperationNeedsRecoveryOrCleanup.
  ///
  /// In en, this message translates to:
  /// **'An operation needs recovery or cleanup. Resolve it in History before starting another move.'**
  String get anOperationNeedsRecoveryOrCleanup;

  /// No description provided for @sourceFolder.
  ///
  /// In en, this message translates to:
  /// **'Source folder'**
  String get sourceFolder;

  /// No description provided for @destinationParentFolder.
  ///
  /// In en, this message translates to:
  /// **'Destination parent folder'**
  String get destinationParentFolder;

  /// No description provided for @theDestinationWillContainAFolder.
  ///
  /// In en, this message translates to:
  /// **'The destination will contain a folder with the same name. Existing folders are never overwritten.'**
  String get theDestinationWillContainAFolder;

  /// No description provided for @checkFolders.
  ///
  /// In en, this message translates to:
  /// **'Check folders'**
  String get checkFolders;

  /// No description provided for @applyMove.
  ///
  /// In en, this message translates to:
  /// **'Apply move'**
  String get applyMove;

  /// No description provided for @verifiedDestinationPath.
  ///
  /// In en, this message translates to:
  /// **'Verified destination path'**
  String get verifiedDestinationPath;

  /// No description provided for @checksPassedApplyMoveOpensA.
  ///
  /// In en, this message translates to:
  /// **'Checks passed. Apply move opens a final confirmation. Checks run again before moving data.'**
  String get checksPassedApplyMoveOpensA;

  /// No description provided for @checkingOperation.
  ///
  /// In en, this message translates to:
  /// **'Checking operation…'**
  String get checkingOperation;

  /// No description provided for @cancellationRequested.
  ///
  /// In en, this message translates to:
  /// **'Cancellation requested…'**
  String get cancellationRequested;

  /// No description provided for @cancelSafely.
  ///
  /// In en, this message translates to:
  /// **'Cancel safely'**
  String get cancelSafely;

  /// No description provided for @historyRecovery.
  ///
  /// In en, this message translates to:
  /// **'History & recovery'**
  String get historyRecovery;

  /// No description provided for @migrationsAppearHereInterruptedOperationsCan.
  ///
  /// In en, this message translates to:
  /// **'Migrations appear here. Interrupted operations can be recovered after restarting FileMover.'**
  String get migrationsAppearHereInterruptedOperationsCan;

  /// No description provided for @closeApplicationsUsingTheFolderLive.
  ///
  /// In en, this message translates to:
  /// **'Close applications using the folder. Live databases, system folders, network locations, encrypted files, and folders containing links are unsupported.'**
  String get closeApplicationsUsingTheFolderLive;

  /// No description provided for @doubleCheckUndo.
  ///
  /// In en, this message translates to:
  /// **'Double-check undo'**
  String get doubleCheckUndo;

  /// No description provided for @doubleCheckMigration.
  ///
  /// In en, this message translates to:
  /// **'Double-check migration'**
  String get doubleCheckMigration;

  /// No description provided for @moveTheCurrentDataBackTo.
  ///
  /// In en, this message translates to:
  /// **'Move the current data back to the original location and remove the junction.'**
  String get moveTheCurrentDataBackTo;

  /// No description provided for @moveThisFolderToTheDestination.
  ///
  /// In en, this message translates to:
  /// **'Move this folder to the destination and leave a junction at the original path.'**
  String get moveThisFolderToTheDestination;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @dataSpaceRequired.
  ///
  /// In en, this message translates to:
  /// **'Data / space required'**
  String get dataSpaceRequired;

  /// No description provided for @everyFileIsCheckedWithSha.
  ///
  /// In en, this message translates to:
  /// **'Every file is checked with SHA-256 before switching locations. Keep applications closed until this finishes.'**
  String get everyFileIsCheckedWithSha;

  /// No description provided for @iCheckedBothPathsAndClosed.
  ///
  /// In en, this message translates to:
  /// **'I checked both paths and closed applications using this folder.'**
  String get iCheckedBothPathsAndClosed;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirmAndUndo.
  ///
  /// In en, this message translates to:
  /// **'Confirm and undo'**
  String get confirmAndUndo;

  /// No description provided for @confirmAndMove.
  ///
  /// In en, this message translates to:
  /// **'Confirm and move'**
  String get confirmAndMove;

  /// No description provided for @migrationVerifiedTheOriginalPathNow.
  ///
  /// In en, this message translates to:
  /// **'Migration verified. The original path now points to the destination.'**
  String get migrationVerifiedTheOriginalPathNow;

  /// No description provided for @undoVerifiedYourCurrentDataIs.
  ///
  /// In en, this message translates to:
  /// **'Undo verified. Your current data is back at the original location.'**
  String get undoVerifiedYourCurrentDataIs;

  /// No description provided for @recoveryCompletedReviewTheOperationDetails.
  ///
  /// In en, this message translates to:
  /// **'Recovery completed. Review the operation details below.'**
  String get recoveryCompletedReviewTheOperationDetails;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @undone.
  ///
  /// In en, this message translates to:
  /// **'Undone'**
  String get undone;

  /// No description provided for @originalLocationRestored.
  ///
  /// In en, this message translates to:
  /// **'Original location restored'**
  String get originalLocationRestored;

  /// No description provided for @verifiedCleanupPending.
  ///
  /// In en, this message translates to:
  /// **'Verified · cleanup pending'**
  String get verifiedCleanupPending;

  /// No description provided for @recoveryRequired.
  ///
  /// In en, this message translates to:
  /// **'Recovery required'**
  String get recoveryRequired;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @migration.
  ///
  /// In en, this message translates to:
  /// **'Migration'**
  String get migration;

  /// No description provided for @originalPath.
  ///
  /// In en, this message translates to:
  /// **'Original path'**
  String get originalPath;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @backupPath.
  ///
  /// In en, this message translates to:
  /// **'Backup path'**
  String get backupPath;

  /// No description provided for @stagingPath.
  ///
  /// In en, this message translates to:
  /// **'Staging path'**
  String get stagingPath;

  /// No description provided for @retryCleanup.
  ///
  /// In en, this message translates to:
  /// **'Retry cleanup'**
  String get retryCleanup;

  /// No description provided for @recoverOriginalLocation.
  ///
  /// In en, this message translates to:
  /// **'Recover original location'**
  String get recoverOriginalLocation;

  /// No description provided for @undoMigration.
  ///
  /// In en, this message translates to:
  /// **'Undo migration'**
  String get undoMigration;

  /// No description provided for @browseFolder.
  ///
  /// In en, this message translates to:
  /// **'Browse {label}'**
  String browseFolder(String label);

  /// No description provided for @fileSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} files · {size} of data'**
  String fileSummary(int count, String size);

  /// No description provided for @spaceSummary.
  ///
  /// In en, this message translates to:
  /// **'{required} required · {free} available'**
  String spaceSummary(String required, String free);

  /// No description provided for @operationStatus.
  ///
  /// In en, this message translates to:
  /// **'{operation} · {status}'**
  String operationStatus(String operation, String status);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @originalDiagnosticDetails.
  ///
  /// In en, this message translates to:
  /// **'Original diagnostic details'**
  String get originalDiagnosticDetails;

  /// No description provided for @languageSettingsWarning.
  ///
  /// In en, this message translates to:
  /// **'Saved language settings could not be loaded. Built-in languages are available.'**
  String get languageSettingsWarning;

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying'**
  String get verifying;

  /// No description provided for @copying.
  ///
  /// In en, this message translates to:
  /// **'Copying'**
  String get copying;

  /// No description provided for @recovering.
  ///
  /// In en, this message translates to:
  /// **'Recovering'**
  String get recovering;

  /// No description provided for @switchingLocations.
  ///
  /// In en, this message translates to:
  /// **'Switching locations'**
  String get switchingLocations;

  /// No description provided for @cleaningUp.
  ///
  /// In en, this message translates to:
  /// **'Cleaning up'**
  String get cleaningUp;

  /// No description provided for @cancelledRestoringTheOriginalFolder.
  ///
  /// In en, this message translates to:
  /// **'Cancelled. Restoring the original folder.'**
  String get cancelledRestoringTheOriginalFolder;

  /// No description provided for @anotherFilemoverOperationIsRunningWait.
  ///
  /// In en, this message translates to:
  /// **'Another FileMover operation is running. Wait for it to finish.'**
  String get anotherFilemoverOperationIsRunningWait;

  /// No description provided for @resolveThePendingRecoveryOrCleanup.
  ///
  /// In en, this message translates to:
  /// **'Resolve the pending recovery or cleanup in History before starting another migration.'**
  String get resolveThePendingRecoveryOrCleanup;

  /// No description provided for @chooseAnAbsoluteLocalFolderPath.
  ///
  /// In en, this message translates to:
  /// **'Choose an absolute local folder path.'**
  String get chooseAnAbsoluteLocalFolderPath;

  /// No description provided for @driveRootsAndAlternateStreamPaths.
  ///
  /// In en, this message translates to:
  /// **'Drive roots and alternate stream paths cannot be migrated.'**
  String get driveRootsAndAlternateStreamPaths;

  /// No description provided for @linksAndMountedFoldersAreUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Links and mounted folders are unsupported:'**
  String get linksAndMountedFoldersAreUnsupported;

  /// No description provided for @systemApplicationAndFilemoverDataFolders.
  ///
  /// In en, this message translates to:
  /// **'System, application, and FileMover data folders cannot be migrated:'**
  String get systemApplicationAndFilemoverDataFolders;

  /// No description provided for @userProfileRootsCannotBeMigrated.
  ///
  /// In en, this message translates to:
  /// **'User profile roots cannot be migrated.'**
  String get userProfileRootsCannotBeMigrated;

  /// No description provided for @protectedDirectory.
  ///
  /// In en, this message translates to:
  /// **'Protected directory:'**
  String get protectedDirectory;

  /// No description provided for @bothSelectedFoldersMustExist.
  ///
  /// In en, this message translates to:
  /// **'Both selected folders must exist.'**
  String get bothSelectedFoldersMustExist;

  /// No description provided for @sourceAndFinalDestinationMustBe.
  ///
  /// In en, this message translates to:
  /// **'Source and final destination must be separate, non-overlapping folders.'**
  String get sourceAndFinalDestinationMustBe;

  /// No description provided for @theFinalDestinationAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'The final destination already exists:'**
  String get theFinalDestinationAlreadyExists;

  /// No description provided for @onlyFixedLocalNtfsVolumesAre.
  ///
  /// In en, this message translates to:
  /// **'Only fixed local NTFS volumes are supported in this version.'**
  String get onlyFixedLocalNtfsVolumesAre;

  /// No description provided for @aPathIsTooLongFor.
  ///
  /// In en, this message translates to:
  /// **'A path is too long for this version\'s Windows worker. Shorten the source/destination paths before migrating.'**
  String get aPathIsTooLongFor;

  /// No description provided for @insufficientDiskSpace.
  ///
  /// In en, this message translates to:
  /// **'Insufficient disk space'**
  String get insufficientDiskSpace;

  /// No description provided for @reparsePointsAreUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Reparse points are unsupported:'**
  String get reparsePointsAreUnsupported;

  /// No description provided for @encryptedFilesAreUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Encrypted files are unsupported:'**
  String get encryptedFilesAreUnsupported;

  /// No description provided for @multiplyLinkedFilesAreUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Multiply linked files are unsupported:'**
  String get multiplyLinkedFilesAreUnsupported;

  /// No description provided for @verificationFailedFileInventoryContentsStreams.
  ///
  /// In en, this message translates to:
  /// **'Verification failed: file inventory, contents, streams, permissions, attributes, or timestamps differ. Original data has been retained.'**
  String get verificationFailedFileInventoryContentsStreams;

  /// No description provided for @folderChangedAReparsePointAppeared.
  ///
  /// In en, this message translates to:
  /// **'Folder changed: a reparse point appeared:'**
  String get folderChangedAReparsePointAppeared;

  /// No description provided for @onlyACompletedMigrationCanBe.
  ///
  /// In en, this message translates to:
  /// **'Only a completed migration can be undone.'**
  String get onlyACompletedMigrationCanBe;

  /// No description provided for @theOriginalJunctionOrDestinationHas.
  ///
  /// In en, this message translates to:
  /// **'The original junction or destination has changed. Undo stopped to preserve data.'**
  String get theOriginalJunctionOrDestinationHas;

  /// No description provided for @junctionTargetVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Junction target verification failed.'**
  String get junctionTargetVerificationFailed;

  /// No description provided for @restoredDirectoryIdentityMismatch.
  ///
  /// In en, this message translates to:
  /// **'Restored directory identity mismatch.'**
  String get restoredDirectoryIdentityMismatch;

  /// No description provided for @junctionChangedDuringVerification.
  ///
  /// In en, this message translates to:
  /// **'Junction changed during verification.'**
  String get junctionChangedDuringVerification;

  /// No description provided for @accessThroughJunctionDidNotReach.
  ///
  /// In en, this message translates to:
  /// **'Access through junction did not reach the destination.'**
  String get accessThroughJunctionDidNotReach;

  /// No description provided for @directoryIdentityChangedKeeping.
  ///
  /// In en, this message translates to:
  /// **'Directory identity changed; keeping'**
  String get directoryIdentityChangedKeeping;

  /// No description provided for @unexpectedLinkRefusingCleanup.
  ///
  /// In en, this message translates to:
  /// **'Unexpected link; refusing cleanup:'**
  String get unexpectedLinkRefusingCleanup;

  /// No description provided for @thisOperationIsNotReadyFor.
  ///
  /// In en, this message translates to:
  /// **'This operation is not ready for cleanup.'**
  String get thisOperationIsNotReadyFor;

  /// No description provided for @destinationOrJunctionChangedBackupRetained.
  ///
  /// In en, this message translates to:
  /// **'Destination or junction changed. Backup retained.'**
  String get destinationOrJunctionChangedBackupRetained;

  /// No description provided for @restoredSourceChangedDestinationRetained.
  ///
  /// In en, this message translates to:
  /// **'Restored source changed. Destination retained.'**
  String get restoredSourceChangedDestinationRetained;

  /// No description provided for @originalBackupCannotBeIdentified.
  ///
  /// In en, this message translates to:
  /// **'Original backup cannot be identified:'**
  String get originalBackupCannotBeIdentified;

  /// No description provided for @originalPathIsOccupiedByAn.
  ///
  /// In en, this message translates to:
  /// **'Original path is occupied by an unexpected directory:'**
  String get originalPathIsOccupiedByAn;

  /// No description provided for @originalFolderRestoredAnyStagingDestination.
  ///
  /// In en, this message translates to:
  /// **'Original folder restored. Any staging/destination copy is retained for inspection.'**
  String get originalFolderRestoredAnyStagingDestination;

  /// No description provided for @undoDestinationCannotBeIdentifiedAll.
  ///
  /// In en, this message translates to:
  /// **'Undo destination cannot be identified. All data retained.'**
  String get undoDestinationCannotBeIdentifiedAll;

  /// No description provided for @originalPathIsOccupiedCannotRestore.
  ///
  /// In en, this message translates to:
  /// **'Original path is occupied. Cannot restore junction.'**
  String get originalPathIsOccupiedCannotRestore;

  /// No description provided for @junctionRestoredAnyStagingCopyIs.
  ///
  /// In en, this message translates to:
  /// **'Junction restored. Any staging copy is retained for inspection.'**
  String get junctionRestoredAnyStagingCopyIs;

  /// No description provided for @unexpectedLink.
  ///
  /// In en, this message translates to:
  /// **'Unexpected link:'**
  String get unexpectedLink;

  /// No description provided for @migrationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Migration cancelled.'**
  String get migrationCancelled;

  /// No description provided for @junctionPathIsOccupied.
  ///
  /// In en, this message translates to:
  /// **'Junction path is occupied:'**
  String get junctionPathIsOccupied;

  /// No description provided for @unexpectedJunctionTarget.
  ///
  /// In en, this message translates to:
  /// **'Unexpected junction target:'**
  String get unexpectedJunctionTarget;
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
