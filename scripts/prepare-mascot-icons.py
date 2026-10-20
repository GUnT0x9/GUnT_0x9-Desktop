#!/usr/bin/env python3
"""Export individually reviewed pose masters; no image synthesis or duplicated poses.
Input manifest is local: {pose: /absolute/generated.png}; use 'approved' for coding.
Requires Pillow. Export preserves actual alpha and normalizes visible padding.
"""
import argparse, hashlib, json
from pathlib import Path
from PIL import Image, ImageDraw

def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--inputs',required=True,type=Path);parser.add_argument('--root',type=Path,default=Path('.'));args=parser.parse_args()
    root=args.root.resolve();target=root/'assets/branding/mascot';target.mkdir(parents=True,exist_ok=True)
    inputs=json.loads(args.inputs.read_text());manifest={'schemaVersion':1,'source':'승인 원본 기반 개별 imagegen 변형. coding은 기존 승인 원본. UI 스크린샷과 별개의 브랜드 그림 자산.', 'processing':'실제 알파의 표시 영역 crop, 정사각 캔버스의 84% 안에 비율 유지, 크기별 Lanczos. PNG 메타데이터 제거.','poses':[]}
    preview=Image.new('RGB',(1000,600),(14,14,18));draw=ImageDraw.Draw(preview)
    for i,(pose,source) in enumerate(inputs.items()):
        path=root/'assets/branding/icons/gunt-mascot-master.png' if source=='approved' else Path(source)
        if not path.is_file():raise SystemExit(f'Missing pose source: {pose}')
        image=Image.open(path).convert('RGBA');alpha=image.getchannel('A');bbox=alpha.getbbox()
        if not bbox or alpha.getextrema()[0]!=0:raise SystemExit(f'{pose}: genuine transparency required')
        crop=image.crop(bbox);folder=target/pose;folder.mkdir(parents=True,exist_ok=True)
        master=Image.new('RGBA',(1024,1024));crop.thumbnail((860,860),Image.Resampling.LANCZOS);master.alpha_composite(crop,((1024-crop.width)//2,(1024-crop.height)//2));master_path=folder/'master.png';master.save(master_path,optimize=True)
        outputs=[]
        for size in (32,48,64,128,256):
            export=folder/f'{size}.png';master.resize((size,size),Image.Resampling.LANCZOS).save(export,optimize=True);outputs.append({'path':str(export.relative_to(root)),'size':size,'sha256':digest(export)})
        manifest['poses'].append({'id':pose,'origin':'approved-original' if source=='approved' else 'imagegen-reference-variation','inputSha256':digest(path),'masterSha256':digest(master_path),'exports':outputs})
        thumb=master.resize((180,180),Image.Resampling.LANCZOS);x=(i%5)*200+10;y=(i//5)*300+12;preview.paste(thumb,(x,y),thumb);draw.text((x+15,y+188),pose,fill=(244,244,245));small=master.resize((64,64),Image.Resampling.LANCZOS);preview.paste(small,(x+58,y+215),small)
    if len({p['masterSha256'] for p in manifest['poses']})!=len(inputs):raise SystemExit('Identical pose files rejected')
    preview.save(target/'contact-sheet.png',optimize=True);(target/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    print(f'{len(inputs)} distinct pose masters exported; visual review still required')
if __name__=='__main__':main()
