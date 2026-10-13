"""Prueba del proceso real y capturas de la ventana propia (opcional)."""
import argparse
from pathlib import Path
import sys
import time
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--capturar',action='store_true');args=parser.parse_args()
    import tkinter as tk
    from f16py.laboratory.app import LaboratoryApp
    from f16py.io import save_record,load_record
    import numpy as np
    root=tk.Tk();app=LaboratoryApp(root);root.update()
    out=Path(__file__).resolve().parents[1]/'resultados'/('qa_laboratorio_'+str(time.time_ns()));out.mkdir(parents=True)
    captures=[]
    try:
        if args.capturar:
            from PIL import ImageGrab
            root.geometry('1200x820+30+30');root.update()
            def capture(name):
                root.update();time.sleep(.25);root.update()
                bbox=(root.winfo_rootx(),root.winfo_rooty(),root.winfo_rootx()+root.winfo_width(),root.winfo_rooty()+root.winfo_height())
                filename=out/(name+'.png');ImageGrab.grab(bbox=bbox).save(filename);captures.append(str(filename))
            capture('avion')
        else:root.withdraw()
        app.load_profile('pid');app.values['duracion'].set('.2');app.run()
        deadline=time.monotonic()+60
        while app.worker.busy and time.monotonic()<deadline:root.update();time.sleep(.03)
        assert app.record_b is not None and not app.worker.busy,'Proceso no entregó registro'
        original=app.record_b;app.save_a();app.original.set(False);app.sync_fields();app.values['pid.kp'].set('2');app.run()
        deadline=time.monotonic()+60
        while app.worker.busy and time.monotonic()<deadline:root.update();time.sleep(.03)
        assert app.record_b is not original and app.record_a['laboratorio']['original']
        assert not app.record_b['laboratorio']['original']
        app.seek(float(app.record_b['t'][-1]));assert app.current_index==len(app.record_b['t'])-1
        folder=save_record(app.record_b,out/'ensayo');loaded=load_record(folder/'registro.npz');np.testing.assert_array_equal(loaded['X'],app.record_b['X'])
        try:save_record(app.record_b,folder)
        except FileExistsError:pass
        else:raise AssertionError('Sobrescritura permitida')
        for name in ('Simulación','Control','Comparación','Vuelo y resultados','Ruta'):
            app.notebook.select(app.tabs[name]);root.update()
            if args.capturar:capture(name.replace(' ','_'))
        app.flight_fig.savefig(out/'vuelo_figura.png');app.compare_fig.savefig(out/'comparacion_figura.png')
        app.load_profile('waypoints');app.run();app.cancel();assert not app.worker.busy and app.record_b is not None
        print('PASS: proceso real, originales/custom, A/B, último instante, NPZ, no sobrescritura, cancelar')
        print('QA:',out)
        for path in captures:print(path)
    finally:app.close()

if __name__=='__main__':main()
