"""Valida estructura y ejecuta tests; la tabla local opcional se informa aparte."""
import argparse,json,subprocess,sys
from pathlib import Path
def main():
    p=argparse.ArgumentParser();p.add_argument('--solo-estructura',action='store_true');p.add_argument('--pre-publicar',action='store_true');a=p.parse_args()
    root=Path(__file__).resolve().parent
    repo=root.parent
    for name in ['README.md','.gitignore','.github/workflows/python.yml','.github/workflows/matlab.yml','tools/verificar_documentacion.py']:
        if not (repo/name).is_file():raise FileNotFoundError(name)
    for name in ['f16py/dynamics.py','references/matlab_reference.mat','references/paridad.mat']:
        if not (root/name).is_file():raise FileNotFoundError(name)
    files=[f for f in repo.rglob('*') if f.is_file() and not any(x in f.relative_to(repo).parts for x in ['.git','__pycache__','.venv','venv','resultados','datos_locales'])]
    blocked=[f for f in files if f.suffix.lower() in ['.pdf','.xlsx','.fig','.asv','.mp4','.npz'] or f.stat().st_size>100*1024**2]
    if blocked:raise RuntimeError('Archivos fuera de publicación: '+str(blocked))
    if a.pre_publicar and not (repo/'LICENSE').is_file():raise RuntimeError('Falta elegir licencia y completar autoría/derechos antes de publicar.')
    subprocess.run([sys.executable,str(repo/'tools'/'verificar_documentacion.py')],check=True)
    print('ESTRUCTURA: PASS; licencia pendiente' if not (repo/'LICENSE').exists() else 'ESTRUCTURA: PASS')
    if not a.solo_estructura:
        result=subprocess.run([sys.executable,'-m','unittest','discover','-s','tests','-v'],cwd=root)
        if result.returncode:raise SystemExit(result.returncode)
if __name__=='__main__':main()
