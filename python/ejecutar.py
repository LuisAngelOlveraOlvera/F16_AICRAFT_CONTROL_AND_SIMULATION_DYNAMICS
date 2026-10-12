"""python ejecutar.py --escenario waypoints; --reproducir ruta/registro.npz"""
import argparse
from datetime import datetime
from pathlib import Path
import json
from f16py.simulation import simulate,SCENARIOS
from f16py.io import save_record,load_record,write_json
from f16py.visualization import plots,animate
from f16py.control import compare_lewis

def main():
    ap=argparse.ArgumentParser(description='Simulador F-16 academico Python')
    ap.add_argument('--escenario',choices=SCENARIOS,default='waypoints');ap.add_argument('--duracion',type=float,default=180)
    ap.add_argument('--paso',type=float,default=.002);ap.add_argument('--salida',type=Path)
    ap.add_argument('--config',type=Path,help='JSON de opciones del integrador, incluyendo waypoints_ned')
    ap.add_argument('--reproducir',type=Path);ap.add_argument('--sin-video',action='store_true');ap.add_argument('--mostrar',action='store_true')
    ap.add_argument('--lewis',action='store_true');args=ap.parse_args()
    if args.reproducir:
        r=load_record(args.reproducir);plots(r);animate(r,show=True,speed=6);return
    out=args.salida or Path('resultados')/datetime.now().strftime('%Y%m%d_%H%M%S')
    if out.exists():ap.error('La carpeta de salida ya existe; usa una nueva.')
    opts={'escenario':args.escenario,'duracion':args.duracion,'paso':args.paso}
    if args.escenario=='trayectoria':opts['tramo']=30
    if args.config:opts.update(json.loads(args.config.read_text(encoding='utf-8-sig')))
    print('Integrando',opts['escenario'],flush=True);r=simulate(**opts);save_record(r,out);plots(r,out)
    if not args.sin_video:animate(r,out/'vuelo_3d.mp4',snapshot=out/'animacion_final.png',show=args.mostrar)
    if args.lewis:write_json(out/'comparacion_lewis.json',compare_lewis())
    print(json.dumps(r['metricas'],indent=2));print('Resultados:',out.resolve())

if __name__=='__main__':main()
