using System;
using System.Diagnostics;
using System.Globalization;
using System.IO;

namespace Gunt.ControlCenter.Infrastructure
{
    // Opt-in local measurements. Never record searches, paths, project names or output.
    internal static class UiPerformance
    {
        internal static readonly bool Enabled = Environment.GetEnvironmentVariable("GUNT_UI_METRICS") == "1";
        static readonly object Gate = new object();

        internal static void Record(string root, string metric, double milliseconds)
        {
            if (!Enabled) return;
            try
            {
                string line = "{\"metric\":\"" + metric + "\",\"ms\":" + milliseconds.ToString("F3", CultureInfo.InvariantCulture) + "}";
                lock (Gate)
                {
                    string folder = Path.Combine(root, "logs");
                    Directory.CreateDirectory(folder);
                    File.AppendAllText(Path.Combine(folder, "v30-ui-timings.jsonl"), line + Environment.NewLine);
                }
            }
            catch (IOException) { }
            catch (UnauthorizedAccessException) { }
        }
    }
}
