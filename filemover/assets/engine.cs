using System;
using System.IO;
using System.Text;
using System.Linq;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Threading;
using System.Web.Script.Serialization;
using Microsoft.Win32.SafeHandles;

namespace FileMover {
public sealed class Request {
    public string action, source, parent, id, dataRoot;
}
public sealed class Entry {
    public string path, hash, acl;
    public long size, modified, created;
    public int attributes;
    public bool directory;
}
public sealed class Record {
    public string id, source, destination, backup, stage, sourceId, destinationId,
        stageId, backupId, state, message, started, direction, parentOperation;
    public List<Entry> manifest;
    public long bytes;
}
public static class Engine {
    static readonly JavaScriptSerializer Json = new JavaScriptSerializer { MaxJsonLength = Int32.MaxValue, RecursionLimit = 100 };
    static string Root;
    static string CancelPath;
    static void Emit(string type, object data) {
        Console.WriteLine(Json.Serialize(new { type = type, data = data }));
        Console.Out.Flush();
    }
    static void Progress(string phase, string path, long done, long total) {
        Emit("progress", new { phase = phase, path = path, done = done, total = total });
    }
    static void CheckCancel() {
        if (CancelPath != null && File.Exists(CancelPath)) throw new OperationCanceledException("Cancelled. Restoring the original folder.");
    }
    public static void Run(string encoded) {
        Request q = Json.Deserialize<Request>(Encoding.UTF8.GetString(Convert.FromBase64String(encoded)));
        Root = Path.GetFullPath(q.dataRoot);
        Directory.CreateDirectory(Root);
        using (var mutex = new Mutex(false, "Local\\FileMover.DirectoryMigration.v1")) {
            bool acquired = false;
            try {
                try { acquired = mutex.WaitOne(0); } catch (AbandonedMutexException) { acquired = true; }
                if (!acquired) throw new IOException("Another FileMover operation is running. Wait for it to finish.");
                CancelPath = null;
                if (q.action == "move" || q.action == "undo" || q.action == "preflight" || q.action == "undoPreflight") {
                    CancelPath = Path.Combine(Root, "cancel");
                    if (File.Exists(CancelPath)) File.Delete(CancelPath);
                }
                if (q.action == "history") { Emit("result", History()); return; }
                if (q.action == "recover") { Recover(Load(q.id)); Emit("result", History()); return; }
                if (q.action == "cleanup") { Cleanup(Load(q.id)); Emit("result", History()); return; }
                if (q.action == "preflight") { EnsureRecovered(); Emit("result", Preflight(q.source, q.parent, false)); return; }
                if (q.action == "undoPreflight") {
                    EnsureRecovered(); var old = Load(q.id); ValidateUndo(old);
                    Emit("result", Preflight(old.destination, Path.GetDirectoryName(old.source), true)); return;
                }
                EnsureRecovered();
                if (q.action == "move") Migrate(q.source, q.parent, null);
                else if (q.action == "undo") { var old = Load(q.id); ValidateUndo(old); Migrate(old.destination, Path.GetDirectoryName(old.source), old); }
                else throw new ArgumentException("Unknown operation.");
                Emit("result", History());
            } catch (Exception e) {
                Emit("error", new { message = e.Message, code = e.HResult, cancelled = e is OperationCanceledException, details = e.ToString() });
            } finally { if (acquired) mutex.ReleaseMutex(); }
        }
    }
    static string Journal(string id) {
        Guid value;
        if (!Guid.TryParseExact(id, "N", out value)) throw new IOException("Invalid operation identifier.");
        return Path.Combine(Root, id + ".json");
    }
    static void Save(Record r, string state) {
        r.state = state;
        string file = Journal(r.id), temp = file + ".tmp";
        byte[] bytes = Encoding.UTF8.GetBytes(Json.Serialize(r));
        using (var stream = new FileStream(temp, FileMode.Create, FileAccess.Write, FileShare.None, 4096, FileOptions.WriteThrough)) {
            stream.Write(bytes, 0, bytes.Length); stream.Flush(true);
        }
        if (File.Exists(file)) File.Replace(temp, file, null); else File.Move(temp, file);
    }
    static Record Load(string id) { return Json.Deserialize<Record>(File.ReadAllText(Journal(id))); }
    static List<Record> History() {
        var list = new List<Record>();
        foreach (string file in Directory.GetFiles(Root, "*.json")) {
            var r = Json.Deserialize<Record>(File.ReadAllText(file));
            Journal(r.id); r.manifest = null; list.Add(r);
        }
        return list.OrderByDescending(r => r.started).ToList();
    }
    static bool Finished(string state) { return state == "complete" || state == "undone" || state == "rolledBack"; }
    static void EnsureRecovered() {
        if (History().Any(r => !Finished(r.state))) throw new IOException("Resolve the pending recovery or cleanup in History before starting another migration.");
    }
    static string Normal(string path, bool allowRoot = false) {
        if (String.IsNullOrWhiteSpace(path) || path.Length < 3 || !Char.IsLetter(path[0]) || path[1] != ':' || (path[2] != '\\' && path[2] != '/'))
            throw new IOException("Choose an absolute local folder path.");
        string full = Path.GetFullPath(path).TrimEnd('\\');
        if (allowRoot && full.Length == 2) return full + "\\";
        if (full.Length <= 3 || full.IndexOf(':', 2) >= 0) throw new IOException("Drive roots and alternate stream paths cannot be migrated.");
        return full;
    }
    static bool Equal(string a, string b) { return String.Equals(a, b, StringComparison.OrdinalIgnoreCase); }
    static bool Within(string a, string b) { return Equal(a, b) || a.StartsWith(b.TrimEnd('\\') + "\\", StringComparison.OrdinalIgnoreCase); }
    static bool Exists(string path) { return Native.Attributes(path) != UInt32.MaxValue; }
    static void PlainAncestors(string path) {
        for (var d = new DirectoryInfo(path); d != null; d = d.Parent) {
            if ((Native.Attributes(d.FullName) & (uint)FileAttributes.ReparsePoint) != 0) throw new IOException("Links and mounted folders are unsupported: " + d.FullName);
        }
    }
    static void Protect(string path, bool destinationParent = false) {
        string[] forbidden = { Environment.GetFolderPath(Environment.SpecialFolder.Windows),
            Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
            Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86),
            Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), Root };
        foreach (string p in forbidden.Where(p => !String.IsNullOrEmpty(p)))
            if (Within(path, p) || (!destinationParent && Within(p, path))) throw new IOException("System, application, and FileMover data folders cannot be migrated: " + path);
        string profile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        string users = String.IsNullOrEmpty(profile) ? null : Path.GetDirectoryName(profile);
        if (!destinationParent && ((!String.IsNullOrEmpty(users) && Within(users, path)) || Equal(path, profile)))
            throw new IOException("User profile roots cannot be migrated.");
        foreach (string part in path.Split('\\'))
            if (Equal(part, "System Volume Information") || Equal(part, "$Recycle.Bin") || Equal(part, "WindowsApps") || Equal(part, "Recovery"))
                throw new IOException("Protected directory: " + path);
    }
    static object Preflight(string source, string parent, bool undo) {
        source = Normal(source); parent = Normal(parent, true);
        if (!Directory.Exists(source) || !Directory.Exists(parent)) throw new IOException("Both selected folders must exist.");
        PlainAncestors(source); PlainAncestors(parent); Protect(source); Protect(parent, true);
        string destination = Path.Combine(parent, Path.GetFileName(source));
        if (Within(source, destination) || Within(destination, source)) throw new IOException("Source and final destination must be separate, non-overlapping folders.");
        if (!undo && Exists(destination)) throw new IOException("The final destination already exists: " + destination);
        foreach (string path in new [] { source, parent }) {
            var drive = new DriveInfo(Path.GetPathRoot(path));
            if (!drive.IsReady || drive.DriveType != DriveType.Fixed || !Equal(drive.DriveFormat, "NTFS"))
                throw new IOException("Only fixed local NTFS volumes are supported in this version.");
        }
        // Probe create/delete access without touching any user file.
        Probe(parent); Probe(Path.GetDirectoryName(source));
        using (Native.Open(source, Native.DELETE | Native.READ_CONTROL, 7)) { }
        var manifest = Scan(source, true);
        // Windows PowerShell's .NET Framework file APIs have legacy path limits.
        // Validate the expanded backup/staging paths before renaming anything.
        foreach (var entry in manifest.Where(e => e.attributes != -1)) {
            int suffix = entry.path.Length == 0 ? 0 : entry.path.Length + 1;
            if (source.Length + 51 + suffix >= 248 || parent.Length + 50 + suffix >= 248 || destination.Length + suffix >= 248)
                throw new IOException("A path is too long for this version's Windows worker. Shorten the source/destination paths before migrating.");
        }
        long size = manifest.Sum(e => e.size);
        long reserve = Math.Max(256L * 1024 * 1024, (long)Math.Ceiling(size * .05));
        long free = new DriveInfo(Path.GetPathRoot(parent)).AvailableFreeSpace;
        if (free < size + reserve) throw new IOException("Insufficient disk space. Need " + (size + reserve) + " bytes; available " + free + ".");
        return new { source = source, parent = parent, destination = destination, bytes = size, required = size + reserve,
            free = free, files = manifest.Count(e => !e.directory && e.attributes != -1) };
    }
    static void Probe(string parent) {
        string path = Path.Combine(parent, ".filemover-probe-" + Guid.NewGuid().ToString("N"));
        using (new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.None, 1, FileOptions.DeleteOnClose)) { }
    }
    static string Acl(string p, bool directory) {
        var sections = System.Security.AccessControl.AccessControlSections.Access;
        System.Security.AccessControl.FileSystemSecurity security = directory
            ? (System.Security.AccessControl.FileSystemSecurity)Directory.GetAccessControl(p, sections) : File.GetAccessControl(p, sections);
        // Inheritance flags and canonical ACE ordering change when access rules
        // become explicit on the destination. Compare the actual access rules.
        return String.Join("|", security.GetAccessRules(true, true, typeof(System.Security.Principal.SecurityIdentifier))
            .Cast<System.Security.AccessControl.FileSystemAccessRule>()
            .Select(rule => rule.IdentityReference.Value + ":" + rule.AccessControlType + ":" + (int)rule.FileSystemRights + ":" + (int)rule.InheritanceFlags + ":" + (int)rule.PropagationFlags)
            .OrderBy(rule => rule, StringComparer.Ordinal));
    }
    static List<Entry> Scan(string root, bool hash) {
        var entries = new List<Entry>();
        ScanAt(root, root, entries, hash);
        return entries.OrderBy(e => e.path, StringComparer.OrdinalIgnoreCase).ToList();
    }
    static void ScanAt(string root, string path, List<Entry> entries, bool hash) {
        CheckCancel();
        FileAttributes attrs = File.GetAttributes(path);
        if ((attrs & FileAttributes.ReparsePoint) != 0) throw new IOException("Reparse points are unsupported: " + path);
        if ((attrs & FileAttributes.Encrypted) != 0) throw new IOException("Encrypted files are unsupported: " + path);
        bool dir = (attrs & FileAttributes.Directory) != 0;
        if (!dir && Native.LinkCount(path) > 1) throw new IOException("Multiply linked files are unsupported: " + path);
        string relative = Equal(root, path) ? "" : path.Substring(root.Length + 1);
        entries.Add(new Entry { path = relative, directory = dir, size = 0, hash = "", acl = Acl(path, dir),
            attributes = (int)(attrs & ~(FileAttributes.Archive | FileAttributes.Normal)),
            modified = File.GetLastWriteTimeUtc(path).Ticks, created = File.GetCreationTimeUtc(path).Ticks });
        foreach (var stream in Native.Streams(path)) {
            if (dir && stream.Key == "::$DATA") continue;
            string suffix = stream.Key == "::$DATA" ? "" : stream.Key;
            string streamPath = path + suffix;
            string digest = "";
            if (hash) {
                Progress("Verifying", relative + suffix, 0, stream.Value);
                using (var input = Native.DataStream(streamPath, false))
                using (var sha = SHA256.Create()) {
                    byte[] buffer = new byte[1024 * 1024]; int n; long done = 0;
                    while ((n = input.Read(buffer, 0, buffer.Length)) != 0) {
                        CheckCancel(); sha.TransformBlock(buffer, 0, n, buffer, 0); done += n;
                        if (done % (16 * 1024 * 1024) == 0) Progress("Verifying", relative + suffix, done, stream.Value);
                    }
                    sha.TransformFinalBlock(new byte[0], 0, 0); digest = BitConverter.ToString(sha.Hash).Replace("-", "");
                }
            }
            entries.Add(new Entry { path = relative + suffix, directory = false, size = stream.Value, hash = digest, attributes = -1 });
        }
        if (dir) foreach (string child in Directory.GetFileSystemEntries(path)) ScanAt(root, child, entries, hash);
    }
    static void Match(List<Entry> a, List<Entry> b) {
        if (Json.Serialize(a) != Json.Serialize(b)) throw new IOException("Verification failed: file inventory, contents, streams, permissions, attributes, or timestamps differ. Original data has been retained.");
    }
    static void CopyTree(string source, string target) {
        CheckCancel();
        foreach (string child in Directory.GetFileSystemEntries(source)) {
            CheckCancel(); string dest = Path.Combine(target, Path.GetFileName(child));
            FileAttributes attrs = File.GetAttributes(child);
            if ((attrs & FileAttributes.ReparsePoint) != 0) throw new IOException("Folder changed: a reparse point appeared: " + child);
            Progress("Copying", child, 0, 0);
            if ((attrs & FileAttributes.Directory) != 0) { Directory.CreateDirectory(dest); CopyTree(child, dest); }
            else Native.Copy(child, dest, CheckCancel);
        }
        // Copy directory streams too; CopyFileEx handles file streams and attributes.
        foreach (var stream in Native.Streams(source).Where(s => s.Key != "::$DATA")) {
            using (var input = Native.DataStream(source + stream.Key, false))
            using (var output = Native.DataStream(target + stream.Key, true)) {
                byte[] buffer = new byte[1024 * 1024]; int n;
                while ((n = input.Read(buffer, 0, buffer.Length)) > 0) { CheckCancel(); output.Write(buffer, 0, n); }
                output.Flush(true);
            }
        }
        Directory.SetCreationTimeUtc(target, Directory.GetCreationTimeUtc(source));
        Directory.SetLastWriteTimeUtc(target, Directory.GetLastWriteTimeUtc(source));
        var security = Directory.GetAccessControl(source, System.Security.AccessControl.AccessControlSections.Access);
        security.SetAccessRuleProtection(true, true); Directory.SetAccessControl(target, security);
        File.SetAttributes(target, File.GetAttributes(source));
    }
    static void ValidateUndo(Record old) {
        if (old.direction != "move" || old.state != "complete") throw new IOException("Only a completed migration can be undone.");
        if (!Native.IsJunctionTo(old.source, old.destination) || !Equal(Native.Identity(old.destination), old.destinationId))
            throw new IOException("The original junction or destination has changed. Undo stopped to preserve data.");
    }
    static void Migrate(string source, string parent, Record old) {
        Preflight(source, parent, old != null);
        source = Normal(source); parent = Normal(parent, true);
        string id = Guid.NewGuid().ToString("N");
        var r = new Record { id = id, source = old == null ? source : old.source,
            destination = source, direction = old == null ? "move" : "undo", parentOperation = old == null ? null : old.id,
            started = DateTime.UtcNow.ToString("o"), message = "", sourceId = Native.Identity(source) };
        if (old == null) r.destination = Path.Combine(parent, Path.GetFileName(source));
        r.backup = old == null ? source + ".filemover-backup-" + id : null;
        r.stage = Path.Combine(parent, ".filemover-stage-" + id);
        Save(r, "prepared");
        try {
            if (old == null) {
                Save(r, "renamingSource"); Directory.Move(r.source, r.backup);
                r.backupId = Native.Identity(r.backup); Save(r, "sourceRenamed");
                source = r.backup;
            }
            Save(r, "creatingStage"); Directory.CreateDirectory(r.stage);
            r.stageId = Native.Identity(r.stage); Save(r, "copying");
            // Keep existing files open without write/delete sharing while taking and copying the snapshot.
            using (var locks = new TreeLocks(source)) {
                r.manifest = Scan(source, true); r.bytes = r.manifest.Sum(e => e.size); Save(r, "copying");
                CopyTree(source, r.stage); Save(r, "verifying");
                Match(r.manifest, Scan(r.stage, true)); Match(r.manifest, Scan(source, true));
                CheckCancel();
                // Cancellation is deferred from here until commit or rollback.
                CancelPath = null;
                Progress("Switching locations", r.source, 0, 0);
                if (old == null) {
                    Save(r, "publishing"); Directory.Move(r.stage, r.destination);
                    r.destinationId = Native.Identity(r.destination); Save(r, "creatingJunction");
                    Native.CreateJunction(r.source, r.destination);
                    Save(r, "checkingJunction");
                    if (!Native.IsJunctionTo(r.source, r.destination)) throw new IOException("Junction target verification failed.");
                    Match(r.manifest, ScanThroughJunction(r.source, r.destination));
                } else {
                    ValidateUndo(old);
                    Save(r, "removingJunction"); Native.RemoveJunction(r.source, r.destination);
                    Save(r, "restoringSource"); Directory.Move(r.stage, r.source);
                    if (!Equal(Native.Identity(r.source), r.stageId)) throw new IOException("Restored directory identity mismatch.");
                }
                Save(r, "committed");
            }
            Cleanup(r);
        } catch (Exception e) {
            r.message = e.Message;
            if (r.state == "committed" || r.state == "cleanupPending" || r.state == "complete") {
                Save(r, "cleanupPending");
            } else {
                try { Recover(r); } catch (Exception recovery) { r.message = e.Message + " Recovery needs attention: " + recovery.Message; Save(r, "recoveryNeeded"); }
            }
            throw new IOException(r.message, e);
        }
    }
    static List<Entry> ScanThroughJunction(string junction, string target) {
        // Root is intentionally a junction; enumerate its children and use target metadata for the root.
        if (!Native.IsJunctionTo(junction, target)) throw new IOException("Junction changed during verification.");
        var result = Scan(target, true);
        foreach (string child in Directory.GetFileSystemEntries(junction)) {
            string corresponding = Path.Combine(target, Path.GetFileName(child));
            if (!Equal(Native.Identity(child), Native.Identity(corresponding))) throw new IOException("Access through junction did not reach the destination.");
        }
        return result;
    }
    static bool Owned(string path, string identity) { return !String.IsNullOrEmpty(path) && !String.IsNullOrEmpty(identity) && Exists(path) && Equal(Native.Identity(path), identity); }
    static void DeleteOwned(string path, string identity) {
        if (!Exists(path)) return;
        if (!Owned(path, identity)) throw new IOException("Directory identity changed; keeping " + path);
        PlainAncestors(path);
        SafeDelete(path);
    }
    static void SafeDelete(string path) {
        FileAttributes a = File.GetAttributes(path);
        if ((a & FileAttributes.ReparsePoint) != 0) throw new IOException("Unexpected link; refusing cleanup: " + path);
        if ((a & FileAttributes.Directory) != 0) {
            foreach (string p in Directory.GetFileSystemEntries(path)) SafeDelete(p);
            File.SetAttributes(path, FileAttributes.Directory); Directory.Delete(path);
        } else { File.SetAttributes(path, FileAttributes.Normal); File.Delete(path); }
    }
    static void Cleanup(Record r) {
        if (r.state != "committed" && r.state != "cleanupPending") throw new IOException("This operation is not ready for cleanup.");
        Save(r, "cleanupPending"); Progress("Cleaning up", "", 0, 0);
        if (r.direction == "move") {
            if (!Owned(r.destination, r.destinationId) || !Native.IsJunctionTo(r.source, r.destination)) throw new IOException("Destination or junction changed. Backup retained.");
            DeleteOwned(r.backup, r.backupId ?? r.sourceId);
        } else {
            if (!Owned(r.source, r.stageId)) throw new IOException("Restored source changed. Destination retained.");
            // A successful undo removes only the recorded destination, never a link target discovered by traversal.
            DeleteOwned(r.destination, r.sourceId);
            var old = Load(r.parentOperation); Save(old, "undone");
        }
        r.message = ""; r.manifest = null; Save(r, "complete");
    }
    static void Recover(Record r) {
        CancelPath = null;
        if (Finished(r.state)) return;
        if (r.state == "committed" || r.state == "cleanupPending") { Cleanup(r); return; }
        Progress("Recovering", r.source, 0, 0);
        if (r.direction == "move") {
            if (Native.IsJunctionTo(r.source, r.destination)) Native.RemoveJunction(r.source, r.destination);
            if (!Exists(r.source)) {
                if (!Owned(r.backup, r.sourceId)) throw new IOException("Original backup cannot be identified: " + r.backup);
                Directory.Move(r.backup, r.source);
            }
            if (!Owned(r.source, r.sourceId)) throw new IOException("Original path is occupied by an unexpected directory: " + r.source);
            // Leave copied data intact on failure. It can be inspected or removed manually after recovery.
            r.message = (r.message ?? "") + " Original folder restored. Any staging/destination copy is retained for inspection.";
        } else {
            if (Owned(r.source, r.stageId)) {
                // The reverse switch completed before the journal was flushed. Keep both copies; finish cleanup explicitly.
                Save(r, "committed"); Cleanup(r); return;
            }
            if (!Owned(r.destination, r.sourceId)) throw new IOException("Undo destination cannot be identified. All data retained.");
            if (!Exists(r.source)) Native.CreateJunction(r.source, r.destination);
            if (!Native.IsJunctionTo(r.source, r.destination)) throw new IOException("Original path is occupied. Cannot restore junction.");
            r.message = (r.message ?? "") + " Junction restored. Any staging copy is retained for inspection.";
        }
        Save(r, "rolledBack");
    }
    sealed class TreeLocks : IDisposable {
        readonly List<IDisposable> handles = new List<IDisposable>();
        public TreeLocks(string root) { try { Add(root); } catch { Dispose(); throw; } }
        void Add(string path) {
            var attrs = File.GetAttributes(path);
            if ((attrs & FileAttributes.ReparsePoint) != 0) throw new IOException("Unexpected link: " + path);
            handles.Add(Native.Open(path, 0x80000000, 1));
            foreach (var stream in Native.Streams(path).Where(s => s.Key != "::$DATA")) handles.Add(Native.DataStream(path + stream.Key, false));
            if ((attrs & FileAttributes.Directory) != 0) foreach (string child in Directory.GetFileSystemEntries(path)) Add(child);
        }
        public void Dispose() { foreach (var handle in handles) handle.Dispose(); handles.Clear(); }
    }
}

internal static class Native {
    internal const uint DELETE = 0x10000, READ_CONTROL = 0x20000;
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] static extern SafeFileHandle CreateFile(string p, uint access, uint share, IntPtr security, uint disposition, uint flags, IntPtr template);
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] static extern uint GetFileAttributes(string path);
    [DllImport("kernel32.dll", SetLastError=true)] static extern bool GetFileInformationByHandle(SafeFileHandle h, out Info info);
    [StructLayout(LayoutKind.Sequential)] struct Info { public uint attributes; public System.Runtime.InteropServices.ComTypes.FILETIME created, accessed, written; public uint volume, sizeHigh, sizeLow, links, indexHigh, indexLow; }
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] static extern IntPtr FindFirstStreamW(string path, int level, out StreamInfo data, uint flags);
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] static extern bool FindNextStreamW(IntPtr handle, out StreamInfo data);
    [DllImport("kernel32.dll")] static extern bool FindClose(IntPtr handle);
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)] struct StreamInfo { public long size; [MarshalAs(UnmanagedType.ByValTStr, SizeConst=296)] public string name; }
    [DllImport("kernel32.dll", SetLastError=true)] static extern bool DeviceIoControl(SafeFileHandle h, uint code, byte[] input, int inputLength, byte[] output, int outputLength, out int returned, IntPtr overlapped);
    delegate uint CopyProgress(long total, long transferred, long streamSize, long streamTransferred, uint streamNumber, uint reason, IntPtr source, IntPtr destination, IntPtr data);
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] static extern bool CopyFileEx(string source, string dest, CopyProgress progress, IntPtr data, ref int cancel, uint flags);
    static Exception Error(string path) { return new IOException(path + ": " + new Win32Exception(Marshal.GetLastWin32Error()).Message); }
    internal static uint Attributes(string path) { return GetFileAttributes(path); }
    internal static FileStream DataStream(string path, bool write) {
        var h = CreateFile(path, write ? 0x40000000u : 0x80000000u, 1, IntPtr.Zero, write ? 4u : 3u, 0, IntPtr.Zero);
        if (h.IsInvalid) { h.Dispose(); throw Error(path); }
        try { return new FileStream(h, write ? FileAccess.Write : FileAccess.Read); } catch { h.Dispose(); throw; }
    }
    internal static SafeFileHandle Open(string path, uint access, uint share) {
        var h = CreateFile(path, access, share, IntPtr.Zero, 3, 0x02200000, IntPtr.Zero);
        if (h.IsInvalid) { h.Dispose(); throw Error(path); } return h;
    }
    static Info Information(string path) {
        using (var h = Open(path, 0, 7)) { Info i; if (!GetFileInformationByHandle(h, out i)) throw Error(path); return i; }
    }
    internal static uint LinkCount(string path) { return Information(path).links; }
    internal static string Identity(string path) { var i = Information(path); return i.volume.ToString("X8") + i.indexHigh.ToString("X8") + i.indexLow.ToString("X8"); }
    internal static List<KeyValuePair<string,long>> Streams(string path) {
        var result = new List<KeyValuePair<string,long>>(); StreamInfo data;
        IntPtr handle = FindFirstStreamW(path, 0, out data, 0);
        if (handle == new IntPtr(-1)) {
            int error = Marshal.GetLastWin32Error(); if (error == 38) return result; throw Error(path);
        }
        try {
            do { result.Add(new KeyValuePair<string,long>(data.name, data.size)); } while (FindNextStreamW(handle, out data));
            if (Marshal.GetLastWin32Error() != 38) throw Error(path);
        } finally { FindClose(handle); }
        return result.OrderBy(s => s.Key, StringComparer.OrdinalIgnoreCase).ToList();
    }
    internal static void Copy(string source, string destination, Action check) {
        bool cancelled = false; int cancel = 0;
        CopyProgress callback = delegate(long a, long b, long c, long d, uint e, uint f, IntPtr g, IntPtr h, IntPtr i) {
            try { check(); return 0; } catch (OperationCanceledException) { cancelled = true; return 1; }
        };
        if (!CopyFileEx(source, destination, callback, IntPtr.Zero, ref cancel, 1)) {
            if (cancelled) throw new OperationCanceledException("Migration cancelled."); throw Error(source);
        }
        var attributes = File.GetAttributes(source);
        File.SetAttributes(destination, attributes & ~FileAttributes.ReadOnly);
        File.SetCreationTimeUtc(destination, File.GetCreationTimeUtc(source));
        File.SetLastWriteTimeUtc(destination, File.GetLastWriteTimeUtc(source));
        using (var h = Open(destination, 0x40000000, 7)) { if (!FlushFileBuffers(h)) throw Error(destination); }
        var security = File.GetAccessControl(source, System.Security.AccessControl.AccessControlSections.Access);
        security.SetAccessRuleProtection(true, true); File.SetAccessControl(destination, security);
        File.SetAttributes(destination, attributes);
    }
    [DllImport("kernel32.dll", SetLastError=true)] static extern bool FlushFileBuffers(SafeFileHandle handle);
    internal static void CreateJunction(string path, string target) {
        if (Attributes(path) != UInt32.MaxValue) throw new IOException("Junction path is occupied: " + path);
        Directory.CreateDirectory(path);
        try {
            byte[] substitute = Encoding.Unicode.GetBytes(@"\??\" + target), print = Encoding.Unicode.GetBytes(target);
            byte[] data = new byte[16 + substitute.Length + 2 + print.Length + 2];
            Action<int, ushort> word = (offset, value) => Array.Copy(BitConverter.GetBytes(value), 0, data, offset, 2);
            Array.Copy(BitConverter.GetBytes(0xA0000003u), data, 4); word(4, (ushort)(data.Length - 8));
            word(8, 0); word(10, (ushort)substitute.Length); word(12, (ushort)(substitute.Length + 2)); word(14, (ushort)print.Length);
            Array.Copy(substitute, 0, data, 16, substitute.Length); Array.Copy(print, 0, data, 18 + substitute.Length, print.Length);
            using (var h = Open(path, 0x40000000, 0)) { int n; if (!DeviceIoControl(h, 0x900A4, data, data.Length, null, 0, out n, IntPtr.Zero)) throw Error(path); }
        } catch { if ((Attributes(path) & (uint)FileAttributes.ReparsePoint) == 0 && Directory.GetFileSystemEntries(path).Length == 0) Directory.Delete(path); throw; }
    }
    internal static bool IsJunctionTo(string path, string target) {
        if (Attributes(path) == UInt32.MaxValue || (Attributes(path) & (uint)FileAttributes.ReparsePoint) == 0) return false;
        using (var h = Open(path, 0, 7)) {
            byte[] data = new byte[16384]; int n;
            if (!DeviceIoControl(h, 0x900A8, null, 0, data, data.Length, out n, IntPtr.Zero)) throw Error(path);
            if (BitConverter.ToUInt32(data, 0) != 0xA0000003u) return false;
            string actual = Encoding.Unicode.GetString(data, 16 + BitConverter.ToUInt16(data, 8), BitConverter.ToUInt16(data, 10));
            return String.Equals(actual, @"\??\" + target.TrimEnd('\\'), StringComparison.OrdinalIgnoreCase);
        }
    }
    internal static void RemoveJunction(string path, string target) {
        if (!IsJunctionTo(path, target)) throw new IOException("Unexpected junction target: " + path);
        // Nonrecursive directory deletion removes the junction itself, never its target.
        Directory.Delete(path);
    }
}
}
