import 'l10n/generated/app_localizations.dart';

// Worker and existing journals carry English diagnostic text.
String? localizedDiagnostic(String raw, AppLocalizations l10n) {
  final message = raw.trimLeft();
  final summaries = {
    'Verification failed: file inventory, contents, streams, permissions, attributes, or timestamps differ. Original data has been retained.':
        l10n.verificationFailedFileInventoryContentsStreams,
    'A path is too long for this version\'s Windows worker. Shorten the source/destination paths before migrating.':
        l10n.aPathIsTooLongFor,
    'Resolve the pending recovery or cleanup in History before starting another migration.':
        l10n.resolveThePendingRecoveryOrCleanup,
    'Original folder restored. Any staging/destination copy is retained for inspection.':
        l10n.originalFolderRestoredAnyStagingDestination,
    'The original junction or destination has changed. Undo stopped to preserve data.':
        l10n.theOriginalJunctionOrDestinationHas,
    'Source and final destination must be separate, non-overlapping folders.':
        l10n.sourceAndFinalDestinationMustBe,
    'System, application, and FileMover data folders cannot be migrated:':
        l10n.systemApplicationAndFilemoverDataFolders,
    'Junction restored. Any staging copy is retained for inspection.':
        l10n.junctionRestoredAnyStagingCopyIs,
    'Another FileMover operation is running. Wait for it to finish.':
        l10n.anotherFilemoverOperationIsRunningWait,
    'Only fixed local NTFS volumes are supported in this version.':
        l10n.onlyFixedLocalNtfsVolumesAre,
    'Drive roots and alternate stream paths cannot be migrated.':
        l10n.driveRootsAndAlternateStreamPaths,
    'Undo destination cannot be identified. All data retained.':
        l10n.undoDestinationCannotBeIdentifiedAll,
    'Access through junction did not reach the destination.':
        l10n.accessThroughJunctionDidNotReach,
    'Original path is occupied by an unexpected directory:':
        l10n.originalPathIsOccupiedByAn,
    'Original path is occupied. Cannot restore junction.':
        l10n.originalPathIsOccupiedCannotRestore,
    'Destination or junction changed. Backup retained.':
        l10n.destinationOrJunctionChangedBackupRetained,
    'Restored source changed. Destination retained.':
        l10n.restoredSourceChangedDestinationRetained,
    'Links and mounted folders are unsupported:':
        l10n.linksAndMountedFoldersAreUnsupported,
    'Cancelled. Restoring the original folder.':
        l10n.cancelledRestoringTheOriginalFolder,
    'Folder changed: a reparse point appeared:':
        l10n.folderChangedAReparsePointAppeared,
    'Only a completed migration can be undone.':
        l10n.onlyACompletedMigrationCanBe,
    'This operation is not ready for cleanup.': l10n.thisOperationIsNotReadyFor,
    'User profile roots cannot be migrated.':
        l10n.userProfileRootsCannotBeMigrated,
    'Multiply linked files are unsupported:':
        l10n.multiplyLinkedFilesAreUnsupported,
    'Choose an absolute local folder path.':
        l10n.chooseAnAbsoluteLocalFolderPath,
    'The final destination already exists:':
        l10n.theFinalDestinationAlreadyExists,
    'Restored directory identity mismatch.':
        l10n.restoredDirectoryIdentityMismatch,
    'Junction changed during verification.':
        l10n.junctionChangedDuringVerification,
    'Original backup cannot be identified:':
        l10n.originalBackupCannotBeIdentified,
    'Junction target verification failed.':
        l10n.junctionTargetVerificationFailed,
    'Directory identity changed; keeping': l10n.directoryIdentityChangedKeeping,
    'Unexpected link; refusing cleanup:': l10n.unexpectedLinkRefusingCleanup,
    'Both selected folders must exist.': l10n.bothSelectedFoldersMustExist,
    'Encrypted files are unsupported:': l10n.encryptedFilesAreUnsupported,
    'Reparse points are unsupported:': l10n.reparsePointsAreUnsupported,
    'Unexpected junction target:': l10n.unexpectedJunctionTarget,
    'Junction path is occupied:': l10n.junctionPathIsOccupied,
    'Insufficient disk space': l10n.insufficientDiskSpace,
    'Protected directory:': l10n.protectedDirectory,
    'Migration cancelled.': l10n.migrationCancelled,
    'Unexpected link:': l10n.unexpectedLink,
  };
  for (final entry in summaries.entries) {
    if (message.startsWith(entry.key)) return entry.value;
  }
  return null;
}
