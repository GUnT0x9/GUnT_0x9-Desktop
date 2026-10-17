"""Approved raster only: crop, remove detached specks, premultiplied resize, PNG/ICO."""
from pathlib import Path
import argparse, hashlib, json, struct
from PIL import Image, ImageDraw
import numpy as np
from scipy import ndimage

def resize(im,size):
    return im.convert('RGBa').resize(size,Image.Resampling.LANCZOS).convert('RGBA')
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1]);args=parser.parse_args()
    root=args.root;out=root/'assets/branding';source=out/'source/gunt-logo-original.png'
    original=Image.open(source).convert('RGBA');arr=np.array(original)
    if original.size!=(1254,1254):raise ValueError('Approved master dimensions changed; review crop coordinates first.')
    labels,_=ndimage.label(arr[:,:,3]>64);counts=np.bincount(labels.ravel());keep=counts>=500;keep[0]=False
    mask=ndimage.binary_dilation(keep[labels],iterations=2)
    cleaned=arr.copy();cleaned[:,:,3][~mask]=0
    clean=Image.fromarray(cleaned)
    mascot=clean.crop((228,145,1044,984))
    wordmark=clean.crop((160,981,1094,1111))
    full=clean.crop((156,145,1098,1200))
    for d in ['icons','wordmark','full','previews']:(out/d).mkdir(parents=True,exist_ok=True)
    mascot.save(out/'icons/gunt-mascot-master.png',optimize=True)
    wordmark.save(out/'wordmark/gunt-wordmark.png',optimize=True)
    full.save(out/'full/gunt-logo-full.png',optimize=True)
    dark=Image.new('RGBA',full.size,'#0E0E12');dark.alpha_composite(full);dark.convert('RGB').save(out/'full/gunt-logo-dark-surface.png',optimize=True)
    # Horizontal compact composition keeps supplied wordmark pixels, no substituted lettering.
    compact=Image.new('RGBA',(520,104));mini=resize(mascot,(93,96));compact.alpha_composite(mini,(2,4))
    wm=resize(wordmark,(400,56));compact.alpha_composite(wm,(112,24));compact.save(out/'wordmark/gunt-logo-compact.png',optimize=True)
    for width in [160,240]:
        resize(full,(width,round(full.height*width/full.width))).save(out/f'full/gunt-logo-full-{width}.png',optimize=True)
    sizes=[16,24,32,48,64,128,256];frames=[]
    for n in sizes:
        icon=Image.new('RGBA',(n,n));limit=round(n*.94);factor=min(limit/mascot.width,limit/mascot.height)
        body=resize(mascot,(max(1,round(mascot.width*factor)),max(1,round(mascot.height*factor))))
        icon.alpha_composite(body,((n-body.width)//2,(n-body.height)//2));path=out/f'icons/gunt-app-{n}.png';icon.save(path,optimize=True);frames.append(path.read_bytes())
    header=struct.pack('<HHH',0,1,len(sizes));offset=6+16*len(sizes);entries=[]
    for n,data in zip(sizes,frames):
        entries.append(struct.pack('<BBBBHHII',0 if n==256 else n,0 if n==256 else n,0,0,1,32,len(data),offset));offset+=len(data)
    (out/'icons/gunt-app.ico').write_bytes(header+b''.join(entries)+b''.join(frames))
    sheet=Image.new('RGB',(1120,710),'#0E0E12');draw=ImageDraw.Draw(sheet)
    for i,n in enumerate(sizes):
        x=12+i*155;im=Image.open(out/f'icons/gunt-app-{n}.png')
        for y,bg in [(36,'#0E0E12'),(200,'#F4F4F5')]:
            patch=Image.new('RGBA',(145,145),bg);factor=min(1,136/n);mini=resize(im,(round(n*factor),round(n*factor)));patch.alpha_composite(mini,((145-mini.width)//2,(145-mini.height)//2));sheet.paste(patch.convert('RGB'),(x,y))
        draw.text((x,12),str(n)+' px',fill='white')
        zoom=im.resize((128,128),Image.Resampling.NEAREST);sheet.paste(zoom,(x,365),zoom)
    preview=resize(full,(178,200));sheet.paste(preview,(20,502),preview)
    cp=resize(compact,(520,104));sheet.paste(cp,(250,540),cp)
    sheet.save(out/'previews/icon-contact-sheet.png')
    files=[]
    for p in sorted(out.rglob('*')):
        if p.is_file() and p.name!='manifest.json':files.append({'file':str(p.relative_to(out)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size})
    manifest={'brand':'GUnT_0x9','subtitle':'Desktop','masterSize':list(original.size),'sourceSHA256':hashlib.sha256(source.read_bytes()).hexdigest(),'icoSizes':sizes,'processing':'Original RGB preserved; detached alpha components under 500px removed outside a 2px guard; fixed crops; premultiplied LANCZOS resizing. No generative redraw.','crops':{'mascot':[228,145,1044,984],'wordmark':[160,981,1094,1111],'full':[156,145,1098,1200]},'removedAlphaPixels':int(np.count_nonzero((arr[:,:,3]>0)&(~mask))),'files':files}
    (out/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps({k:manifest[k] for k in ['masterSize','icoSizes','removedAlphaPixels']},ensure_ascii=False))
if __name__=='__main__':main()
