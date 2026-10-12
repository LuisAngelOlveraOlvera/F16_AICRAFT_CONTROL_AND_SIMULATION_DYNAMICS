"""Reabre el registro nativo NPZ; los MAT legacy no son registros Python."""
import argparse
from f16py.io import load_record
from f16py.visualization import plots,animate
from f16py.demonstrations import comparison_plots
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('archivo');args=parser.parse_args()
    r=load_record(args.archivo);plots(r)
    if r['config']['escenario']=='comparacion':comparison_plots(r)
    animate(r,show=True,speed=6)
