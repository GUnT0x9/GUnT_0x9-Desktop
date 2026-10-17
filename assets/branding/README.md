# GUnT_0x9 Desktop 공식 브랜딩 자산

사용자가 승인한 RGBA 원본은 `source/gunt-logo-original.png`이며 변경 없이 보존합니다. 마스코트 전용 아이콘, 가로형 로고, 전체 로고는 이 원본에서 crop·alpha 잡티 정리·크기 변환으로 생성했습니다. AI 재생성이나 벡터 추적은 사용하지 않았습니다.

- `icons/`: 마스코트, 16/24/32/48/64/128/256 PNG, 7프레임 ICO.
- `wordmark/`: 승인 워드마크, 마스코트+워드마크 가로형 로고.
- `full/`: 투명 전체 로고와 160/240px 변형, 어두운 표면 제시용 변형.
- `previews/`: 크기별 어두운/밝은 표면 검수표.
- `manifest.json`: 원본·자산 해시, crop 좌표, 처리 내역.

재생성: Python + Pillow + NumPy + SciPy에서 `python scripts/prepare-branding.py --root .`.

[통합·빌드·검증·복구 문서](../../docs/branding-integration.md).
