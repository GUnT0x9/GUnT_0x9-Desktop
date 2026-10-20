"""Linux에서도 실행 가능한 소스 보존·XAML 구조 검사. 실제 WPF 렌더링 검사는 아니다."""
from pathlib import Path
import re
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
VIEWS = ROOT / 'control-center/src/GUNT.ControlCenter/Views'
original = subprocess.check_output(['git', 'show', '3ae33e2:control-center/src/GUNT.ControlCenter/Views/MainWindow.cs'], cwd=ROOT, text=True)
current = (VIEWS / 'MainWindow.cs').read_text()
def pages(source):
    registry = source[source.index('readonly string[][] pages='):source.index('public MainWindow(')]
    return re.findall(r'new\[\]\{"([a-z-]+)",', registry)
assert pages(current)[:len(pages(original))] == pages(original), '기존 페이지 순서·목적지가 사라졌습니다.'
assert set(pages(current)[len(pages(original)):]) == {'workspace-overview', 'launchpad-settings', 'shortcuts'}, '새 영역 목적지를 확인하세요.'
count = 0
for file in VIEWS.glob('*.cs'):
    for literal in re.findall(r'XamlReader.Parse\(@"((?:[^"]|"")*)"\)', file.read_text()):
        ET.fromstring(literal.replace('""', '"'))
        count += 1
assert count > 0
for file in (ROOT / 'control-center/src').rglob('*.cs'):
    assert '\ufffd' not in file.read_text(), str(file)
print(f'기존 목적지 {len(pages(original))}개 보존·새 목적지 {len(pages(current))-len(pages(original))}개, XAML XML {count}개 구문, UTF-8 대체문자 검사 통과')
print('이 검사는 WPF 템플릿 로딩·화면 배치·DPI·키보드 동작 검증을 대신하지 않습니다.')
