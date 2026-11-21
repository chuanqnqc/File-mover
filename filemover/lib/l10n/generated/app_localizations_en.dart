// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get operationFailedReviewTheOriginal =>
      'Operation failed. Review the original details below.';

  @override
  String get refreshHistory => 'Refresh history';

  @override
  String get heading => 'Move the data. Keep the path.';

  @override
  String get intro =>
      'Safely relocate a Windows folder and leave a junction at its original location. Local NTFS drives only.';

  @override
  String get anOperationNeedsRecoveryOrCleanup =>
      'An operation needs recovery or cleanup. Resolve it in History before starting another move.';

  @override
  String get sourceFolder => 'Source folder';

  @override
  String get destinationParentFolder => 'Destination parent folder';

  @override
  String get theDestinationWillContainAFolder =>
      'The destination will contain a folder with the same name. Existing folders are never overwritten.';

  @override
  String get checkFolders => 'Check folders';

  @override
  String get applyMove => 'Apply move';

  @override
  String get verifiedDestinationPath => 'Verified destination path';

  @override
  String get checksPassedApplyMoveOpensA =>
      'Checks passed. Apply move opens a final confirmation. Checks run again before moving data.';

  @override
  String get checkingOperation => 'Checking operation…';

  @override
  String get cancellationRequested => 'Cancellation requested…';

  @override
  String get cancelSafely => 'Cancel safely';

  @override
  String get historyRecovery => 'History & recovery';

  @override
  String get migrationsAppearHereInterruptedOperationsCan =>
      'Migrations appear here. Interrupted operations can be recovered after restarting FileMover.';

  @override
  String get closeApplicationsUsingTheFolderLive =>
      'Close applications using the folder. Live databases, system folders, network locations, encrypted files, and folders containing links are unsupported.';

  @override
  String get doubleCheckUndo => 'Double-check undo';

  @override
  String get doubleCheckMigration => 'Double-check migration';

  @override
  String get moveTheCurrentDataBackTo =>
      'Move the current data back to the original location and remove the junction.';

  @override
  String get moveThisFolderToTheDestination =>
      'Move this folder to the destination and leave a junction at the original path.';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get dataSpaceRequired => 'Data / space required';

  @override
  String get everyFileIsCheckedWithSha =>
      'Every file is checked with SHA-256 before switching locations. Keep applications closed until this finishes.';

  @override
  String get iCheckedBothPathsAndClosed =>
      'I checked both paths and closed applications using this folder.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmAndUndo => 'Confirm and undo';

  @override
  String get confirmAndMove => 'Confirm and move';

  @override
  String get migrationVerifiedTheOriginalPathNow =>
      'Migration verified. The original path now points to the destination.';

  @override
  String get undoVerifiedYourCurrentDataIs =>
      'Undo verified. Your current data is back at the original location.';

  @override
  String get recoveryCompletedReviewTheOperationDetails =>
      'Recovery completed. Review the operation details below.';

  @override
  String get completed => 'Completed';

  @override
  String get undone => 'Undone';

  @override
  String get originalLocationRestored => 'Original location restored';

  @override
  String get verifiedCleanupPending => 'Verified · cleanup pending';

  @override
  String get recoveryRequired => 'Recovery required';

  @override
  String get undo => 'Undo';

  @override
  String get migration => 'Migration';

  @override
  String get originalPath => 'Original path';

  @override
  String get destination => 'Destination';

  @override
  String get backupPath => 'Backup path';

  @override
  String get stagingPath => 'Staging path';

  @override
  String get retryCleanup => 'Retry cleanup';

  @override
  String get recoverOriginalLocation => 'Recover original location';

  @override
  String get undoMigration => 'Undo migration';

  @override
  String browseFolder(String label) {
    return 'Browse $label';
  }

  @override
  String fileSummary(int count, String size) {
    return '$count files · $size of data';
  }

  @override
  String spaceSummary(String required, String free) {
    return '$required required · $free available';
  }

  @override
  String operationStatus(String operation, String status) {
    return '$operation · $status';
  }

  @override
  String get language => 'Language';

  @override
  String get originalDiagnosticDetails => 'Original diagnostic details';

  @override
  String get languageSettingsWarning =>
      'Saved language settings could not be loaded. Built-in languages are available.';

  @override
  String get verifying => 'Verifying';

  @override
  String get copying => 'Copying';

  @override
  String get recovering => 'Recovering';

  @override
  String get switchingLocations => 'Switching locations';

  @override
  String get cleaningUp => 'Cleaning up';

  @override
  String get cancelledRestoringTheOriginalFolder =>
      'Cancelled. Restoring the original folder.';

  @override
  String get anotherFilemoverOperationIsRunningWait =>
      'Another FileMover operation is running. Wait for it to finish.';

  @override
  String get resolveThePendingRecoveryOrCleanup =>
      'Resolve the pending recovery or cleanup in History before starting another migration.';

  @override
  String get chooseAnAbsoluteLocalFolderPath =>
      'Choose an absolute local folder path.';

  @override
  String get driveRootsAndAlternateStreamPaths =>
      'Drive roots and alternate stream paths cannot be migrated.';

  @override
  String get linksAndMountedFoldersAreUnsupported =>
      'Links and mounted folders are unsupported:';

  @override
  String get systemApplicationAndFilemoverDataFolders =>
      'System, application, and FileMover data folders cannot be migrated:';

  @override
  String get userProfileRootsCannotBeMigrated =>
      'User profile roots cannot be migrated.';

  @override
  String get protectedDirectory => 'Protected directory:';

  @override
  String get bothSelectedFoldersMustExist =>
      'Both selected folders must exist.';

  @override
  String get sourceAndFinalDestinationMustBe =>
      'Source and final destination must be separate, non-overlapping folders.';

  @override
  String get theFinalDestinationAlreadyExists =>
      'The final destination already exists:';

  @override
  String get onlyFixedLocalNtfsVolumesAre =>
      'Only fixed local NTFS volumes are supported in this version.';

  @override
  String get aPathIsTooLongFor =>
      'A path is too long for this version\'s Windows worker. Shorten the source/destination paths before migrating.';

  @override
  String get insufficientDiskSpace => 'Insufficient disk space';

  @override
  String get reparsePointsAreUnsupported => 'Reparse points are unsupported:';

  @override
  String get encryptedFilesAreUnsupported => 'Encrypted files are unsupported:';

  @override
  String get multiplyLinkedFilesAreUnsupported =>
      'Multiply linked files are unsupported:';

  @override
  String get verificationFailedFileInventoryContentsStreams =>
      'Verification failed: file inventory, contents, streams, permissions, attributes, or timestamps differ. Original data has been retained.';

  @override
  String get folderChangedAReparsePointAppeared =>
      'Folder changed: a reparse point appeared:';

  @override
  String get onlyACompletedMigrationCanBe =>
      'Only a completed migration can be undone.';

  @override
  String get theOriginalJunctionOrDestinationHas =>
      'The original junction or destination has changed. Undo stopped to preserve data.';

  @override
  String get junctionTargetVerificationFailed =>
      'Junction target verification failed.';

  @override
  String get restoredDirectoryIdentityMismatch =>
      'Restored directory identity mismatch.';

  @override
  String get junctionChangedDuringVerification =>
      'Junction changed during verification.';

  @override
  String get accessThroughJunctionDidNotReach =>
      'Access through junction did not reach the destination.';

  @override
  String get directoryIdentityChangedKeeping =>
      'Directory identity changed; keeping';

  @override
  String get unexpectedLinkRefusingCleanup =>
      'Unexpected link; refusing cleanup:';

  @override
  String get thisOperationIsNotReadyFor =>
      'This operation is not ready for cleanup.';

  @override
  String get destinationOrJunctionChangedBackupRetained =>
      'Destination or junction changed. Backup retained.';

  @override
  String get restoredSourceChangedDestinationRetained =>
      'Restored source changed. Destination retained.';

  @override
  String get originalBackupCannotBeIdentified =>
      'Original backup cannot be identified:';

  @override
  String get originalPathIsOccupiedByAn =>
      'Original path is occupied by an unexpected directory:';

  @override
  String get originalFolderRestoredAnyStagingDestination =>
      'Original folder restored. Any staging/destination copy is retained for inspection.';

  @override
  String get undoDestinationCannotBeIdentifiedAll =>
      'Undo destination cannot be identified. All data retained.';

  @override
  String get originalPathIsOccupiedCannotRestore =>
      'Original path is occupied. Cannot restore junction.';

  @override
  String get junctionRestoredAnyStagingCopyIs =>
      'Junction restored. Any staging copy is retained for inspection.';

  @override
  String get unexpectedLink => 'Unexpected link:';

  @override
  String get migrationCancelled => 'Migration cancelled.';

  @override
  String get junctionPathIsOccupied => 'Junction path is occupied:';

  @override
  String get unexpectedJunctionTarget => 'Unexpected junction target:';
}
