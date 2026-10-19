"""실제 검색 메서드를 추출해 스냅샷 검색 회귀를 실행한다. WPF 실행 검사는 아니다."""
from pathlib import Path
import argparse
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--dotnet', required=True, type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
source = (root / 'control-center/src/GUNT.ControlCenter/Services/CommandRegistry.cs').read_text()
models = (root / 'control-center/src/GUNT.ControlCenter/Models/DeveloperModels.cs').read_text()
def extract(source, start):
    index = source.index(start)
    brace = source.index('{', index)
    depth = 0
    for end in range(brace, len(source)):
        if source[end] == '{': depth += 1
        if source[end] == '}':
            depth -= 1
            if depth == 0: return source[index:end + 1]
    raise ValueError(start)
methods = extract(source, 'public static int MatchCommand(') + '\n' + extract(source, 'public CommandEntry[] SearchCommands(string query,CommandEntry[] list,CommandStore config)')
# Use the real field definitions and ToString, excluding UI-only computed metadata.
command = extract(models, 'public sealed class CommandEntry ')
store = extract(models, 'public sealed class CommandStore ')
program = '''using System;using System.Linq;using System.Collections.Generic;using System.Text.RegularExpressions;
namespace Gunt.ControlCenter.Models { COMMAND STORE }
namespace Checks { using Gunt.ControlCenter.Models;class Search { METHODS }
class Program {static int tests;static void Assert(bool ok,string name){if(!ok)throw new Exception(name);tests++;}
static void Main(){var search=new Search();var config=new CommandStore();var commands=new[]{
 new CommandEntry{Id="codex",Name="WSL + Codex · 현재 프로젝트",Aliases="cx codex 코덱스"},
 new CommandEntry{Id="opencode",Name="WSL + OpenCode",Aliases="oc opencode"},
 new CommandEntry{Id="developer",Name="개발 세팅",Aliases="dev 개발"},
 new CommandEntry{Id="project:one:codex",Name="한글 프로젝트 · codex",Aliases="한글 프로젝트 codex"}};
Assert(search.SearchCommands("cx",commands,config).Single().Id=="codex","기본 cx 별칭");
Assert(search.SearchCommands(" OC ",commands,config).Single().Id=="opencode","기본 별칭 대소문자와 공백");
Assert(search.SearchCommands("dev",commands,config).Single().Id=="developer","개발 별칭");
config.Aliases["작업"]="project:one:codex";
Assert(search.SearchCommands("작업",commands,config).Single().Id=="project:one:codex","사용자 별칭");
Assert(search.SearchCommands("cdx",commands,config).Any(x=>x.Id=="codex"),"fuzzy Codex");
Assert(search.SearchCommands("한글",commands,config).Single().Id=="project:one:codex","한국어 검색");
Assert(search.SearchCommands("없는검색어",commands,config).Length==0,"빈 결과");
commands[1].Favorite=true;
Assert(search.SearchCommands("",commands,config)[0].Id=="opencode","즐겨찾기 우선");
commands[1].Favorite=false;config.Recent.Add("developer");
Assert(search.SearchCommands("",commands,config)[0].Id=="developer","최근 사용 우선");
var many=Enumerable.Range(0,1000).Select(i=>new CommandEntry{Id=i.ToString(),Name="프로젝트 "+i,Aliases="project"}).ToArray();
Assert(search.SearchCommands("project",many,config).Length==60,"결과 상한");
Console.WriteLine("검색 회귀 "+tests+"개 통과 (실제 스냅샷 검색 메서드)");}}}
'''.replace('COMMAND', command).replace('STORE', store).replace('METHODS', methods)
with tempfile.TemporaryDirectory(prefix='gunt-v30-search-') as folder:
    path = Path(folder)
    (path / 'Program.cs').write_text(program)
    sdks = subprocess.check_output([str(args.dotnet), '--list-sdks'], text=True).splitlines()
    version, location = sdks[-1].split(' ', 1)
    sdk = Path(location.strip('[]')) / version
    refs = sorted((sdk.parents[1] / 'packs/Microsoft.NETCore.App.Ref').glob('*/ref/net8.0'))[-1]
    command = [str(args.dotnet), str(sdk / 'Roslyn/bincore/csc.dll'), '/nologo', '/noconfig', '/nostdlib+', '/target:exe', '/out:' + str(path / 'Search.dll')]
    command += ['/reference:' + str(file) for file in refs.glob('*.dll')]
    subprocess.run(command + [str(path / 'Program.cs')], check=True)
    (path / 'Search.runtimeconfig.json').write_text('{"runtimeOptions":{"tfm":"net8.0","framework":{"name":"Microsoft.NETCore.App","version":"8.0.0"}}}')
    subprocess.run([str(args.dotnet), str(path / 'Search.dll')], check=True)
