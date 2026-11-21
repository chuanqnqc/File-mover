// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get operationFailedReviewTheOriginal => '操作失败，请查看下方原始详情。';

  @override
  String get refreshHistory => '刷新历史记录';

  @override
  String get heading => '迁移数据，保留原路径。';

  @override
  String get intro => '安全迁移 Windows 文件夹，并在原位置创建目录联接。仅支持本地 NTFS 驱动器。';

  @override
  String get anOperationNeedsRecoveryOrCleanup =>
      '有操作需要恢复或清理。请先在历史记录中处理，再开始新的迁移。';

  @override
  String get sourceFolder => '源文件夹';

  @override
  String get destinationParentFolder => '目标父文件夹';

  @override
  String get theDestinationWillContainAFolder => '目标位置将创建同名文件夹，不会覆盖已有文件夹。';

  @override
  String get checkFolders => '检查文件夹';

  @override
  String get applyMove => '应用迁移';

  @override
  String get verifiedDestinationPath => '已检查的目标路径';

  @override
  String get checksPassedApplyMoveOpensA => '检查通过。点击“应用迁移”后需再次确认；迁移前将重新检查。';

  @override
  String get checkingOperation => '正在检查操作…';

  @override
  String get cancellationRequested => '已请求取消…';

  @override
  String get cancelSafely => '安全取消';

  @override
  String get historyRecovery => '历史记录与恢复';

  @override
  String get migrationsAppearHereInterruptedOperationsCan =>
      '迁移记录将显示在这里。操作中断后，可重新启动 FileMover 进行恢复。';

  @override
  String get closeApplicationsUsingTheFolderLive =>
      '请关闭正在使用该文件夹的应用。不支持运行中的数据库、系统文件夹、网络位置、加密文件以及包含链接的文件夹。';

  @override
  String get doubleCheckUndo => '再次确认撤销';

  @override
  String get doubleCheckMigration => '再次确认迁移';

  @override
  String get moveTheCurrentDataBackTo => '将当前数据迁回原位置，并移除目录联接。';

  @override
  String get moveThisFolderToTheDestination => '将此文件夹迁移至目标位置，并在原路径创建目录联接。';

  @override
  String get from => '原位置';

  @override
  String get to => '新位置';

  @override
  String get dataSpaceRequired => '数据大小 / 所需空间';

  @override
  String get everyFileIsCheckedWithSha =>
      '切换位置前，将使用 SHA-256 校验每个文件。完成前请保持相关应用关闭。';

  @override
  String get iCheckedBothPathsAndClosed => '我已核对两个路径，并关闭使用此文件夹的应用。';

  @override
  String get cancel => '取消';

  @override
  String get confirmAndUndo => '确认并撤销';

  @override
  String get confirmAndMove => '确认并迁移';

  @override
  String get migrationVerifiedTheOriginalPathNow => '迁移校验成功，原路径现已指向目标位置。';

  @override
  String get undoVerifiedYourCurrentDataIs => '撤销校验成功，当前数据已迁回原位置。';

  @override
  String get recoveryCompletedReviewTheOperationDetails => '恢复已完成，请查看下方操作详情。';

  @override
  String get completed => '已完成';

  @override
  String get undone => '已撤销';

  @override
  String get originalLocationRestored => '已恢复原位置';

  @override
  String get verifiedCleanupPending => '已校验 · 等待清理';

  @override
  String get recoveryRequired => '需要恢复';

  @override
  String get undo => '撤销';

  @override
  String get migration => '迁移';

  @override
  String get originalPath => '原路径';

  @override
  String get destination => '目标位置';

  @override
  String get backupPath => '备份路径';

  @override
  String get stagingPath => '临时副本路径';

  @override
  String get retryCleanup => '重试清理';

  @override
  String get recoverOriginalLocation => '恢复原位置';

  @override
  String get undoMigration => '撤销迁移';

  @override
  String browseFolder(String label) {
    return '浏览$label';
  }

  @override
  String fileSummary(int count, String size) {
    return '$count 个文件 · 数据大小 $size';
  }

  @override
  String spaceSummary(String required, String free) {
    return '需要 $required · 可用 $free';
  }

  @override
  String operationStatus(String operation, String status) {
    return '$operation · $status';
  }

  @override
  String get language => '语言';

  @override
  String get originalDiagnosticDetails => '原始诊断详情';

  @override
  String get languageSettingsWarning => '无法加载已保存的语言设置，仍可使用内置语言。';

  @override
  String get verifying => '正在校验';

  @override
  String get copying => '正在复制';

  @override
  String get recovering => '正在恢复';

  @override
  String get switchingLocations => '正在切换位置';

  @override
  String get cleaningUp => '正在清理';

  @override
  String get cancelledRestoringTheOriginalFolder => '已取消，正在恢复原文件夹。';

  @override
  String get anotherFilemoverOperationIsRunningWait =>
      '另一个 FileMover 操作正在运行，请等待完成。';

  @override
  String get resolveThePendingRecoveryOrCleanup => '请先在历史记录中完成待处理的恢复或清理。';

  @override
  String get chooseAnAbsoluteLocalFolderPath => '请选择本地文件夹的绝对路径。';

  @override
  String get driveRootsAndAlternateStreamPaths => '无法迁移驱动器根目录或备用数据流路径。';

  @override
  String get linksAndMountedFoldersAreUnsupported => '不支持链接和挂载的文件夹：';

  @override
  String get systemApplicationAndFilemoverDataFolders =>
      '无法迁移系统、应用和 FileMover 数据文件夹：';

  @override
  String get userProfileRootsCannotBeMigrated => '无法迁移用户配置文件根目录。';

  @override
  String get protectedDirectory => '这是受保护的目录：';

  @override
  String get bothSelectedFoldersMustExist => '所选的两个文件夹都必须存在。';

  @override
  String get sourceAndFinalDestinationMustBe => '源文件夹与最终目标必须相互独立，不能重叠。';

  @override
  String get theFinalDestinationAlreadyExists => '最终目标位置已存在：';

  @override
  String get onlyFixedLocalNtfsVolumesAre => '此版本仅支持本地固定 NTFS 卷。';

  @override
  String get aPathIsTooLongFor => '路径超出此版本的长度限制，请缩短源或目标路径后重试。';

  @override
  String get insufficientDiskSpace => '磁盘空间不足';

  @override
  String get reparsePointsAreUnsupported => '不支持重解析点：';

  @override
  String get encryptedFilesAreUnsupported => '不支持加密文件：';

  @override
  String get multiplyLinkedFilesAreUnsupported => '不支持具有多个硬链接的文件：';

  @override
  String get verificationFailedFileInventoryContentsStreams =>
      '校验失败：文件列表、内容、数据流、权限、属性或时间戳不一致。原始数据已保留。';

  @override
  String get folderChangedAReparsePointAppeared => '文件夹发生变化，出现了重解析点：';

  @override
  String get onlyACompletedMigrationCanBe => '只能撤销已完成的迁移。';

  @override
  String get theOriginalJunctionOrDestinationHas => '原目录联接或目标发生变化。为保留数据，已停止撤销。';

  @override
  String get junctionTargetVerificationFailed => '目录联接目标校验失败。';

  @override
  String get restoredDirectoryIdentityMismatch => '恢复后的目录标识不匹配。';

  @override
  String get junctionChangedDuringVerification => '校验过程中目录联接发生变化。';

  @override
  String get accessThroughJunctionDidNotReach => '通过目录联接访问时未到达目标位置。';

  @override
  String get directoryIdentityChangedKeeping => '目录标识发生变化，已保留副本。';

  @override
  String get unexpectedLinkRefusingCleanup => '发现非预期的链接，已停止清理：';

  @override
  String get thisOperationIsNotReadyFor => '此操作尚未满足清理条件。';

  @override
  String get destinationOrJunctionChangedBackupRetained => '目标或目录联接发生变化，备份已保留。';

  @override
  String get restoredSourceChangedDestinationRetained => '恢复后的源位置发生变化，目标副本已保留。';

  @override
  String get originalBackupCannotBeIdentified => '无法确认原始备份：';

  @override
  String get originalPathIsOccupiedByAn => '原路径被非预期的目录占用：';

  @override
  String get originalFolderRestoredAnyStagingDestination =>
      '原文件夹已恢复。临时副本或目标副本已保留，可供检查。';

  @override
  String get undoDestinationCannotBeIdentifiedAll => '无法确认撤销的目标，所有数据均已保留。';

  @override
  String get originalPathIsOccupiedCannotRestore => '原路径被占用，无法恢复目录联接。';

  @override
  String get junctionRestoredAnyStagingCopyIs => '目录联接已恢复，临时副本已保留，可供检查。';

  @override
  String get unexpectedLink => '发现非预期的链接：';

  @override
  String get migrationCancelled => '迁移已取消。';

  @override
  String get junctionPathIsOccupied => '目录联接路径被占用：';

  @override
  String get unexpectedJunctionTarget => '目录联接目标与预期不符：';
}
