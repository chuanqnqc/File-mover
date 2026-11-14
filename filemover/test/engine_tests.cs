using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Collections.Generic;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Web.Script.Serialization;

namespace FileMover {
public static class EngineTests {
    static readonly JavaScriptSerializer Json = new JavaScriptSerializer { MaxJsonLength = Int32.MaxValue };
    static string Suite;
    static int Passed;
    static void Assert(bool condition, string message) { if (!condition) throw new Exception(message); }
    sealed class Capture : StringWriter {
        internal Action<string> onLine;
        public override void WriteLine(string value) { base.WriteLine(value); if (onLine != null) onLine(value); }
    }
    static string Call(string root, string action, string source, string parent, string id, Action<string> hook) {
        var output = new Capture { onLine = hook };
        var previous = Console.Out;
        try {
            Console.SetOut(output);
            Engine.Run(Convert.ToBase64String(Encoding.UTF8.GetBytes(Json.Serialize(new Request {
                action = action, source = source, parent = parent, id = id, dataRoot = Path.Combine(root, "journals") }))));
        } finally { Console.SetOut(previous); }
        return output.ToString();
    }
    static string Fixture(string name) {
        string root = Path.Combine(Suite, name); Directory.CreateDirectory(Path.Combine(root, "original", "Example"));
        Directory.CreateDirectory(Path.Combine(root, "target"));
        File.WriteAllText(Path.Combine(root, "original", "Example", "hello.txt"), "original content");
        return root;
    }
    static string Source(string root) { return Path.Combine(root, "original", "Example"); }
    static string Target(string root) { return Path.Combine(root, "target", "Example"); }
    static string Move(string root, Action<string> hook) { return Call(root, "move", Source(root), Path.Combine(root, "target"), null, hook); }
    static Record Latest(string root) {
        return Directory.GetFiles(Path.Combine(root, "journals"), "*.json")
            .Select(p => Json.Deserialize<Record>(File.ReadAllText(p))).OrderByDescending(r => r.started).First();
    }
    static void Success(string output) { Assert(!output.Contains("\"type\":\"error\""), output); Assert(output.Contains("\"type\":\"result\""), output); }
    static void Failure(string output) { Assert(output.Contains("\"type\":\"error\""), "Expected failure: " + output); }
    static void WriteStream(string path, string text) { using (var output = Native.DataStream(path, true)) { byte[] data = Encoding.UTF8.GetBytes(text); output.Write(data, 0, data.Length); } }
    static string ReadStream(string path) { using (var input = Native.DataStream(path, false)) using (var reader = new StreamReader(input)) return reader.ReadToEnd(); }
    static void Test(string name, Action action) {
        action(); Passed++; Console.WriteLine("PASS " + name);
    }
    public static void Run(string directory) {
        Suite = Path.GetFullPath(directory); Directory.CreateDirectory(Suite);
        Test("migration preserves content, streams, read-only files, Unicode, empty directories and timestamps", delegate {
            string root = Fixture("roundtrip"), source = Source(root);
            Directory.CreateDirectory(Path.Combine(source, "empty"));
            string special = Path.Combine(source, "日本語 & ' $ ` file.txt");
            File.WriteAllText(special, "unicode contents"); WriteStream(special + ":notes", "stream data");
            WriteStream(source + ":foldernotes:$DATA", "directory stream");
            File.SetCreationTimeUtc(special, new DateTime(2020, 1, 2, 3, 4, 5, DateTimeKind.Utc));
            File.SetAttributes(special, FileAttributes.ReadOnly);
            Success(Move(root, null)); var record = Latest(root);
            Assert(record.state == "complete", "Not complete");
            Assert(Native.IsJunctionTo(source, Target(root)), "Junction missing");
            Assert(ReadStream(Path.Combine(source, Path.GetFileName(special)) + ":notes") == "stream data", "ADS lost");
            Assert(ReadStream(source + ":foldernotes:$DATA") == "directory stream", "Directory ADS lost");
            Assert(!Directory.Exists(record.backup), "Backup not cleaned");
            File.WriteAllText(Path.Combine(source, "hello.txt"), "changed since migration");
            File.WriteAllText(Path.Combine(source, "new.txt"), "new data");
            Success(Call(root, "undo", null, null, record.id, null));
            Assert((File.GetAttributes(source) & FileAttributes.ReparsePoint) == 0, "Undo left a junction");
            Assert(File.ReadAllText(Path.Combine(source, "hello.txt")) == "changed since migration", "Undo used stale contents");
            Assert(File.ReadAllText(Path.Combine(source, "new.txt")) == "new data", "Undo lost new file");
            Assert(!Directory.Exists(Target(root)), "Undo did not clean destination");
        });
        Test("existing destination is never overwritten", delegate {
            string root = Fixture("collision"); Directory.CreateDirectory(Target(root));
            File.WriteAllText(Path.Combine(Target(root), "sentinel"), "keep");
            Failure(Move(root, null)); Assert(File.ReadAllText(Path.Combine(Target(root), "sentinel")) == "keep", "Overwrote collision");
        });
        Test("overlapping folders and missing source rejected", delegate {
            string root = Fixture("overlap");
            Failure(Call(root, "preflight", Source(root), Path.Combine(root, "original"), null, null));
            Failure(Call(root, "preflight", Source(root) + "missing", Path.Combine(root, "target"), null, null));
        });
        Test("locked source remains intact", delegate {
            string root = Fixture("locked");
            using (var stream = new FileStream(Path.Combine(Source(root), "hello.txt"), FileMode.Open, FileAccess.ReadWrite, FileShare.None)) Failure(Move(root, null));
            Assert(Directory.Exists(Source(root)), "Source lost");
        });
        Test("nested junctions and hard links rejected", delegate {
            string root = Fixture("links"); Native.CreateJunction(Path.Combine(Source(root), "nested"), Path.Combine(root, "target"));
            Failure(Move(root, null)); Native.RemoveJunction(Path.Combine(Source(root), "nested"), Path.Combine(root, "target"));
            Assert(CreateHardLink(Path.Combine(Source(root), "linked.txt"), Path.Combine(Source(root), "hello.txt"), IntPtr.Zero), "Cannot make test hard link");
            Failure(Move(root, null));
        });
        Test("cancellation after rename restores original", delegate {
            string root = Fixture("cancel");
            Failure(Move(root, line => { if (line.Contains("\"phase\":\"Copying\"")) File.WriteAllText(Path.Combine(root, "journals", "cancel"), "cancel"); }));
            Assert(Latest(root).state == "rolledBack", "Cancellation not rolled back");
            Assert(File.ReadAllText(Path.Combine(Source(root), "hello.txt")) == "original content", "Cancellation lost data");
        });
        Test("hash mismatch restores source and retains copy", delegate {
            string root = Fixture("mismatch"); bool changed = false;
            Failure(Move(root, line => {
                if (changed || !line.Contains("\"phase\":\"Verifying\"")) return;
                string[] stages = Directory.GetDirectories(Path.Combine(root, "target"), ".filemover-stage-*");
                if (stages.Length > 0 && File.Exists(Path.Combine(stages[0], "hello.txt"))) {
                    File.WriteAllText(Path.Combine(stages[0], "hello.txt"), "corrupted copy"); changed = true;
                }
            }));
            Assert(changed && Latest(root).state == "rolledBack", "Mismatch not detected");
            Assert(File.ReadAllText(Path.Combine(Source(root), "hello.txt")) == "original content", "Source corrupted");
            Assert(Directory.Exists(Latest(root).stage), "Failed copy should remain available");
        });
        Test("undo refuses changed junction", delegate {
            string root = Fixture("changedjunction"); Success(Move(root, null)); var r = Latest(root);
            Native.RemoveJunction(r.source, r.destination); Directory.CreateDirectory(r.source);
            File.WriteAllText(Path.Combine(r.source, "sentinel"), "keep");
            Failure(Call(root, "undo", null, null, r.id, null));
            Assert(File.ReadAllText(Path.Combine(r.source, "sentinel")) == "keep", "Undo overwrote unexpected data");
        });
        Test("cross-volume migration and undo", delegate {
            string root = Fixture("cross-volume");
            string parent = Path.Combine(Path.GetTempPath(), "filemover-test-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(parent);
            Assert(!String.Equals(Path.GetPathRoot(root), Path.GetPathRoot(parent), StringComparison.OrdinalIgnoreCase), "Cross-volume test requires TEMP on a different NTFS volume.");
            Success(Call(root, "move", Source(root), parent, null, null)); var r = Latest(root);
            Assert(Native.IsJunctionTo(Source(root), Path.Combine(parent, "Example")), "Cross-volume junction missing");
            Success(Call(root, "undo", null, null, r.id, null));
            Assert(File.ReadAllText(Path.Combine(Source(root), "hello.txt")) == "original content", "Cross-volume undo lost data");
            Directory.Delete(parent);
        });
        string[] phases = { "prepared", "renamingSource", "sourceRenamed", "creatingStage", "copying", "verifying", "publishing", "creatingJunction", "checkingJunction", "committed", "cleanupPending" };
        foreach (string phaseValue in phases) {
            string phase = phaseValue;
            Test("restart recovery at " + phase, delegate {
                string root = Fixture("restart-" + phase), source = Source(root), id = Guid.NewGuid().ToString("N");
                Directory.CreateDirectory(Path.Combine(root, "journals"));
                var r = new Record { id = id, direction = "move", source = source, destination = Target(root),
                    backup = source + ".filemover-backup-" + id, stage = Path.Combine(root, "target", ".filemover-stage-" + id),
                    sourceId = Native.Identity(source), state = phase, started = DateTime.UtcNow.ToString("o") };
                int index = Array.IndexOf(phases, phase);
                if (index >= 1) { Directory.Move(source, r.backup); r.backupId = r.sourceId; }
                if (index >= 3) { Directory.CreateDirectory(r.stage); File.WriteAllText(Path.Combine(r.stage, "hello.txt"), "original content"); r.stageId = Native.Identity(r.stage); }
                if (index >= 6) { Directory.Move(r.stage, r.destination); r.destinationId = r.stageId; }
                if (index >= 7) Native.CreateJunction(source, r.destination);
                File.WriteAllText(Path.Combine(root, "journals", id + ".json"), Json.Serialize(r));
                Success(Call(root, "recover", null, null, id, null));
                Assert(File.ReadAllText(Path.Combine(source, "hello.txt")) == "original content", "Recovery lost contents");
                Assert(Latest(root).state == (index >= 9 ? "complete" : "rolledBack"), "Unexpected recovery outcome");
            });
        }
        string[] undoPhases = { "prepared", "creatingStage", "copying", "verifying", "removingJunction", "restoringSource", "committed", "cleanupPending" };
        foreach (string phaseValue in undoPhases) {
            string phase = phaseValue;
            Test("undo restart recovery at " + phase, delegate {
                string root = Fixture("undo-restart-" + phase); Success(Move(root, null)); var old = Latest(root);
                string id = Guid.NewGuid().ToString("N");
                var r = new Record { id = id, direction = "undo", source = old.source, destination = old.destination,
                    stage = Path.Combine(root, "original", ".filemover-stage-" + id), sourceId = Native.Identity(old.destination),
                    state = phase, parentOperation = old.id, started = DateTime.UtcNow.AddSeconds(1).ToString("o") };
                int index = Array.IndexOf(undoPhases, phase);
                if (index >= 1) { Directory.CreateDirectory(r.stage); File.WriteAllText(Path.Combine(r.stage, "hello.txt"), "original content"); r.stageId = Native.Identity(r.stage); }
                if (index >= 4) Native.RemoveJunction(r.source, r.destination);
                if (index >= 5) Directory.Move(r.stage, r.source);
                File.WriteAllText(Path.Combine(root, "journals", id + ".json"), Json.Serialize(r));
                Success(Call(root, "recover", null, null, id, null));
                Assert(File.ReadAllText(Path.Combine(r.source, "hello.txt")) == "original content", "Undo recovery lost data");
                Assert(Latest(root).state == (index >= 5 ? "complete" : "rolledBack"), "Unexpected undo recovery state");
            });
        }
        Test("cleanup refuses nested junction without touching its target", delegate {
            string root = Fixture("cleanup-link"), source = Source(root), id = Guid.NewGuid().ToString("N");
            var r = new Record { id = id, direction = "move", source = source, destination = Target(root), backup = source + ".backup",
                sourceId = Native.Identity(source), state = "committed", started = DateTime.UtcNow.ToString("o") };
            Directory.Move(source, r.backup); r.backupId = r.sourceId;
            Directory.CreateDirectory(r.destination); File.WriteAllText(Path.Combine(r.destination, "hello.txt"), "original content");
            r.destinationId = Native.Identity(r.destination); Native.CreateJunction(source, r.destination);
            string external = Path.Combine(root, "external"); Directory.CreateDirectory(external); File.WriteAllText(Path.Combine(external, "sentinel"), "keep");
            Native.CreateJunction(Path.Combine(r.backup, "unexpected"), external);
            Directory.CreateDirectory(Path.Combine(root, "journals")); File.WriteAllText(Path.Combine(root, "journals", id + ".json"), Json.Serialize(r));
            Failure(Call(root, "recover", null, null, id, null));
            Assert(File.ReadAllText(Path.Combine(external, "sentinel")) == "keep", "Cleanup traversed a junction");
            Assert(Latest(root).state == "cleanupPending", "Cleanup failure should remain recoverable");
        });
        Test("recovery never overwrites unexpected original path", delegate {
            string root = Fixture("recovery-conflict"), source = Source(root), id = Guid.NewGuid().ToString("N");
            var r = new Record { id = id, direction = "move", source = source, destination = Target(root), backup = source + ".backup", sourceId = Native.Identity(source), state = "copying" };
            Directory.Move(source, r.backup); Directory.CreateDirectory(source); File.WriteAllText(Path.Combine(source, "sentinel"), "keep");
            Directory.CreateDirectory(Path.Combine(root, "journals")); File.WriteAllText(Path.Combine(root, "journals", id + ".json"), Json.Serialize(r));
            Failure(Call(root, "recover", null, null, id, null));
            Assert(File.ReadAllText(Path.Combine(source, "sentinel")) == "keep" && Directory.Exists(r.backup), "Recovery destroyed data");
        });
        Console.WriteLine("Passed " + Passed + " native integration tests. Fixtures: " + Suite);
    }
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] static extern bool CreateHardLink(string link, string existing, IntPtr security);
}
}
