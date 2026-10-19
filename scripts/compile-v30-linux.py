"""임시 산출물만 생성하는 .NET Framework 4.8 교차 컴파일 검사.
사용법: python3 scripts/compile-v30-linux.py --dotnet /path/dotnet --references /path/.NETFramework/v4.8
Windows 배포 빌드 또는 실행 검증을 대신하지 않는다. 외부 패키지를 자동 설치하지 않는다.
"""
from pathlib import Path
import argparse
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--dotnet', required=True, type=Path)
parser.add_argument('--references', required=True, type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
sdks = subprocess.check_output([str(args.dotnet), '--list-sdks'], text=True).splitlines()
version, location = sdks[-1].split(' ', 1)
csc = Path(location.strip('[]')) / version / 'Roslyn/bincore/csc.dll'
base = ['mscorlib', 'System', 'System.Core', 'System.Drawing', 'System.Windows.Forms', 'System.Web.Extensions', 'Accessibility']
with tempfile.TemporaryDirectory(prefix='gunt-v30-compile-') as temp:
    output = Path(temp)
    def compile(name, sources, extra=(), target='library'):
        command = [str(args.dotnet), str(csc), '/nologo', '/noconfig', '/nostdlib+', '/langversion:5', '/optimize+', '/target:' + target, '/out:' + str(output / name)]
        command += ['/reference:' + str(args.references / (item + '.dll')) for item in base]
        command += ['/reference:' + str(item) for item in extra]
        subprocess.run(command + list(map(str, sources)), check=True, cwd=root)
        print(name + ': 컴파일 통과', flush=True)
    compile('Gunt.Configuration.dll', [root / 'src/Configuration.cs'])
    compile('Gunt.Sensors.dll', [root / 'src' / name for name in ['Sensors.cs', 'AdditionalTelemetry.cs', 'HwinfoTelemetry.cs']])
    shared = [output / 'Gunt.Configuration.dll', output / 'Gunt.Sensors.dll']
    compile('GUNT.ControlCenter.exe', list((root / 'control-center/src').rglob('*.cs')), shared + [args.references / (name + '.dll') for name in ['System.Xaml', 'PresentationFramework', 'PresentationCore', 'WindowsBase']], 'winexe')
    compile('GUNT-Bar.exe', [root / 'src/GuntBar.cs', root / 'src/GuntDeveloperIntegration.cs'], shared, 'winexe')
