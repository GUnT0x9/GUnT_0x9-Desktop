#!/usr/bin/env python3
"""README 연결 문서와 승인 이미지의 구조를 검사한다. 개인정보 시각 검토는 별도다."""
import binascii
import hashlib
import json
from pathlib import Path
import re
import struct
import sys
from urllib.parse import unquote, urlsplit
import zlib

ROOT = Path(__file__).resolve().parents[1]
errors = []


def fail(message):
    errors.append(message)


def prose(path):
    text = path.read_text(encoding="utf-8-sig")
    return re.sub(r"(?ms)^\s*(```|~~~).*?^\s*\1[^\n]*$", "", text)


def anchors(text):
    result, counts = set(), {}
    for line in text.splitlines():
        match = re.match(r"^#{1,6}\s+(.+?)\s*#*$", line)
        if not match:
            continue
        title = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", match[1])
        slug = re.sub(r"[^\w\- ]", "", title.lower()).replace(" ", "-")
        index = counts.get(slug, 0)
        counts[slug] = index + 1
        result.add(slug + ("-" + str(index) if index else ""))
    return result


def check_links():
    queue = [ROOT / "README.md", ROOT / "docs/readme-maintenance.md"]
    seen, links = set(), 0
    while queue:
        path = queue.pop()
        if path in seen:
            continue
        seen.add(path)
        text = prose(path)
        references = re.findall(r"!?\[[^\]]*\]\(([^)]+)\)", text)
        references += re.findall(r'<img\b[^>]*\bsrc=[\'"]([^\'"]+)', text)
        for raw in references:
            value = raw.strip().split(' "', 1)[0].strip("<>")
            url = urlsplit(value)
            if url.scheme or url.netloc:
                continue  # 외부 사이트의 접속 가능 여부는 이 로컬 검사 범위가 아니다.
            links += 1
            destination = (path.parent / unquote(url.path)).resolve() if url.path else path
            if not destination.is_relative_to(ROOT):
                fail(f"저장소 밖 링크: {path.relative_to(ROOT)} -> {value}")
                continue
            if not destination.exists():
                fail(f"없는 링크: {path.relative_to(ROOT)} -> {value}")
                continue
            if destination.suffix.lower() == ".md":
                if url.fragment and unquote(url.fragment) not in anchors(prose(destination)):
                    fail(f"없는 앵커: {path.relative_to(ROOT)} -> {value}")
                queue.append(destination)
    return len(seen), links


def check_png(path):
    data = path.read_bytes()
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("PNG 서명 오류")
    offset, tags, pixels, header = 8, [], bytearray(), None
    while offset < len(data):
        size = struct.unpack_from(">I", data, offset)[0]
        tag = data[offset + 4:offset + 8]
        payload = data[offset + 8:offset + 8 + size]
        if len(payload) != size:
            raise ValueError("잘린 PNG 청크")
        crc = struct.unpack_from(">I", data, offset + 8 + size)[0]
        if binascii.crc32(tag + payload) & 0xffffffff != crc:
            raise ValueError("PNG CRC 오류")
        if tag not in {b"IHDR", b"IDAT", b"IEND", b"sRGB", b"gAMA", b"pHYs", b"PLTE", b"tRNS"}:
            raise ValueError("공개 허용 목록 밖 메타데이터/청크: " + tag.decode("ascii"))
        tags.append(tag)
        if tag == b"IHDR":
            header = struct.unpack(">IIBBBBB", payload)
        if tag == b"IDAT":
            pixels.extend(payload)
        offset += size + 12
        if tag == b"IEND":
            break
    if offset != len(data) or not header or tags[0] != b"IHDR" or tags[-1] != b"IEND":
        raise ValueError("PNG 구조 또는 후행 데이터 오류")
    width, height, depth, color, compression, filtering, interlace = header
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[color]
    decoded = zlib.decompress(pixels)
    if interlace or compression or filtering:
        raise ValueError("검증 도구가 지원하지 않는 PNG 방식")
    stride = (width * channels * depth + 7) // 8
    if len(decoded) != (stride + 1) * height or any(decoded[y * (stride + 1)] > 4 for y in range(height)):
        raise ValueError("PNG 이미지 데이터 오류")
    return width, height, hashlib.sha256(data).hexdigest()


def check_images():
    manifest = json.loads((ROOT / "docs/images/releases/manifest.json").read_text(encoding="utf-8"))
    files, hashes = set(), set()
    for entry in manifest["images"]:
        name = entry["path"]
        path = (ROOT / name).resolve()
        if not path.is_relative_to(ROOT / "docs/images") or path.suffix != ".png":
            fail("공개 이미지 경로 오류: " + name)
            continue
        if path in files:
            fail("중복 이미지 등록: " + name)
        files.add(path)
        try:
            width, height, sha = check_png(path)
            if entry.get("reviewStatus") != "reviewed" or not entry.get("privacyReview") or not entry.get("rights"):
                fail("검토/권리 기록 누락: " + name)
            if sha != entry["sha256"] or [width, height] != entry["dimensions"]:
                fail("검토한 이미지의 해시/크기가 바뀜: " + name)
            if sha in hashes:
                fail("동일 이미지 중복 저장: " + name)
            hashes.add(sha)
            if path.stat().st_size > 1024 * 1024:
                fail("1MiB 초과 이미지, 별도 크기 검토 필요: " + name)
        except (OSError, ValueError, KeyError, struct.error, zlib.error) as error:
            fail(name + ": " + str(error))
    for path in (ROOT / "docs/images/releases").rglob("*.png"):
        if path.resolve() not in files:
            fail("공개 manifest 미등록 이미지: " + str(path.relative_to(ROOT)))
    for path in [ROOT / "README.md", ROOT / "docs/visual-history.md"]:
        for name in re.findall(r"!\[[^\]]*\]\(([^)]+\.png)\)", prose(path)):
            if (path.parent / name).resolve() not in files:
                fail("쇼케이스 이미지 검토 기록 누락: " + name)
    return len(files)


if __name__ == "__main__":
    documents, links = check_links()
    images = check_images()
    if errors:
        print("문서 검사 실패:\n" + "\n".join(errors))
        sys.exit(1)
    print(f"문서 {documents}개·상대 링크/앵커 {links}개·공개 PNG {images}개 검사 통과")
    print("외부 URL 접속·픽셀 속 개인정보·저작권의 자동 승인을 의미하지 않습니다.")
